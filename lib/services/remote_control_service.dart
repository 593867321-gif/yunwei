import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:operation/models/remote_control_payload.dart';
import 'package:operation/net/mqtt_manager.dart';
import 'package:operation/services/status_raw_parser.dart';
import 'package:operation/utils/snowflake.dart';

/// 等待设备 ack 的本地超时（客户端侧，非协议字段）
const Duration _kAckTimeout = Duration(seconds: 15);

/// 待确认的 P2P 指令
class _PendingAck {
  /// 指令 cmd
  final String cmd;

  /// 超时定时器
  final Timer timer;

  _PendingAck({required this.cmd, required this.timer});
}

/// 控制权状态
enum ControlState {
  /// 未申请控制权
  idle,

  /// 已获得控制权
  controlled,

  /// 已被他人占用
  occupied,
}

/// 指令执行结果
class CommandResult {
  final String cmd;
  final bool success;
  final String? reason;

  const CommandResult({required this.cmd, required this.success, this.reason});

  bool get isNotController => reason == 'NotController';
}

/// 远程控制服务
///
/// 职责：
/// - 管理本地控制权状态（idle / controlled / occupied）
/// - 通过 MQTT P2P 发送控制指令、管理指令
/// - 解析设备回复，更新控制权状态
/// - 维护心跳定时器（30s 间隔）
/// - 订阅 statusRaw 广播并解析为结构化数据
///
/// 使用 StreamData 暴露状态流，UI 通过 StreamBuilder 订阅。
class RemoteControlService implements IBaseStreamBloc {
  final MqttManager _mqtt;

  /// 店铺 ID
  final int _storeId;

  /// 设备编码
  final String _deviceCode;

  /// 设备 MQTT clientId（完整格式：groupId@@@baseId）
  final String _deviceClientId;

  /// 指令序号（seqNo 去重，每次 P2P 发送时自增）
  int _seqNo = 0;

  /// 心跳定时器
  Timer? _heartbeatTimer;

  /// 控制时长
  int _durationSeconds = 0;
  Timer? _durationTimer;

  /// 按 msgId 等待设备回复的 pending 表
  final Map<String, _PendingAck> _pendingAcks = {};

  /// 二进制消息处理器引用，用于 dispose 时取消注册
  void Function(String topic, Uint8List payload, Map<String, String> userProperties)?
      _binaryHandler;

  /// 字符串消息处理器引用，用于接收 P2P 回复
  void Function(String topic, String payload, Map<String, String> userProperties)?
      _replyHandler;

  // --- StreamData ---

  /// 控制权状态
  final _controlState = ControlState.idle.streamData;

  /// 当前控制者名称（被占用时）
  final _controllerName = ''.streamData;

  /// 控制时长（秒）
  final _durationSec = 0.streamData;

  /// statusRaw 解析结果
  final _statusData = (null as StatusRawData?).streamData;

  /// MQTT 连接状态
  final _mqttConnected = false.streamData;

  /// statusRaw 是否已首次收到
  bool _statusRawReceived = false;

  /// 最近一次指令执行结果
  final _commandResult = (null as CommandResult?).streamData;

  /// versionQuery 回复中的 data 字符串（设备固件版本摘要）
  final _versionQueryText = (null as String?).streamData;

  /// queryControl 返回的查看者 cId 列表
  final _viewers = (const <String>[]).streamData;

  // --- 公开流 ---

  Stream<ControlState?> get controlStateStream => _controlState.stream;
  Stream<StatusRawData?> get statusDataStream => _statusData.stream;
  Stream<CommandResult?> get commandResultStream => _commandResult.stream;
  Stream<String?> get controllerNameStream => _controllerName.stream;
  Stream<int?> get durationSecStream => _durationSec.stream;
  Stream<bool?> get mqttConnectedStream => _mqttConnected.stream;
  Stream<String?> get versionQueryTextStream => _versionQueryText.stream;
  Stream<List<String>?> get viewersStream => _viewers.stream;

