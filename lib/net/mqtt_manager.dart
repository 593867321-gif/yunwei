import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:operation/net/api_response.dart';

/// MQTT V5 连接管理器（单例）
/// 使用端口 1883 的纯 TCP 连接阿里云 MQTT Broker，并兼容临时秘钥鉴权
class MqttManager {
  static final MqttManager instance = MqttManager._();
  MqttManager._();

  /// MQTT V5 客户端实例
  MqttServerClient? _client;

  /// 当前连接状态
  bool _connected = false;

  /// 是否已连接
  bool get isConnected => _connected;

  /// 最后一次收到的临时凭证信息，用于重连
  MqttInfoVo? _lastToken;

  /// 当前环境组 ID
  String? get groupId => _lastToken?.groupId;

  /// 当前 clientId（不含 groupId 前缀）
  String? get clientId => _lastToken?.clientId;

  /// 重连次数
  int _reconnectCount = 0;

  /// 最大连续重连次数
  static const int maxReconnects = 5;

  /// 订阅消息回调列表（含 MQTT V5 User Properties，如 msgId、cId、action）
  final List<void Function(String topic, String payload, Map<String, String> userProperties)>
      _messageHandlers = [];

  /// 二进制消息回调列表（用于 statusRaw 等二进制 payload）
  /// 第三个参数为 MQTT V5 User Properties（如 action、ts、msgId、cId）
  final List<void Function(String topic, Uint8List payload, Map<String, String> userProperties)>
      _binaryHandlers = [];

  /// 连接状态变更回调
  final List<void Function(bool connected)> _stateListeners = [];

  /// MQTT 消息流订阅，连接重建时需要重新绑定
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSubscription;

  /// 是否已注册 updates 监听器
  bool _isListenRegistered = false;

  /// 添加连接状态监听
  void addConnectionListener(void Function(bool connected) listener) {
    _stateListeners.add(listener);
  }

  /// 移除连接状态监听
  void removeConnectionListener(void Function(bool connected) listener) {
    _stateListeners.remove(listener);
  }

  /// 发起 MQTT 连接
  Future<void> connect(MqttInfoVo info) async {
    _lastToken = info;
    _reconnectCount = 0;
    _isListenRegistered = false; // 重置监听器标记
    await _updatesSubscription?.cancel();
    _updatesSubscription = null;
    "MQTT 开始连接".log();
    await _doConnect(info);
  }

  /// 执行实际 MQTT V5 连接
  Future<void> _doConnect(MqttInfoVo info) async {
    // 释放旧连接
    await _disconnectOld();

    try {
      _connected = false;
      notifyState(false);
    } catch (_) {}

    // 临时凭证过期后不能继续重连，需重新向服务端申请新的凭证
    if (_isCredentialExpired(info)) {
      "MQTT 临时秘钥已过期，请重新获取连接凭证".log();
      _connected = false;
      notifyState(false);
      return;
    }

    // 构建阿里云 MQTT 所需的 clientId / host / username / password
    final fullClientId = _buildFullClientId(info);
    final userName = _buildUserName(info);
    final password = info.password ?? "";
    final host = _buildHost(info);

    // 基础参数缺失时直接终止，避免无意义重试
    if (fullClientId.isEmpty || userName.isEmpty || password.isEmpty || host.isEmpty) {
      "MQTT 连接参数不完整，clientId=$fullClientId userName=$userName host=$host".log();
      _connected = false;
      notifyState(false);
      return;
    }

    // 使用 MQTT V5 客户端发起纯 TCP 连接
    _client = MqttServerClient.withPort(host, fullClientId, 1883);
    final c = _client;
    if (c == null) return;
    c.keepAlivePeriod = 60;
    c.logging(on: true);
    c.autoReconnect = false;

    // 设置 MQTT V5 CONNECT 报文，临时秘钥仍走用户名 / 密码鉴权
    final connMsg = MqttConnectMessage()
        .withClientIdentifier(fullClientId)
        .authenticateAs(userName, password)
        .keepAliveFor(60)
        .startClean(); // Clean Start = true，每次建立新会话
    c.connectionMessage = connMsg;

    // 注册回调
    c.onConnected = _onConnected;
    c.onDisconnected = _onDisconnected;

    try {
      // 建立连接，超时时间 10 秒
      "MQTT V5 正在建立 TCP 连接...".log();
      await c.connect().timeout(const Duration(seconds: 10));
      final status = c.connectionStatus;
      if (status?.state == MqttConnectionState.connected) {
        _connected = true;
        _reconnectCount = 0;
        _registerUpdatesListener();
        "MQTT V5 连接成功 ✓".log();
      } else {
        _connected = false;
        "MQTT V5 连接失败，状态=${status?.state} 返回码=${status?.state}".log();
        await _disconnectOld();
        if (_reconnectCount < maxReconnects && _lastToken != null) {
          _scheduleReconnect();
        }
      }
    } catch (e, st) {
      _connected = false;
      // 详细记录错误原因以便排查
      final errorMessage = e.toString().replaceAll('\n', ' ');
      "MQTT V5 连接失败: $errorMessage".log();
      // 堆栈日志不指定 level 参数
      "$st\n".log();

      // 触发自动重连（指数退避）
      if (_reconnectCount < maxReconnects && _lastToken != null) {
        _scheduleReconnect();
      }
    }

    notifyState(_connected);
  }