  /// 当前控制权状态（只读，供页面 dispose 判断）
  ControlState get controlState =>
      _controlState.value ?? ControlState.idle;

  /// 当前 App MQTT 是否已连接（供 StreamBuilder initialData）
  bool get mqttConnected => _mqttConnected.value ?? false;

  // --- 计算属性 ---

  /// Topic 前缀（groupId 去掉 GID_ 前缀，per PC 后台规范）
  String get _topicNs => (_mqtt.groupId ?? '').replaceFirst(RegExp(r'^GID_'), '');

  /// APP 端原始 clientId（不含 GROUP_ID 和 @@@）
  String get _rawClientId => _mqtt.clientId ?? '';

  /// APP 端完整 clientId（groupId@@@rawClientId）
  String get _appFullClientId => '${_mqtt.groupId ?? ''}@@@$_rawClientId';

  /// 控制指令 Topic: {topicNs}/p2p/{deviceClientId}
  String get _controlTopic => '$_topicNs/p2p/$_deviceClientId';

  /// P2P 回复订阅 Topic: {topicNs}/p2p/{appFullClientId}
  String get _replyTopic => '$_topicNs/p2p/$_appFullClientId';

  /// statusRaw 广播 Topic: {topicNs}/device/{storeId}/{deviceCode}
  String get _statusTopic => '$_topicNs/device/$_storeId/$_deviceCode';

  RemoteControlService({
    required int storeId,
    required String deviceCode,
    required String deviceClientId,
  }) : _mqtt = MqttManager.instance,
       _storeId = storeId,
       _deviceCode = deviceCode,
       _deviceClientId = deviceClientId {
    _setupReplyListener();
    _mqtt.addConnectionListener(_onMqttStateChange);
    _mqttConnected.value = _mqtt.isConnected;
  }

  // ============================================================
  // 控制权管理
  // ============================================================

  /// 申请控制权
  Future<void> acquireControl() async {
    final payload = const RemoteControlPayload.acquireControl();
    _sendP2p(payload, ack: true);
    // 状态更新由 _handleReply 驱动
  }

  /// 释放控制权
  Future<void> releaseControl() async {
    final payload = const RemoteControlPayload.releaseControl();
    _sendP2p(payload, ack: true);
    _setControlState(ControlState.idle);
    _stopHeartbeat();
  }

  /// 强制释放控制权（管理员操作）
  Future<void> forceRelease() async {
    final payload = const RemoteControlPayload.forceRelease();
    _sendP2p(payload, ack: true);
    // 状态更新由 _handleReply 驱动
  }

  /// 查询当前控制权状态
  Future<void> queryControl() async {
    final payload = const RemoteControlPayload.queryControl();
    _sendP2p(payload, ack: true);
  }

  // ============================================================
  // 状态推送
  // ============================================================

  /// MQTT 连接状态变化（重连时自动恢复）
  void _onMqttStateChange(bool connected) {
    _mqttConnected.value = connected;
    "远程控制 MQTT ${connected ? "已连接" : "已断开"}".log();
    if (connected) {
      _doStartStatusPush();
    }
  }

  /// 开启状态推送（先订阅广播 topic，再发 P2P 指令）
  void startStatusPush() {
    if (!_mqtt.isConnected) {
      "远程控制 MQTT 未连接，等待连接后自动订阅".log();
      return;
    }
    _doStartStatusPush();
  }

  void _doStartStatusPush() {
    "远程控制 订阅status: $_statusTopic".log();
    _mqtt.subscribe(_statusTopic, qos: MqttQos.atLeastOnce);
    _setupStatusListener();
    final payload = const RemoteControlPayload.startStatusPush();
    _sendP2p(payload, ack: true);
  }

  /// 关闭状态推送
  void stopStatusPush() {
    final payload = const RemoteControlPayload.stopStatusPush();
    _sendP2p(payload);
  }

  // ============================================================
  // 硬件指令
  // ============================================================

  /// 发送硬件控制指令
  ///
  /// 会先校验控制权，无控制权时直接返回失败结果。
  Future<void> sendCommand(RemoteControlPayload payload) async {
    if (_controlState.value != ControlState.controlled) {
      _commandResult.value = CommandResult(
        cmd: (payload.toJson()['cmd'] as String?) ?? 'unknown',
        success: false,
        reason: 'NotController',
      );
      return;
    }
    _sendP2p(payload, ack: true);
  }

  // ============================================================
  // 内部：P2P 消息发送
  // ============================================================

  /// 发送 P2P 消息到设备
  void _sendP2p(RemoteControlPayload payload, {bool ack = false}) {
    final msgId = Snowflake.nextId();
    final cmd = (payload.toJson()['cmd'] as String?) ?? 'unknown';
    final json = jsonEncode(payload.toJson());
    final props = <String, String>{
      'msgId': msgId,
      'cId': _rawClientId,
      'action': 'control',
    };
    if (ack) {
      props['ack'] = 'true';
    }
    _seqNo++;
    props['seqNo'] = '$_seqNo';
    _mqtt.publish(
      _controlTopic,
      json,
      qos: MqttQos.atLeastOnce,
      userProperties: props,
    );
    // 仅 ack 指令进入 pending，按 msgId 配对回复 / 超时
    if (ack) {
      _trackPendingAck(msgId, cmd);
    }
  }

  /// 登记待确认指令
  void _trackPendingAck(String msgId, String cmd) {
    final timer = Timer(_kAckTimeout, () {
      final pending = _pendingAcks.remove(msgId);
      if (pending == null) return;
      "远程控制 ack 超时 cmd=$cmd msgId=$msgId".log();
      _commandResult.value = CommandResult(
        cmd: cmd,
        success: false,
        reason: 'AckTimeout',
      );
    });
    _pendingAcks[msgId] = _PendingAck(cmd: cmd, timer: timer);
  }

  /// 按 msgId 或 cmd 清除 pending
  void _completePendingAck({String? msgId, required String cmd}) {
    if (msgId != null && msgId.isNotEmpty) {
      final pending = _pendingAcks.remove(msgId);
      pending?.timer.cancel();
      return;
    }
    // 无 msgId 时按 cmd 匹配最早一条（设备异常回包兜底）
    for (final entry in _pendingAcks.entries) {
      if (entry.value.cmd == cmd) {
        entry.value.timer.cancel();
        _pendingAcks.remove(entry.key);
        return;
      }
    }
  }

  /// 取消全部 pending（dispose）
  void _clearAllPendingAcks() {
    for (final pending in _pendingAcks.values) {
      pending.timer.cancel();
    }
    _pendingAcks.clear();
  }

  // ============================================================
  // 内部：回复监听
  // ============================================================

  /// 注册 P2P 回复监听器（订阅 {topicNs}/p2p/{appFullClientId}）
  void _setupReplyListener() {
    _replyHandler = (String topic, String payload, Map<String, String> userProperties) {
      if (topic != _replyTopic) return;
      _handleReply(payload, userProperties);
    };
    _mqtt.subscribe(_replyTopic, qos: MqttQos.atLeastOnce);
    _mqtt.onMessage(_replyHandler!);
    "远程控制 订阅P2P回复: $_replyTopic".log();
  }