  /// 连接成功后调用
  void _onConnected() {
    _connected = true;
    "MQTT V5 已连接".log();
  }

  /// 连接断开后调用
  void _onDisconnected() {
    _connected = false;
    _isListenRegistered = false; // 断开后下次需重新注册
    _updatesSubscription = null;
    "MQTT V5 连接已断开".log();
    notifyState(false);
  }

  /// 组装阿里云 MQTT V5 的 clientId
  String _buildFullClientId(MqttInfoVo info) {
    final baseClientId = info.clientId ?? "";
    final groupId = info.groupId ?? "";
    if (baseClientId.contains("@@@") || groupId.isEmpty) {
      return baseClientId;
    }
    return "$groupId@@@$baseClientId";
  }

  /// 获取阿里云 MQTT 用户名
  String _buildUserName(MqttInfoVo info) {
    return info.userName ?? "";
  }

  /// 从用户名中提取阿里云实例地址
  String _buildHost(MqttInfoVo info) {
    final parts = (info.userName ?? "").split("|");
    final instanceId = parts.length > 2 ? parts[2] : (parts.isNotEmpty ? parts.last : "");
    return instanceId.isEmpty ? "" : "$instanceId.mqtt.aliyuncs.com";
  }

  /// 判断临时秘钥是否已过期，预留 30 秒缓冲避免边界时间连接失败
  bool _isCredentialExpired(MqttInfoVo info) {
    final expirationTime = info.expirationTime;
    if (expirationTime == null || expirationTime <= 0) {
      return false;
    }
    final expirationMillis =
        expirationTime < 1000000000000 ? expirationTime * 1000 : expirationTime;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    return nowMillis + 30 * 1000 >= expirationMillis;
  }

  /// 注册消息监听器，确保首次连接和重连后都能收到消息
  void _registerUpdatesListener() {
    if (_client == null || _isListenRegistered) {
      return;
    }
    final c = _client ?? (throw StateError('client is null'));
    _updatesSubscription = c.updates.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      for (final msg in messages) {
        if (msg.payload is! MqttPublishMessage) {
          continue;
        }
        final pubMsg = msg.payload as MqttPublishMessage;
        final messageBytes = pubMsg.payload.message;
        final topic = msg.topic ?? '';
        "MQTT 收到: $topic".log();

        // 统一解析 MQTT V5 User Properties
        final userProps = <String, String>{};
        final props = pubMsg.variableHeader?.userProperty;
        if (props != null) {
          for (final p in props) {
            final name = p.pairName;
            final value = p.pairValue;
            if (name != null && value != null) {
              userProps[name] = value;
            }
          }
        }

        // 派发二进制回调（statusRaw 等）
        if (messageBytes != null && _binaryHandlers.isNotEmpty) {
          final raw = Uint8List.fromList(messageBytes.toList());
          for (final handler in List.of(_binaryHandlers)) {
            try {
              handler(topic, raw, userProps);
            } catch (e) {
              "二进制消息回调执行失败: $e".log();
            }
          }
        }

        // 派发字符串回调（二进制 payload 跳过 UTF-8 解码）
        String? payload;
        if (messageBytes != null) {
          try {
            payload = utf8.decode(messageBytes.toList());
          } on FormatException {
            // 二进制消息（如 statusRaw），由 _binaryHandlers 处理
          }
        }
        if (payload != null) {
          for (final handler
              in List<
                      void Function(
                        String topic,
                        String payload,
                        Map<String, String> userProperties,
                      )>.from(_messageHandlers)) {
            try {
              handler(topic, payload, userProps);
            } catch (e) {
              "消息回调执行失败: $e".log();
            }
          }
        }
      }
    });
    _isListenRegistered = true;
  }

  /// 指数退避重连
  void _scheduleReconnect() {
    _reconnectCount++;
    // 间隔时间：1s, 2s, 4s, 8s, 16s（不用 pow，手动计算）
    int delay = 1 << (_reconnectCount - 1);
    if (delay > 16) delay = 16;
    "MQTT ${delay}s 后第 $_reconnectCount 次重连".log();
    Timer(Duration(seconds: delay), () {
      final token = _lastToken;
      if (token != null) {
        _doConnect(token);
      } else {
        "_lastToken is null, stopping reconnect loop".log();
        _connected = false;
        notifyState(false);
      }
    });
  }

  /// 通知所有状态监听器
  void notifyState(bool connected) {
    for (final l in List.from(_stateListeners)) {
      try {
        l(connected);
      } catch (e) {
        "状态回调异常: $e".log();
      }
    }
  }

  /// 注册消息处理器（含 User Properties，用于 msgId 配对等）
  void onMessage(
    void Function(String topic, String payload, Map<String, String> userProperties)
        handler,
  ) {
    if (!_messageHandlers.contains(handler)) {
      _messageHandlers.add(handler);
    }
    _registerUpdatesListener();
  }

  /// 取消消息处理器
  void offMessage(
    void Function(String topic, String payload, Map<String, String> userProperties)
        handler,
  ) {
    _messageHandlers.remove(handler);
  }

  /// 注册二进制消息处理器（statusRaw 等）
  void onBinaryMessage(
    void Function(String topic, Uint8List payload, Map<String, String> userProperties) handler,
  ) {
    if (!_binaryHandlers.contains(handler)) {
      _binaryHandlers.add(handler);
    }
    _registerUpdatesListener();
  }

  /// 取消二进制消息处理器
  void offBinaryMessage(
    void Function(String topic, Uint8List payload, Map<String, String> userProperties) handler,
  ) {
    _binaryHandlers.remove(handler);
  }

  /// 订阅指定 Topic
  void subscribe(String topic, {MqttQos qos = MqttQos.atMostOnce}) {
    if (!isConnected || _client == null) return;
    final c = _client ?? (throw StateError('client is null'));
    c.subscribe(topic, qos);
    "MQTT 请求订阅: $topic".log();
  }

  /// 发布消息到指定 Topic
  /// [userProperties] MQTT V5 User Property 键值对（msgId、cId、action、ack 等）
  void publish(String topic, String payload, {MqttQos qos = MqttQos.atMostOnce, Map<String, String>? userProperties}) {
    if (!isConnected || _client == null) return;
    final c = _client!;
    final builder = MqttPayloadBuilder();
    builder.addString(payload);
    final p = builder.payload;
    if (p == null) return;

    final props = userProperties?.entries
        .map((e) => MqttUserProperty()
          ..pairName = e.key
          ..pairValue = e.value)
        .toList();

    c.publishMessage(topic, qos, p, userProperties: props);
    "MQTT published: $topic".log();
  }

  /// 检查并触发重连（由外部生命周期事件如 app resume 调用）
  void checkAndReconnect() {
    final token = _lastToken;
    if (_connected || token == null) return;
    _reconnectCount = 0; // 重置重连计数器
    _isListenRegistered = false;
    "MQTT App 回前台，重新连接".log();
    _doConnect(token);
  }

  /// 断开并释放当前连接
  Future<void> _disconnectOld() async {
    try {
      await _updatesSubscription?.cancel();
      _updatesSubscription = null;
      _client?.disconnect();
      _client = null;
    } catch (e) {
      "MQTT 断开旧连接异常: $e".log();
    }
  }

  /// 清理资源
  void dispose() {
    _disconnectOld();
    _connected = false;
    _isListenRegistered = false;
    _messageHandlers.clear();
    _binaryHandlers.clear();
    _stateListeners.clear();
  }
}