  /// 处理设备回复（User Property msgId 与请求配对）
  void _handleReply(String payloadStr, Map<String, String> userProperties) {
    try {
      final json = jsonDecode(payloadStr) as Map<String, dynamic>;
      final reply = ReplyPayload.fromJson(json);
      final success = reply.isOk;
      final replyMsgId = userProperties['msgId'];
      _completePendingAck(msgId: replyMsgId, cmd: reply.cmd);

      // 根据 cmd 更新状态
      switch (reply.cmd) {
        case 'acquireControl':
          if (success) {
            _setControlState(ControlState.controlled);
            _startHeartbeat();
            _startDurationTimer();
          } else if (reply.reason == 'Occupied') {
            _setControlState(ControlState.occupied);
            _controllerName.value = reply.controller ?? '--';
          }
          break;

        case 'releaseControl':
          _setControlState(ControlState.idle);
          _stopHeartbeat();
          break;

        case 'forceRelease':
          _setControlState(ControlState.idle);
          _stopHeartbeat();
          break;

        case 'queryControl':
          if (success) {
            _controllerName.value = reply.controller ?? '';
            _viewers.value = List<String>.from(reply.viewers ?? const []);
          }
          break;

        case 'versionQuery':
          if (success && reply.data != null && reply.data!.isNotEmpty) {
            _versionQueryText.value = reply.data;
          }
          break;

        default:
          // 硬件指令回复
          break;
      }

      _commandResult.value = CommandResult(
        cmd: reply.cmd,
        success: success,
        reason: reply.reason,
      );

      // 如果回复 NotController，更新状态
      if (reply.reason == 'NotController') {
        "远程控制 收到 NotController，失去控制权".log();
        _setControlState(ControlState.idle);
        _stopHeartbeat();
      }
    } catch (_) {
      // 解析失败忽略
    }
  }

  // ============================================================
  // 内部：statusRaw 监听
  // ============================================================

  /// 注册 statusRaw 二进制监听器
  void _setupStatusListener() {
    if (_binaryHandler != null) return;
    _binaryHandler = (String topic, Uint8List payload, Map<String, String> userProperties) {
      if (topic != _statusTopic) return;
      // 业务时间戳优先 User Property ts
      final userTs = int.tryParse(userProperties['ts'] ?? '');
      final data = StatusRawParser.parse(payload, userPropertyTs: userTs);
      if (data != null) {
        if (!_statusRawReceived) {
          _statusRawReceived = true;
          "远程控制 首次收到 statusRaw ts=${data.timestampMs} userTs=$userTs".log();
        }
        _statusData.value = data;
      }
    };
    _mqtt.onBinaryMessage(_binaryHandler!);
  }

  // ============================================================
  // 内部：心跳
  // ============================================================

  /// 启动心跳定时器（30s 间隔）
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      "远程控制 heartbeat 发送".log();
      final payload = const RemoteControlPayload.heartbeat();
      _sendP2p(payload);
    });
    // 立即发送第一次心跳
    final payload = const RemoteControlPayload.heartbeat();
    _sendP2p(payload);
  }

  /// 停止心跳定时器
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _stopDurationTimer();
  }

  // ============================================================
  // 内部：控制时长
  // ============================================================

  void _startDurationTimer() {
    _stopDurationTimer();
    _durationSeconds = 0;
    _durationSec.value = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _durationSeconds++;
      _durationSec.value = _durationSeconds;
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _durationSeconds = 0;
  }

  // ============================================================
  // 内部：状态变更
  // ============================================================

  void _setControlState(ControlState state) {
    _controlState.value = state;
  }

  // ============================================================
  // 生命周期
  // ============================================================

  /// 释放所有资源
  @override
  void streamDispose() {
    _stopHeartbeat();
    _stopDurationTimer();
    _clearAllPendingAcks();
    if (_replyHandler != null) {
      _mqtt.offMessage(_replyHandler!);
      _replyHandler = null;
    }
    if (_binaryHandler != null) {
      _mqtt.offBinaryMessage(_binaryHandler!);
      _binaryHandler = null;
    }
    _mqtt.removeConnectionListener(_onMqttStateChange);
    _controlState.dispose();
    _controllerName.dispose();
    _durationSec.dispose();
    _statusData.dispose();
    _mqttConnected.dispose();
    _commandResult.dispose();
    _versionQueryText.dispose();
    _viewers.dispose();
  }
}
