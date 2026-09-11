import 'dart:async';
import 'package:flutter/material.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/models/remote_control_payload.dart';
import 'package:operation/page/page_device.dart';
import 'package:operation/services/remote_control_service.dart';
import 'package:operation/services/status_raw_parser.dart';
import 'package:operation/widget/widet_dialog.dart';

/// 远程控制页面
///
/// 入口：从 [DeviceDetailPage] 点击"远程控制"按钮跳转。
/// 参考 UI 原型：ui/remote-control.html
///
/// 页面结构（9 个卡片分区）：
/// 1. 控制权状态栏 2. 设备状态总览 3. 继电器 4. 机械臂
/// 5. 出餐门/落杯/落盖 6. 咖啡机/制冰 7. 传感器数据 8. 系统指令 9. 版本查询
///
// ignore: always_put_control_body_on_new_line
class RemoteControlPage extends StatefulWidget {
  final DeviceCardData device;
  final String deviceClientId;
  final int storeId;

  const RemoteControlPage({
    super.key,
    required this.device,
    required this.deviceClientId,
    required this.storeId,
  });

  static void actionStart({
    required DeviceCardData device,
    required String deviceClientId,
    required int storeId,
  }) {
    RouterUtil.navigatorKey.currentState?.push(
      MaterialPageRouteLifecycle(
        builder: (_) => RemoteControlPage(
          device: device,
          deviceClientId: deviceClientId,
          storeId: storeId,
        ),
      ),
    );
  }

  @override
  State<RemoteControlPage> createState() => _RemoteControlPageState();
}

class _RemoteControlPageState extends State<RemoteControlPage> with _Bloc {
  late final RemoteControlService _service;
  StreamSubscription<CommandResult?>? _commandResultSub;

  @override
  void initState() {
    super.initState();
    final device = widget.device;
    _service = RemoteControlService(
      storeId: widget.storeId,
      deviceCode: device.deviceCode ?? '',
      deviceClientId: widget.deviceClientId,
    );
    _service.startStatusPush();
    // A2: 订阅指令回复，toast 展示成功/失败（reason 走 i18n）
    _commandResultSub = _service.commandResultStream.listen((result) {
      if (result == null || !mounted) return;
      final l10n = AppLocalizations.of(context);
      if (result.success) {
        l10n.remoteControlCmdSuccess(result.cmd).toast();
      } else {
        final reasonLabel = _reasonLabel(l10n, result.reason);
        l10n.remoteControlCmdFailed(result.cmd, reasonLabel).toast();
      }
    });
  }

  /// reason 英文标识符 → 本地化文案
  String _reasonLabel(AppLocalizations l10n, String? reason) {
    return switch (reason) {
      'NotController' => l10n.remoteControlReasonNotController,
      'Occupied' => l10n.remoteControlReasonOccupied,
      'InvalidParams' => l10n.remoteControlReasonInvalidParams,
      'SlaveNoResponse' => l10n.remoteControlReasonSlaveNoResponse,
      'UnknownCmd' => l10n.remoteControlReasonUnknownCmd,
      'AckTimeout' => l10n.remoteControlReasonAckTimeout,
      null || '' => '--',
      _ => reason,
    };
  }

  @override
  void dispose() {
    _commandResultSub?.cancel();
    // A6: 退页时若持有控制权则释放（MQTT 异步发出即可）
    if (_service.controlState == ControlState.controlled) {
      _service.releaseControl();
    }
    _service.stopStatusPush();
    _service.streamDispose();
    super.dispose();
  }

  // ============================================================
  // 控制权操作（控制类指令均二次确认，防误触）
  // ============================================================

  /// 二次确认；取消返回 false
  Future<bool> _confirmControl(String actionLabel) async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context);
    return DialogUtil.confirm(
      context,
      title: l10n.remoteControlConfirmTitle,
      message: l10n.remoteControlConfirmMessage(actionLabel),
      confirmText: l10n.remoteControlConfirmOk,
      cancelText: l10n.remoteControlConfirmCancel,
    );
  }

  Future<void> _acquireControl() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirmControl(l10n.remoteControlAcquire)) return;
    await _service.acquireControl();
  }

  Future<void> _releaseControl() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirmControl(l10n.remoteControlRelease)) return;
    await _service.releaseControl();
  }

  Future<void> _forceRelease() async {
    final l10n = AppLocalizations.of(context);
    if (!await _confirmControl(l10n.remoteControlForceRelease)) return;
    await _service.forceRelease();
  }

  Future<void> _queryControl() async {
    // 只读查询，无需二次确认
    await _service.queryControl();
  }

  Future<void> _sendCommand(RemoteControlPayload payload) async {
    final l10n = AppLocalizations.of(context);
    final cmd = (payload.toJson()['cmd'] as String?) ?? 'unknown';
    final actionLabel = _controlCmdLabel(l10n, cmd, payload);
    if (!await _confirmControl(actionLabel)) return;
    if (!mounted) return;
    await _service.sendCommand(payload);
  }

  /// 控制 cmd → 用户可读动作名（弹窗文案）
  String _controlCmdLabel(
    AppLocalizations l10n,
    String cmd,
    RemoteControlPayload payload,
  ) {
    return switch (cmd) {
      'relayToggle' => l10n.remoteControlRelay,
      'robotAction' => l10n.remoteControlRobot,
      'coffeeAction' => l10n.remoteControlCoffeeSection,
      'doorControl' => l10n.remoteControlDoorSection,
      'cupDispense' => l10n.remoteControlCupSection,
      'lidDispense' => l10n.remoteControlLidSection,
      'iceDispense' => l10n.remoteControlIceSection,
      'juiceDispense' => l10n.remoteControlJuiceSection,
      'systemCommand' => l10n.remoteControlSystemSection,
      'versionQuery' => l10n.remoteControlQueryVersion,
      _ => cmd,
    };
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final device = widget.device;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(device.deviceName ?? l10n.remoteControlTitle),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // §1 控制权状态栏
            _ControlStatusBar(
              service: _service,
              onAcquire: _acquireControl,
              onRelease: _releaseControl,
              onForceRelease: _forceRelease,
              onQueryControl: _queryControl,
            ),
            const SizedBox(height: 12),

            // §2 设备状态总览
            _DeviceStatusOverview(device: device, service: _service),
            const SizedBox(height: 12),

            // §3 继电器控制
            _RelaySection(service: _service, onSend: _sendCommand),
            const SizedBox(height: 12),

            // §4 机械臂控制
            _RobotArmSection(service: _service, onSend: _sendCommand),
            const SizedBox(height: 12),

            // §5 出餐门
            _DoorSection(service: _service, onSend: _sendCommand),
            const SizedBox(height: 12),

            // §6 落杯
            _CupDispenseSection(service: _service, onSend: _sendCommand),
            const SizedBox(height: 12),

            // §7 落盖
            _LidDispenseSection(service: _service, onSend: _sendCommand),
            const SizedBox(height: 12),

            // §8 咖啡机
            _CoffeeSection(service: _service, onSend: _sendCommand),
            const SizedBox(height: 12),

            // §9 制冰
            _IceSection(service: _service, onSend: _sendCommand),
            const SizedBox(height: 12),

            // §10 果汁
            _JuiceSection(service: _service, onSend: _sendCommand),
            const SizedBox(height: 12),

            // §11 传感器数据
            _SensorDataSection(service: _service),
            const SizedBox(height: 12),

            // §12 系统指令
            _SystemCommandSection(service: _service, onSend: _sendCommand),
            const SizedBox(height: 12),

            // §13 版本查询
            _VersionSection(service: _service, onSend: _sendCommand),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Mixin Bloc
// ============================================================

mixin _Bloc implements IBaseStreamBloc {
  @override
  void streamDispose() {}
}

// ============================================================
// §1 控制权状态栏
// ============================================================

class _ControlStatusBar extends StatelessWidget {
  final RemoteControlService service;
  final VoidCallback onAcquire;
  final VoidCallback onRelease;
  final VoidCallback onForceRelease;
  final VoidCallback onQueryControl;

  const _ControlStatusBar({
    required this.service,
    required this.onAcquire,
    required this.onRelease,
    required this.onForceRelease,
    required this.onQueryControl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration,
      child: StreamBuilder<ControlState?>(
        stream: service.controlStateStream,
        initialData: ControlState.idle,
        builder: (_, snap) {
          final state = snap.data ?? ControlState.idle;
          return StreamBuilder<bool?>(
            stream: service.mqttConnectedStream,
            // 用当前真实连接状态，避免 stream 不回放导致一直显示未连
            initialData: service.mqttConnected,
            builder: (_, mqttSnap) {
              final mqttOk = mqttSnap.data ?? service.mqttConnected;
              return StreamBuilder<String?>(
                stream: service.controllerNameStream,
                initialData: null,
                builder: (_, nameSnap) {
                  final controllerName = nameSnap.data;
                  return StreamBuilder<List<String>?>(
                    stream: service.viewersStream,
                    initialData: const [],
                    builder: (_, viewersSnap) {
                      final viewers = viewersSnap.data ?? const <String>[];
                      final showController = controllerName != null &&
                          controllerName.isNotEmpty &&
                          controllerName != '--';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 两行：状态信息不截断，操作按钮单独一行
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildStatusDot(state),
                                  const SizedBox(width: 8),
                                  _buildStatusText(state, l10n),
                                  const SizedBox(width: 10),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: mqttOk
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF94A3B8),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mqttOk
                                        ? l10n.remoteControlMqttOn
                                        : l10n.remoteControlMqttOff,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: mqttOk
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _buildActions(state, l10n),
                              ),
                            ],
                          ),
                          if (showController)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                l10n.remoteControlControllerLabel(
                                  controllerName,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: state == ControlState.occupied
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          if (viewers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                l10n.remoteControlViewersLabel(
                                  viewers.join(', '),
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusDot(ControlState state) {
    Color color;
    switch (state) {
      case ControlState.idle:
        color = const Color(0xFF94A3B8);
      case ControlState.controlled:
        color = const Color(0xFF10B981);
      case ControlState.occupied:
        color = const Color(0xFFF59E0B);
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildStatusText(ControlState state, AppLocalizations l10n) {
    final (label, color) = switch (state) {
      ControlState.idle => (l10n.remoteControlIdle, const Color(0xFF64748B)),
      ControlState.controlled => (
        l10n.remoteControlControlling,
        const Color(0xFF10B981),
      ),
      ControlState.occupied => (
        l10n.remoteControlOccupied,
        const Color(0xFFF59E0B),
      ),
    };
    return Text(
      label,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
    );
  }

  Widget _buildActions(ControlState state, AppLocalizations l10n) {
    switch (state) {
      case ControlState.idle:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Btn(
              label: l10n.remoteControlQueryControl,
              color: const Color(0xFF64748B),
              onTap: onQueryControl,
            ),
            const SizedBox(width: 6),
            _Btn(
              label: l10n.remoteControlAcquire,
              color: const Color(0xFF10B981),
              onTap: onAcquire,
            ),
          ],
        );
      case ControlState.controlled:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Btn(
              label: l10n.remoteControlQueryControl,
              color: const Color(0xFF64748B),
              onTap: onQueryControl,
            ),
            const SizedBox(width: 6),
            _Btn(
              label: l10n.remoteControlRelease,
              color: const Color(0xFFEF4444),
              onTap: onRelease,
            ),
          ],
        );
      case ControlState.occupied:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Btn(
              label: l10n.remoteControlQueryControl,
              color: const Color(0xFF64748B),
              onTap: onQueryControl,
            ),
            const SizedBox(width: 6),
            _Btn(
              label: l10n.remoteControlAcquire,
              color: const Color(0xFF10B981),
              onTap: onAcquire,
            ),
            const SizedBox(width: 6),
            _Btn(
              label: l10n.remoteControlForceRelease,
              color: const Color(0xFFEF4444),
              onTap: onForceRelease,
            ),
          ],
        );
    }
  }
}

// ============================================================
// §2 设备状态总览
// ============================================================

class _DeviceStatusOverview extends StatelessWidget {
  final DeviceCardData device;
  final RemoteControlService service;

  const _DeviceStatusOverview({required this.device, required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<StatusRawData?>(
      stream: service.statusDataStream,
      initialData: null,
      builder: (_, snap) {
        final data = snap.data;
        return _Card(
          title: l10n.remoteControlStatusOverview,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 型号（设备在线与否由是否有 statusRaw 体现，不单独假显示「在线」）
              _StatusGrid(
                children: [
                  _StatusItem(
                    label: '型号',
                    value: data?.deviceModel ?? device.model ?? '--',
                    valueColor: const Color(0xFF3B82F6),
                  ),
                ],
              ),
              // 子系统摘要条（有实时数据时展示）
              if (data != null) ...[
                const SizedBox(height: 10),
                _SubsystemStrip(data: data),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  '等待设备数据...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 子系统状态摘要条
class _SubsystemStrip extends StatelessWidget {
  final StatusRawData data;
  const _SubsystemStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final relays = data.relayStates;
    final relayOn = relays != null ? relays.values.where((v) => v).length : 0;
    final relayTotal = relays?.length ?? 0;

    final arm1 = data.robotArm1;
    final arm2 = data.robotArm2;

    final doors = data.doorStates;
    final anyDoorOpen = doors != null && doors.values.any((d) => d.isOpen);
    final anyDoorFault =
        doors != null &&
        doors.values.any((d) => d.hasCupFault || d.hasFrontFault);

    final coffee = data.coffeeStatus;
    final ice = data.iceStatus;

    final bubble = data.bubbleStatus;
    final waterHot = data.waterHotStatus;
    final stock = data.stockData;
    final moduleLink = data.moduleLinkStatus;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _StripItem(
          dotColor: relayOn > 0
              ? const Color(0xFF10B981)
              : const Color(0xFF94A3B8),
          text: '继电器 $relayOn/$relayTotal 开',
        ),
        _StripItem(
          dotColor: arm1 != null
              ? (arm1.hasAlarm
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981))
              : const Color(0xFF94A3B8),
          text: '①臂 ${arm1?.stateLabel ?? "--"}',
        ),
        _StripItem(
          dotColor: arm2 != null
              ? (arm2.hasAlarm
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981))
              : const Color(0xFF94A3B8),
          text: '②臂 ${arm2?.stateLabel ?? "--"}',
        ),
        _StripItem(
          dotColor: anyDoorFault
              ? const Color(0xFFEF4444)
              : (anyDoorOpen
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF94A3B8)),
          text: anyDoorFault ? '门 故障' : (anyDoorOpen ? '门 有开' : '门 全关'),
        ),
        _StripItem(
          dotColor: coffee != null
              ? (coffee.hasFault
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981))
              : const Color(0xFF94A3B8),
          text: '咖啡机 ${coffee?.stateLabel ?? "--"}',
        ),
        _StripItem(
          dotColor: ice != null
              ? (ice.hasFault
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981))
              : const Color(0xFF94A3B8),
          text: '制冰 ${ice?.stateLabel ?? "--"}',
        ),
        if (bubble != null)
          _StripItem(
            dotColor: (bubble.co2Empty || bubble.isWaterEmpty)
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981),
            text: '气泡 ${bubble.stateLabel}',
          ),
        if (waterHot != null)
          _StripItem(
            dotColor: waterHot.hasFault
                ? const Color(0xFFF59E0B)
                : const Color(0xFF10B981),
            text: '热水 ${waterHot.stateLabel}',
          ),
        if (stock != null)
          _StripItem(
            dotColor: stock.totalCups > 0
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            text: '杯${stock.totalCups} 盖${stock.totalLids}',
          ),
        if (moduleLink != null)
          _StripItem(
            dotColor: moduleLink.onlineCount == moduleLink.totalCount
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            text: '模块 ${moduleLink.onlineCount}/${moduleLink.totalCount}',
          ),
      ],
    );
  }
}

class _StripItem extends StatelessWidget {
  final Color dotColor;
  final String text;
  const _StripItem({required this.dotColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// §3 继电器控制
// ============================================================

class _RelaySection extends StatefulWidget {
  final RemoteControlService service;
  final Future<void> Function(RemoteControlPayload payload) onSend;

  const _RelaySection({required this.service, required this.onSend});

  @override
  State<_RelaySection> createState() => _RelaySectionState();
}

class _RelaySectionState extends State<_RelaySection> {
  /// 协议有效继电器（排除预留位），index 与 slave-protocol §2.8 一致
  static const _relays = <(int index, String Function(AppLocalizations) name)>[
    (1, _nTableFan),
    (2, _nCoffeePower),
    (3, _nIcePower),
    (4, _nRobotPower),
    (5, _nAirPower),
    (6, _nLightPower),
    (7, _nAdPower),
    (8, _nBubblePower),
    (9, _nWaterPumpIn),
    (10, _nWaterPumpOut),
    (11, _nValve1),
    (12, _nValve2),
    (13, _nValve3),
    (16, _nJuiceFan),
    (17, _nWaterWaste),
    (18, _nDxkw),
    (21, _nLightColor),
  ];

  static String _nTableFan(AppLocalizations l) => l.remoteControlRelayTableFan;
  static String _nCoffeePower(AppLocalizations l) =>
      l.remoteControlRelayCoffeePower;
  static String _nIcePower(AppLocalizations l) => l.remoteControlRelayIcePower;
  static String _nRobotPower(AppLocalizations l) =>
      l.remoteControlRelayRobotPower;
  static String _nAirPower(AppLocalizations l) => l.remoteControlRelayAirPower;
  static String _nLightPower(AppLocalizations l) =>
      l.remoteControlRelayLightPower;
  static String _nAdPower(AppLocalizations l) => l.remoteControlRelayAdPower;
  static String _nBubblePower(AppLocalizations l) =>
      l.remoteControlRelayBubblePower;
  static String _nWaterPumpIn(AppLocalizations l) =>
      l.remoteControlRelayWaterPumpIn;
  static String _nWaterPumpOut(AppLocalizations l) =>
      l.remoteControlRelayWaterPumpOut;
  static String _nValve1(AppLocalizations l) => l.remoteControlRelayValve1;
  static String _nValve2(AppLocalizations l) => l.remoteControlRelayValve2;
  static String _nValve3(AppLocalizations l) => l.remoteControlRelayValve3;
  static String _nJuiceFan(AppLocalizations l) => l.remoteControlRelayJuiceFan;
  static String _nWaterWaste(AppLocalizations l) =>
      l.remoteControlRelayWaterWaste;
  static String _nDxkw(AppLocalizations l) => l.remoteControlRelayDxkw;
  static String _nLightColor(AppLocalizations l) =>
      l.remoteControlRelayLightColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<ControlState?>(
      stream: widget.service.controlStateStream,
      initialData: ControlState.idle,
      builder: (_, ctrlSnap) {
        final hasControl = ctrlSnap.data == ControlState.controlled;
        return StreamBuilder<StatusRawData?>(
          stream: widget.service.statusDataStream,
          initialData: null,
          builder: (_, statusSnap) {
            final relays = statusSnap.data?.relayStates;
            return _Card(
              title: l10n.remoteControlRelay,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 状态始终可见；全开/全关与点按切换仅控制权后显示/可操作
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in _relays)
                        _ToggleChip(
                          label: entry.$2(l10n),
                          value: relays?[entry.$1] ?? false,
                          disabled: !hasControl,
                          onChanged: (v) {
                            widget.onSend(
                              RemoteControlPayload.relayToggle(
                                data: RelayToggleData(
                                  relayIndex: entry.$1,
                                  on: v,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  if (hasControl) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Chip(
                          label: l10n.remoteControlRelayAllOn,
                          color: const Color(0xFF10B981),
                          onTap: () => widget.onSend(
                            RemoteControlPayload.relayToggle(
                              data: const RelayToggleData(
                                relayIndex: 0xFF,
                                on: true,
                              ),
                            ),
                          ),
                        ),
                        _Chip(
                          label: l10n.remoteControlRelayAllOff,
                          color: const Color(0xFFEF4444),
                          onTap: () => widget.onSend(
                            RemoteControlPayload.relayToggle(
                              data: const RelayToggleData(
                                relayIndex: 0x00,
                                on: false,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// §4 机械臂控制
// ============================================================

class _RobotArmSection extends StatefulWidget {
  final RemoteControlService service;
  final Future<void> Function(RemoteControlPayload payload) onSend;

  const _RobotArmSection({required this.service, required this.onSend});

  @override
  State<_RobotArmSection> createState() => _RobotArmSectionState();
}

class _RobotArmSectionState extends State<_RobotArmSection> {
  /// 目标臂 1/2
  int _arm = 1;

  /// 动作码 0=未选，1–11 见协议
  int _action = 0;

  /// 丢杯目标：0=不涉及，1=咖啡位，2–4=缓存
  int _dropTarget = 0;

  /// 出餐门：0=不涉及，1–4
  int _cupOut = 0;

  /// 缓存位：0=不涉及，1–4
  int _cacheDiscard = 0;

  /// 是否丢杯类动作（才展示定位参数）
  bool get _isDropAction => _action >= 9 && _action <= 11;

  /// action → 文案
  Map<int, String> _actionLabels(AppLocalizations l10n) => {
        1: l10n.remoteControlArmReset,
        2: l10n.remoteControlArmEnable,
        3: l10n.remoteControlArmDisable,
        4: l10n.remoteControlArmRun,
        5: l10n.remoteControlArmStop,
        6: l10n.remoteControlArmDragEnter,
        7: l10n.remoteControlArmDragExit,
        8: l10n.remoteControlArmContinue,
        9: l10n.remoteControlArmDropOrigin,
        10: l10n.remoteControlArmDropCache,
        11: l10n.remoteControlArmDropOutlet,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actionLabels = _actionLabels(l10n);
    return StreamBuilder<ControlState?>(
      stream: widget.service.controlStateStream,
      initialData: ControlState.idle,
      builder: (_, ctrlSnap) {
        final ok = ctrlSnap.data == ControlState.controlled;
        return StreamBuilder<StatusRawData?>(
          stream: widget.service.statusDataStream,
          initialData: null,
          builder: (_, statusSnap) {
            final data = statusSnap.data;
            final arm1 = data?.robotArm1;
            final arm2 = data?.robotArm2;
            return _Card(
              title: l10n.remoteControlRobot,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 臂状态摘要（只读）
                  _StatusGrid(
                    children: [
                      _StatusItem(
                        label: '①臂',
                        value: arm1?.stateLabel ?? '--',
                        valueColor: arm1 != null
                            ? (arm1.hasAlarm
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981))
                            : null,
                      ),
                      _StatusItem(
                        label: '②臂',
                        value: arm2?.stateLabel ?? '--',
                        valueColor: arm2 != null
                            ? (arm2.hasAlarm
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981))
                            : null,
                      ),
                      if (arm1 != null)
                        _StatusItem(
                          label: '①臂Z轴',
                          value: '${arm1.zHeight}',
                        ),
                      if (arm2 != null)
                        _StatusItem(
                          label: '②臂Z轴',
                          value: '${arm2.zHeight}',
                        ),
                      if (arm1 != null)
                        _StatusItem(
                          label: '①制作/取货',
                          value:
                              '${arm1.isMakeBusy ? "忙" : "闲"}/${arm1.isFetchBusy ? "忙" : "闲"}',
                        ),
                      if (arm2 != null)
                        _StatusItem(
                          label: '②制作/取货',
                          value:
                              '${arm2.isMakeBusy ? "忙" : "闲"}/${arm2.isFetchBusy ? "忙" : "闲"}',
                        ),
                    ],
                  ),
                  if (arm1 != null && arm1.hasAlarm)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '⚠ ①臂告警',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  if (arm2 != null && arm2.hasAlarm)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '⚠ ②臂告警',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  // 有控制权：选臂 → 选动作 →（丢杯类）可选定位 → 启动
                  if (ok) ...[
                    const SizedBox(height: 12),
                    _OpGroup(
                      title: l10n.remoteControlOpTargetArm,
                      child: _Segmented<int>(
                        value: _arm,
                        items: {
                          1: l10n.remoteControlArm1,
                          2: l10n.remoteControlArm2,
                        },
                        onChanged: (v) => setState(() => _arm = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _OpGroup(
                      title: l10n.remoteControlOpActions,
                      child: _ActionDropdown(
                        value: _action,
                        placeholder: l10n.remoteControlArmSelectAction,
                        items: actionLabels,
                        onChanged: (v) => setState(() {
                          _action = v;
                          // 切到非丢杯时定位归 0
                          if (v < 9 || v > 11) {
                            _dropTarget = 0;
                            _cupOut = 0;
                            _cacheDiscard = 0;
                          }
                        }),
                      ),
                    ),
                    if (_isDropAction) ...[
                      const SizedBox(height: 12),
                      _OpGroup(
                        title: l10n.remoteControlDropParams,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.remoteControlDropTarget,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _Segmented<int>(
                              value: _dropTarget,
                              items: {
                                0: l10n.remoteControlParamNone,
                                1: l10n.remoteControlDropTargetCoffee,
                                2: l10n.remoteControlDropTargetCache1,
                                3: l10n.remoteControlDropTargetCache2,
                                4: l10n.remoteControlDropTargetCache3,
                              },
                              onChanged: (v) =>
                                  setState(() => _dropTarget = v),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.remoteControlDropCupOut,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _Segmented<int>(
                              value: _cupOut,
                              items: {
                                0: l10n.remoteControlParamNone,
                                1: l10n.remoteControlDoor1,
                                2: l10n.remoteControlDoor2,
                                3: l10n.remoteControlDoor3,
                                4: l10n.remoteControlDoor4,
                              },
                              onChanged: (v) => setState(() => _cupOut = v),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.remoteControlDropCacheDiscard,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _Segmented<int>(
                              value: _cacheDiscard,
                              items: {
                                0: l10n.remoteControlParamNone,
                                1: l10n.remoteControlCache1,
                                2: l10n.remoteControlCache2,
                                3: l10n.remoteControlCache3,
                                4: l10n.remoteControlCache4,
                              },
                              onChanged: (v) =>
                                  setState(() => _cacheDiscard = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: _Btn.full(
                        label: l10n.remoteControlArmStart,
                        color: const Color(0xFF10B981),
                        onTap: () => _start(l10n),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 启动：一条 robotAction；非丢杯强制定位三字段为 0
  void _start(AppLocalizations l10n) {
    if (_action < 1 || _action > 11) {
      l10n.remoteControlArmSelectActionHint.toast();
      return;
    }
    final isDrop = _action >= 9 && _action <= 11;
    widget.onSend(
      RemoteControlPayload.robotAction(
        data: RobotActionData(
          arm: _arm,
          action: _action,
          dropTarget: isDrop ? _dropTarget : 0,
          cupOut: isDrop ? _cupOut : 0,
          cacheDiscard: isDrop ? _cacheDiscard : 0,
        ),
      ),
    );
  }
}

/// 机械臂动作下拉（选择器样式，非动作按钮）
class _ActionDropdown extends StatelessWidget {
  final int value;
  final String placeholder;
  final Map<int, String> items;
  final ValueChanged<int> onChanged;

  const _ActionDropdown({
    required this.value,
    required this.placeholder,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = items[value] ?? placeholder;
    final selected = value >= 1;
    return PopupMenuButton<int>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        for (final e in items.entries)
          PopupMenuItem<int>(
            value: e.key,
            child: Text(
              e.value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: e.key == value ? FontWeight.w600 : FontWeight.w400,
                color: e.key == value
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF334155),
              ),
            ),
          ),
      ],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF3B82F6)
                : const Color(0xFFCBD5E1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// §5 出餐门
// ============================================================

class _DoorSection extends StatefulWidget {
  final RemoteControlService service;
  final Future<void> Function(RemoteControlPayload payload) onSend;

  const _DoorSection({required this.service, required this.onSend});

  @override
  State<_DoorSection> createState() => _DoorSectionState();
}

class _DoorSectionState extends State<_DoorSection> {
  int _door = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<ControlState?>(
      stream: widget.service.controlStateStream,
      initialData: ControlState.idle,
      builder: (_, ctrlSnap) {
        final ok = ctrlSnap.data == ControlState.controlled;
        return StreamBuilder<StatusRawData?>(
          stream: widget.service.statusDataStream,
          initialData: null,
          builder: (_, statusSnap) {
            final doors = statusSnap.data?.doorStates;
            return _Card(
              title: l10n.remoteControlDoorSection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (doors != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final e in doors.entries) ...[
                            _StatusTag(
                              label: '门${e.key} ${e.value.label}',
                              isOn: e.value.isOpen,
                              isFault:
                                  e.value.hasCupFault || e.value.hasFrontFault,
                            ),
                            if (e.value.frontDoorUp || e.value.frontDoorDown)
                              _StatusTag(
                                label: '前门${e.value.frontDoorUp ? "上" : "下"}限位',
                                isOn: e.value.frontDoorUp,
                                isFault: false,
                              ),
                          ],
                        ],
                      ),
                    )
                  else
                    Text(
                      l10n.remoteControlNoData,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  if (ok) ...[
                    const SizedBox(height: 4),
                    _OpGroup(
                      title: l10n.remoteControlDropCupOut,
                      child: _Segmented<int>(
                        value: _door,
                        items: {
                          1: l10n.remoteControlDoor1,
                          2: l10n.remoteControlDoor2,
                          3: l10n.remoteControlDoor3,
                          4: l10n.remoteControlDoor4,
                        },
                        onChanged: (v) => setState(() => _door = v),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _OpGroup(
                      title: l10n.remoteControlOpLinkDoor,
                      child: Row(
                        children: [
                          _Chip(
                            label: l10n.remoteControlDoorOpen,
                            color: const Color(0xFF10B981),
                            onTap: () => widget.onSend(
                              RemoteControlPayload.doorControl(
                                data: DoorControlData(
                                  doorIndex: _door,
                                  linkControl: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _Chip(
                            label: l10n.remoteControlDoorClose,
                            color: const Color(0xFFEF4444),
                            onTap: () => widget.onSend(
                              RemoteControlPayload.doorControl(
                                data: DoorControlData(
                                  doorIndex: _door,
                                  linkControl: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _OpGroup(
                      title: l10n.remoteControlOpCupMotor,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Chip(
                            label: l10n.remoteControlCupMotorOpen,
                            color: const Color(0xFF10B981),
                            onTap: () => widget.onSend(
                              RemoteControlPayload.doorControl(
                                data: DoorControlData(
                                  doorIndex: _door,
                                  cupMotor: 2,
                                ),
                              ),
                            ),
                          ),
                          _Chip(
                            label: l10n.remoteControlCupMotorClose,
                            color: const Color(0xFFEF4444),
                            onTap: () => widget.onSend(
                              RemoteControlPayload.doorControl(
                                data: DoorControlData(
                                  doorIndex: _door,
                                  cupMotor: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _OpGroup(
                      title: l10n.remoteControlOpFrontDoor,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _Chip(
                            label: l10n.remoteControlFrontDoorOpen,
                            color: const Color(0xFF10B981),
                            onTap: () => widget.onSend(
                              RemoteControlPayload.doorControl(
                                data: DoorControlData(
                                  doorIndex: _door,
                                  frontDoorMotor: 2,
                                ),
                              ),
                            ),
                          ),
                          _Chip(
                            label: l10n.remoteControlFrontDoorClose,
                            color: const Color(0xFFEF4444),
                            onTap: () => widget.onSend(
                              RemoteControlPayload.doorControl(
                                data: DoorControlData(
                                  doorIndex: _door,
                                  frontDoorMotor: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// §6 落杯
// ============================================================

class _CupDispenseSection extends StatefulWidget {
  final RemoteControlService service;
  final Future<void> Function(RemoteControlPayload payload) onSend;

  const _CupDispenseSection({required this.service, required this.onSend});

  @override
  State<_CupDispenseSection> createState() => _CupDispenseSectionState();
}

class _CupDispenseSectionState extends State<_CupDispenseSection> {
  int _cupIdx = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<ControlState?>(
      stream: widget.service.controlStateStream,
      initialData: ControlState.idle,
      builder: (_, ctrlSnap) {
        final ok = ctrlSnap.data == ControlState.controlled;
        return StreamBuilder<StatusRawData?>(
          stream: widget.service.statusDataStream,
          initialData: null,
          builder: (_, statusSnap) {
            final cupLid = statusSnap.data?.cupLidStatus;
            return _Card(
              title: l10n.remoteControlCupSection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cupLid != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final e in [
                            (1, cupLid.cup1),
                            (2, cupLid.cup2),
                            (3, cupLid.cup3),
                            (4, cupLid.cup4),
                          ])
                            _StatusTag(
                              label:
                                  '杯${e.$1} ${e.$2.present
                                      ? "在位"
                                      : e.$2.shortage
                                      ? "缺料"
                                      : "空"}',
                              isOn: e.$2.present,
                              isFault: e.$2.isJammed,
                            ),
                        ],
                      ),
                    )
                  else
                    Text(
                      l10n.remoteControlNoData,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  if (ok) ...[
                    _Segmented<int>(
                      value: _cupIdx,
                      items: {
                        1: l10n.remoteControlCupPos1,
                        2: l10n.remoteControlCupPos2,
                        3: '落杯③',
                        4: '落杯④',
                      },
                      onChanged: (v) => setState(() => _cupIdx = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(
                          label: l10n.remoteControlCupDispense,
                          onTap: () => widget.onSend(
                            RemoteControlPayload.cupDispense(
                              data: CupDispenseData(
                                index: _cupIdx,
                                action: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _Chip(
                          label: l10n.remoteControlResetAction,
                          onTap: () => widget.onSend(
                            RemoteControlPayload.cupDispense(
                              data: CupDispenseData(
                                index: _cupIdx,
                                action: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// §7 落盖
// ============================================================

class _LidDispenseSection extends StatefulWidget {
  final RemoteControlService service;
  final Future<void> Function(RemoteControlPayload payload) onSend;

  const _LidDispenseSection({required this.service, required this.onSend});

  @override
  State<_LidDispenseSection> createState() => _LidDispenseSectionState();
}

class _LidDispenseSectionState extends State<_LidDispenseSection> {
  int _lidIdx = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<ControlState?>(
      stream: widget.service.controlStateStream,
      initialData: ControlState.idle,
      builder: (_, ctrlSnap) {
        final ok = ctrlSnap.data == ControlState.controlled;
        return StreamBuilder<StatusRawData?>(
          stream: widget.service.statusDataStream,
          initialData: null,
          builder: (_, statusSnap) {
            final cupLid = statusSnap.data?.cupLidStatus;
            return _Card(
              title: l10n.remoteControlLidSection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cupLid != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final e in [
                            (1, cupLid.lid1),
                            (2, cupLid.lid2),
                          ])
                            _StatusTag(
                              label:
                                  '盖${e.$1} ${e.$2.present
                                      ? "在位"
                                      : e.$2.shortage
                                      ? "缺料"
                                      : "空"}',
                              isOn: e.$2.present,
                              isFault: e.$2.isJammed,
                            ),
                        ],
                      ),
                    )
                  else
                    Text(
                      l10n.remoteControlNoData,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  if (ok) ...[
                    _Segmented<int>(
                      value: _lidIdx,
                      items: {
                        1: l10n.remoteControlLidPos1,
                        2: l10n.remoteControlLidPos2,
                      },
                      onChanged: (v) => setState(() => _lidIdx = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Chip(
                          label: l10n.remoteControlLidDispense,
                          onTap: () => widget.onSend(
                            RemoteControlPayload.lidDispense(
                              data: LidDispenseData(
                                index: _lidIdx,
                                action: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _Chip(
                          label: l10n.remoteControlResetAction,
                          onTap: () => widget.onSend(
                            RemoteControlPayload.lidDispense(
                              data: LidDispenseData(
                                index: _lidIdx,
                                action: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// §8 咖啡机
// ============================================================

class _CoffeeSection extends StatefulWidget {
  final RemoteControlService service;
  final Future<void> Function(RemoteControlPayload payload) onSend;

  const _CoffeeSection({required this.service, required this.onSend});

  @override
  State<_CoffeeSection> createState() => _CoffeeSectionState();
}

class _CoffeeSectionState extends State<_CoffeeSection> {
  int _coffeeMachine = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<ControlState?>(
      stream: widget.service.controlStateStream,
      initialData: ControlState.idle,
      builder: (_, snap) {
        final ok = snap.data == ControlState.controlled;
        return StreamBuilder<StatusRawData?>(
          stream: widget.service.statusDataStream,
          initialData: null,
          builder: (_, stSnap) {
            final coffee = stSnap.data?.coffeeStatus;
            final moduleLink = stSnap.data?.moduleLinkStatus;
            return _Card(
              title: l10n.remoteControlCoffeeSection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (coffee != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusItem(
                            label: '咖啡机通讯',
                            value: moduleLink?.coffee == true ? '正常' : '异常',
                            valueColor: moduleLink?.coffee == true
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          _StatusItem(
                            label: '可制作',
                            value: coffee.canMake ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '豆1可制作',
                            value: coffee.canMakeBean1 ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '豆2可制作',
                            value: coffee.canMakeBean2 ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '奶1可制作',
                            value: coffee.canMakeMilk1 ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '奶2可制作',
                            value: coffee.canMakeMilk2 ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '可润湿',
                            value: coffee.canWet ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '润湿中',
                            value: coffee.isWetting ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '停止故障',
                            value: coffee.hasStopFault
                                ? coffee.stopFaultCodes.join(',')
                                : '无',
                            valueColor: coffee.hasStopFault
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                          _StatusItem(
                            label: '警告故障',
                            value: coffee.hasWarningFault
                                ? coffee.warningFaultCodes.join(',')
                                : '无',
                            valueColor: coffee.hasWarningFault
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
                          ),
                          _StatusItem(
                            label: '停机故障',
                            value: coffee.hasEmergencyFault
                                ? coffee.emergencyFaultCodes.join(',')
                                : '无',
                            valueColor: coffee.hasEmergencyFault
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                          if (coffee.orderId != null)
                            _StatusItem(
                              label: '出咖啡订单',
                              value: '${coffee.orderId}',
                            ),
                          if (coffee.milkOut1 != null)
                            _StatusItem(
                              label: '实际出奶1',
                              value: '${coffee.milkOut1} g',
                            ),
                          if (coffee.milkOut2 != null)
                            _StatusItem(
                              label: '实际出奶2',
                              value: '${coffee.milkOut2} g',
                            ),
                          if (coffee.demandGrindBean != null)
                            _StatusItem(
                              label: '需求研磨豆',
                              value:
                                  '${coffee.demandGrindBean!.toStringAsFixed(1)} g',
                            ),
                          if (coffee.actualGrindBean != null)
                            _StatusItem(
                              label: '实际研磨豆',
                              value:
                                  '${coffee.actualGrindBean!.toStringAsFixed(1)} g',
                            ),
                          if (coffee.coffeeType != null)
                            _StatusItem(
                              label: '咖啡机类型',
                              value: coffee.coffeeTypeLabel,
                            ),
                        ],
                      ),
                    )
                  else
                    Text(
                      l10n.remoteControlNoData,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  if (ok) ...[
                    _OpGroup(
                      title: l10n.remoteControlOpMachine,
                      child: _Segmented<int>(
                        value: _coffeeMachine,
                        items: {
                          1: l10n.remoteControlCoffeeMachine(1),
                          2: l10n.remoteControlCoffeeMachine(2),
                          3: l10n.remoteControlCoffeeMachine(3),
                          4: l10n.remoteControlCoffeeMachine(4),
                        },
                        onChanged: (v) => setState(() => _coffeeMachine = v),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _OpGroup(
                      title: l10n.remoteControlOpActions,
                      child: Wrap(
                        spacing: 6,
                        children: [
                          _Chip(
                            label: l10n.remoteControlCoffeeBrew,
                            color: const Color(0xFF8B4513),
                            onTap: () => widget.onSend(
                              RemoteControlPayload.coffeeAction(
                                data: CoffeeActionData(
                                  function: 19,
                                  value: _coffeeMachine,
                                ),
                              ),
                            ),
                          ),
                          _Chip(
                            label: l10n.remoteControlCoffeeRinse,
                            onTap: () => widget.onSend(
                              RemoteControlPayload.coffeeAction(
                                data: CoffeeActionData(
                                  function: 3,
                                  value: _coffeeMachine,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// §9 制冰
// ============================================================

class _IceSection extends StatefulWidget {
  final RemoteControlService service;
  final Future<void> Function(RemoteControlPayload payload) onSend;

  const _IceSection({required this.service, required this.onSend});

  @override
  State<_IceSection> createState() => _IceSectionState();
}

class _IceSectionState extends State<_IceSection> {
  bool _iceWeightMode = true;
  final TextEditingController _iceCtrl = TextEditingController(text: '100');

  @override
  void dispose() {
    _iceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<ControlState?>(
      stream: widget.service.controlStateStream,
      initialData: ControlState.idle,
      builder: (_, snap) {
        final ok = snap.data == ControlState.controlled;
        return StreamBuilder<StatusRawData?>(
          stream: widget.service.statusDataStream,
          initialData: null,
          builder: (_, stSnap) {
            final ice = stSnap.data?.iceStatus;
            final moduleLink = stSnap.data?.moduleLinkStatus;
            return _Card(
              title: l10n.remoteControlIceSection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ice != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatusItem(
                            label: '制冰机通讯',
                            value: moduleLink?.ice == true ? '正常' : '异常',
                            valueColor: ice.hasFault
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                          ),
                          _StatusItem(
                            label: '落冰中',
                            value: ice.stateCode == 2 ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '缺冰',
                            value: ice.isEmpty ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '不制冰',
                            value: ice.hasNoIceFault ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '电机故障',
                            value: ice.hasMotorFault ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '无水',
                            value: ice.hasNoWaterFault ? '是' : '否',
                          ),
                          _StatusItem(
                            label: '温度过高',
                            value: ice.hasOverheatFault ? '是' : '否',
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      l10n.remoteControlNoData,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  if (ok)
                    _OpGroup(
                      title: l10n.remoteControlOpIceMode,
                      child: Row(
                        children: [
                          _Segmented<bool>(
                            value: _iceWeightMode,
                            items: {
                              true: l10n.remoteControlIceWeightMode,
                              false: l10n.remoteControlIceContinuousMode,
                            },
                            onChanged: (v) =>
                                setState(() => _iceWeightMode = v),
                          ),
                          if (_iceWeightMode) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 72,
                              height: 36,
                              child: TextField(
                                controller: _iceCtrl,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 4,
                                  ),
                                  suffixText: 'g',
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          _Chip(
                            label: l10n.remoteControlIceStart,
                            color: const Color(0xFF06B6D4),
                            onTap: () {
                              final mode = _iceWeightMode ? 1 : 2;
                              final target = _iceWeightMode
                                  ? (int.tryParse(_iceCtrl.text) ?? 0)
                                  : 0;
                              widget.onSend(
                                RemoteControlPayload.iceDispense(
                                  data: IceDispenseData(
                                    mode: mode,
                                    target: target,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// §10 果汁
// ============================================================

class _JuiceSection extends StatefulWidget {
  final RemoteControlService service;
  final Future<void> Function(RemoteControlPayload payload) onSend;

  const _JuiceSection({required this.service, required this.onSend});

  @override
  State<_JuiceSection> createState() => _JuiceSectionState();
}

class _JuiceSectionState extends State<_JuiceSection> {
  int _juicePipe = 1;
  final TextEditingController _juiceGramsCtrl =
      TextEditingController(text: '50');

  @override
  void dispose() {
    _juiceGramsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<ControlState?>(
      stream: widget.service.controlStateStream,
      initialData: ControlState.idle,
      builder: (_, snap) {
        final ok = snap.data == ControlState.controlled;
        return StreamBuilder<StatusRawData?>(
          stream: widget.service.statusDataStream,
          initialData: null,
          builder: (_, stSnap) {
            final juice = stSnap.data?.juiceStatus;
            return _Card(
              title: l10n.remoteControlJuiceSection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (juice != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l10n.remoteControlJuice,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  else
                    Text(
                      l10n.remoteControlNoData,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  if (ok) ...[
                    _OpGroup(
                      title: l10n.remoteControlOpJuicePipe,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (var p = 1; p <= 12; p++)
                            _SelectChip(
                              label: l10n.remoteControlJuicePipe(p),
                              selected: _juicePipe == p,
                              onTap: () => setState(() => _juicePipe = p),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SizedBox(
                          width: 88,
                          height: 36,
                          child: TextField(
                            controller: _juiceGramsCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              suffixText: 'g',
                              hintText: l10n.remoteControlJuiceGramsHint,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: l10n.remoteControlJuiceStart,
                          color: const Color(0xFFF59E0B),
                          onTap: () {
                            final grams =
                                num.tryParse(_juiceGramsCtrl.text) ?? -1;
                            final pulse = (grams * 10).floor();
                            if (_juicePipe < 1 ||
                                _juicePipe > 12 ||
                                grams < 0 ||
                                !grams.isFinite ||
                                pulse < 0 ||
                                pulse > 32767) {
                              l10n.remoteControlJuiceInvalidParams.toast();
                              return;
                            }
                            widget.onSend(
                              RemoteControlPayload.juiceDispense(
                                data: JuiceDispenseData(
                                  pipe: _juicePipe,
                                  grams: grams,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ============================================================
// §7 传感器数据
// ============================================================

class _SensorDataSection extends StatelessWidget {
  final RemoteControlService service;

  const _SensorDataSection({required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<StatusRawData?>(
      stream: service.statusDataStream,
      initialData: null,
      builder: (_, snap) {
        final data = snap.data;
        final s = data?.sensorReadings;
        final stock = data?.stockData;
        final ioSignals = data?.ioInputSignals;
        final moduleLink = data?.moduleLinkStatus;
        final waterHot = data?.waterHotStatus;
        final bubble = data?.bubbleStatus;
        final juice = data?.juiceStatus;
        final drop = data?.dropStatus;
        final items = <Widget>[];
        if (s != null) {
          items.addAll(_buildRealTimeItems(s, l10n));
          if (ioSignals != null) {
            items.add(
              _StatusItem(
                label: '进水流量计',
                value: ioSignals.inputFlowMeter ? 'ON' : 'OFF',
                valueColor: ioSignals.inputFlowMeter
                    ? const Color(0xFF10B981)
                    : const Color(0xFF94A3B8),
              ),
            );
            items.add(
              _StatusItem(
                label: '进水水流开关',
                value: ioSignals.inputWaterFlowSwitch ? 'ON' : 'OFF',
                valueColor: ioSignals.inputWaterFlowSwitch
                    ? const Color(0xFF10B981)
                    : const Color(0xFF94A3B8),
              ),
            );
            items.add(
              _StatusItem(
                label: '废水流开关',
                value: ioSignals.wasteWaterFlowSwitch ? 'ON' : 'OFF',
                valueColor: ioSignals.wasteWaterFlowSwitch
                    ? const Color(0xFF10B981)
                    : const Color(0xFF94A3B8),
              ),
            );
            items.add(
              _StatusItem(
                label: '废水满开关',
                value: ioSignals.wasteWaterFullSwitch ? 'ON' : 'OFF',
                valueColor: ioSignals.wasteWaterFullSwitch
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF94A3B8),
              ),
            );
          }
          items.add(
            _StatusItem(
              label: '冷水通讯',
              value: moduleLink?.coldWater == true ? '正常' : '异常',
              valueColor: moduleLink?.coldWater == true
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
          );
          items.add(
            _StatusItem(
              label: '热水通讯',
              value: moduleLink?.waterHot == true ? '正常' : '异常',
              valueColor: moduleLink?.waterHot == true
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
          );
          items.add(
            _StatusItem(
              label: '系统缺水',
              value: s.isWaterShortage ? '是' : '否',
              valueColor: s.isWaterShortage
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
            ),
          );
          items.add(
            _StatusItem(
              label: '奶路称重通讯',
              value: moduleLink?.milkScale == true ? '正常' : '异常',
              valueColor: moduleLink?.milkScale == true
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
          );
          items.add(_StatusItem(label: '奶路1', value: '${s.milkWeight1} g'));
          items.add(_StatusItem(label: '奶路2', value: '${s.milkWeight2} g'));
          if (waterHot != null) {
            items.add(
              _StatusItem(
                label: '热水管路堵塞',
                value: waterHot.isClogged ? '是' : '否',
                valueColor: waterHot.isClogged
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            );
            items.add(
              _StatusItem(
                label: '热水加热故障',
                value: waterHot.hasHeatFault ? '是' : '否',
                valueColor: waterHot.hasHeatFault
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            );
            items.add(
              _StatusItem(label: '热水剩余脉冲', value: '${waterHot.pulseRemain}'),
            );
            items.add(
              _StatusItem(label: '出水温度', value: '${waterHot.outputTemp} ℃'),
            );
          }
          if (stock != null) {
            items.add(
              _StatusItem(label: '桶1剩余', value: '${stock.waterTank1Ml} ml'),
            );
            items.add(
              _StatusItem(label: '桶2剩余', value: '${stock.waterTank2Ml} ml'),
            );
          }
          if (bubble != null) {
            items.add(
              _StatusItem(
                label: '气泡机通讯',
                value: moduleLink?.bubble == true ? '正常' : '异常',
                valueColor: moduleLink?.bubble == true
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            );
            items.add(
              _StatusItem(
                label: '缺气',
                value: bubble.co2Empty ? '是' : '否',
                valueColor: bubble.co2Empty
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            );
            items.add(
              _StatusItem(
                label: '缺水状态',
                value: bubble.waterStateLabel,
                valueColor: bubble.isWaterEmpty
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            );
            items.add(
              _StatusItem(
                label: '气泡水剩余脉冲',
                value: '${bubble.bubblePulseRemain}',
              ),
            );
            items.add(
              _StatusItem(label: '冷水剩余脉冲', value: '${bubble.coldPulseRemain}'),
            );
            items.add(
              _StatusItem(
                label: '气压数据',
                value: '${bubble.pressure.toStringAsFixed(1)} bar',
              ),
            );
            items.add(
              _StatusItem(
                label: '气罐气压',
                value: '${bubble.gasTankPressure.toStringAsFixed(1)} bar',
              ),
            );
          }
          if (drop != null) {
            items.add(
              _StatusItem(
                label: '丢杯通讯',
                value: moduleLink?.drop == true ? '正常' : '异常',
                valueColor: moduleLink?.drop == true
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            );
            items.add(
              _StatusItem(label: '杯托上', value: drop.cupTrayUp ? 'ON' : 'OFF'),
            );
            items.add(
              _StatusItem(label: '杯托下', value: drop.cupTrayDown ? 'ON' : 'OFF'),
            );
            items.add(
              _StatusItem(
                label: '推杯电机前限位',
                value: drop.pushMotorFront ? 'ON' : 'OFF',
              ),
            );
            items.add(
              _StatusItem(
                label: '推杯电机回限位',
                value: drop.pushMotorBack ? 'ON' : 'OFF',
              ),
            );
            items.add(
              _StatusItem(
                label: '杯托故障',
                value: drop.cupTrayFault ? '是' : '否',
                valueColor: drop.cupTrayFault
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            );
            items.add(
              _StatusItem(
                label: '电机故障',
                value: drop.pushMotorFault ? '是' : '否',
                valueColor: drop.pushMotorFault
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            );
            items.add(
              _StatusItem(label: '杯托电机', value: drop.cupTrayMotorLabel),
            );
            items.add(
              _StatusItem(label: '推杯电机', value: drop.pushMotorLabel),
            );
          }
          if (juice != null) {
            items.add(
              _StatusItem(
                label: '果汁通讯1-4',
                value: moduleLink?.juiceGroup1 == true ? '正常' : '异常',
              ),
            );
            items.add(
              _StatusItem(
                label: '果汁通讯5-8',
                value: moduleLink?.juiceGroup2 == true ? '正常' : '异常',
              ),
            );
            items.add(
              _StatusItem(
                label: '果汁通讯9-12',
                value: moduleLink?.juiceGroup3 == true ? '正常' : '异常',
              ),
            );
            items.add(
              _StatusItem(label: '出料中', value: juice.isDispensing ? '是' : '否'),
            );
            for (var index = 0; index < juice.channels.length; index++) {
              final channel = juice.channels[index];
              items.add(
                _StatusItem(
                  label: '管路堵${index + 1}',
                  value: channel.isClogged ? '是' : '否',
                  valueColor: channel.isClogged
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              );
              items.add(
                _StatusItem(
                  label: '管路${index + 1}剩余脉冲',
                  value: '${channel.pulseRemain}',
                ),
              );
              if (stock != null && index < stock.juiceRemains.length) {
                items.add(
                  _StatusItem(
                    label: '管路${index + 1}剩余克重',
                    value: '${stock.juiceRemains[index]}',
                  ),
                );
              }
            }
          }
        }
        return _Card(
          title: l10n.remoteControlSensorData,
          child: items.isNotEmpty
              ? _StatusGrid(children: items)
              : Text(
                  l10n.remoteControlNoData,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
        );
      },
    );
  }

  /// 从 statusRaw 实时数据构建传感器项
  List<Widget> _buildRealTimeItems(SensorReadings s, AppLocalizations l10n) {
    return [
      _StatusItem(
        label: l10n.remoteControlSensorVoltage,
        value: '${s.voltage.toStringAsFixed(0)} V',
      ),
      _StatusItem(
        label: l10n.remoteControlSensorCurrent,
        value: '${s.current.toStringAsFixed(1)} A',
      ),
      _StatusItem(
        label: l10n.remoteControlSensorPower,
        value: '${s.power.toStringAsFixed(0)} W',
      ),
      _StatusItem(label: '能耗', value: '${s.energy.toStringAsFixed(2)} kwh'),
      _StatusItem(label: '底仓温度', value: '${s.bottomTemp} ℃'),
      _StatusItem(label: '上仓温度', value: '${s.topTemp} ℃'),
      _StatusItem(
        label: l10n.remoteControlSensorColdTemp,
        value: '${s.coldTemp} ℃',
      ),
      _StatusItem(label: '冷藏箱温度', value: '${s.coldStorageTemp} ℃'),
      _StatusItem(label: '进水温度', value: '${s.waterInTemp} ℃'),
      _StatusItem(label: '水管表面温度', value: '${s.waterSurfaceTemp} ℃'),
      _StatusItem(
        label: l10n.remoteControlSensorWaterUsage,
        value: '${s.waterUsage.toStringAsFixed(3)} L',
      ),
      _StatusItem(
        label: l10n.remoteControlSensorWaterPressure,
        value: '${s.waterPressure.toStringAsFixed(2)} bar',
      ),
      _StatusItem(label: l10n.remoteControlSensorTDS, value: '${s.tds} ppm'),
      _StatusItem(
        label: '拉花①',
        value: '请求=${s.lattePrintRequest1} 订单=${s.latteOrderId1}',
      ),
      _StatusItem(
        label: '拉花②',
        value: '请求=${s.lattePrintRequest2} 订单=${s.latteOrderId2}',
      ),
      _StatusItem(label: '奶箱冷藏温度', value: '${s.milkBoxTemp} ℃'),
      _StatusItem(label: '复位状态', value: s.isReset ? '已复位' : '未复位'),
      _StatusItem(label: '订单丢杯状态', value: s.isOrderDropBusy ? '忙碌' : '空闲'),
    ];
  }
}

// ============================================================
// §8 系统指令
// ============================================================

class _SystemCommandSection extends StatefulWidget {
  final RemoteControlService service;
  final Future<void> Function(RemoteControlPayload payload) onSend;

  const _SystemCommandSection({required this.service, required this.onSend});

  @override
  State<_SystemCommandSection> createState() => _SystemCommandSectionState();
}

class _SystemCommandSectionState extends State<_SystemCommandSection> {
  bool _cleanAll = true;
  /// 指定清理门号 UI 值 1–4
  int _cleanDoor = 1;
  /// 指定清理缓存：0xFF=不限缓存（按门清理），1–4=按缓存清理
  int _cleanCache = 0xFF;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<ControlState?>(
      stream: widget.service.controlStateStream,
      initialData: ControlState.idle,
      builder: (_, snap) {
        final ok = snap.data == ControlState.controlled;
        return _Card(
          title: l10n.remoteControlSystemSection,
          child: ok
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _Btn.full(
                            label: l10n.remoteControlReset,
                            color: const Color(0xFFF59E0B),
                            onTap: () => widget.onSend(
                              RemoteControlPayload.systemCommand(
                                data: const SystemCommandData(action: 'reset'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Btn.full(
                            label: l10n.remoteControlRestart,
                            color: const Color(0xFFEF4444),
                            onTap: () => widget.onSend(
                              RemoteControlPayload.systemCommand(
                                data:
                                    const SystemCommandData(action: 'restart'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _Segmented<bool>(
                      value: _cleanAll,
                      items: {
                        true: l10n.remoteControlCleanAll,
                        false: l10n.remoteControlCleanSpec,
                      },
                      onChanged: (v) => setState(() => _cleanAll = v),
                    ),
                    if (!_cleanAll) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.remoteControlCleanDoor,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _Segmented<int>(
                        value: _cleanDoor,
                        items: {
                          1: l10n.remoteControlDoor1,
                          2: l10n.remoteControlDoor2,
                          3: l10n.remoteControlDoor3,
                          4: l10n.remoteControlDoor4,
                        },
                        // 已选缓存清理时门号无效，仅此互斥禁用
                        disabled: _cleanCache != 0xFF,
                        onChanged: (v) => setState(() {
                          _cleanDoor = v;
                          _cleanCache = 0xFF;
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.remoteControlCleanCache,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _SelectChip(
                            label: l10n.remoteControlCleanCacheNone,
                            selected: _cleanCache == 0xFF,
                            onTap: () => setState(() => _cleanCache = 0xFF),
                          ),
                          for (var c = 1; c <= 4; c++)
                            _SelectChip(
                              label: l10n.remoteControlCacheN(c),
                              selected: _cleanCache == c,
                              onTap: () => setState(() => _cleanCache = c),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _Btn.full(
                        label: l10n.remoteControlExecuteClean,
                        color: const Color(0xFFEF4444),
                        onTap: () {
                          // 全清：省略参数
                          // 指定门：doorSelect=门号, cacheSelect=0xFF
                          // 指定缓存：doorSelect=0xFF, cacheSelect=缓存号
                          final SystemCommandData data;
                          if (_cleanAll) {
                            data =
                                const SystemCommandData(action: 'cleanOrder');
                          } else if (_cleanCache != 0xFF) {
                            data = SystemCommandData(
                              action: 'cleanOrder',
                              doorSelect: 0xFF,
                              cacheSelect: _cleanCache,
                            );
                          } else {
                            data = SystemCommandData(
                              action: 'cleanOrder',
                              doorSelect: _cleanDoor,
                              cacheSelect: 0xFF,
                            );
                          }
                          widget.onSend(
                            RemoteControlPayload.systemCommand(data: data),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : Text(
                  l10n.remoteControlNeedControlHint,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
        );
      },
    );
  }
}

// ============================================================
// §13 版本查询
// ============================================================

class _VersionSection extends StatelessWidget {
  final RemoteControlService service;
  final Future<void> Function(RemoteControlPayload payload) onSend;

  const _VersionSection({required this.service, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<ControlState?>(
      stream: service.controlStateStream,
      initialData: ControlState.idle,
      builder: (_, ctrlSnap) {
        final ok = ctrlSnap.data == ControlState.controlled;
        return StreamBuilder<StatusRawData?>(
          stream: service.statusDataStream,
          initialData: null,
          builder: (_, statusSnap) {
            final versions = statusSnap.data?.moduleVersions;
            return StreamBuilder<String?>(
              stream: service.versionQueryTextStream,
              initialData: null,
              builder: (_, versionSnap) {
                final queryText = versionSnap.data;
                return _Card(
                  title: l10n.remoteControlVersionSection,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (queryText != null && queryText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              queryText,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      if (versions != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StatusGrid(
                            children: [
                              _StatusItem(
                                label: '落杯①',
                                value: 'v${versions.cupDispenser1}',
                              ),
                              _StatusItem(
                                label: '落杯②',
                                value: 'v${versions.cupDispenser2}',
                              ),
                              _StatusItem(
                                label: '门①',
                                value: 'v${versions.door1}',
                              ),
                              _StatusItem(
                                label: '门②',
                                value: 'v${versions.door2}',
                              ),
                              _StatusItem(
                                label: '门③',
                                value: 'v${versions.door3}',
                              ),
                              _StatusItem(
                                label: '门④',
                                value: 'v${versions.door4}',
                              ),
                              _StatusItem(
                                label: '热水',
                                value: 'v${versions.waterHot}',
                              ),
                              _StatusItem(
                                label: '气泡',
                                value: 'v${versions.bubble}',
                              ),
                              _StatusItem(
                                label: '果汁①',
                                value: 'v${versions.juice1}',
                              ),
                              _StatusItem(
                                label: '果汁②',
                                value: 'v${versions.juice2}',
                              ),
                              _StatusItem(
                                label: '果汁③',
                                value: 'v${versions.juice3}',
                              ),
                              _StatusItem(
                                label: '丢杯口',
                                value: 'v${versions.drop}',
                              ),
                            ],
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: _Btn.full(
                          label: l10n.remoteControlQueryVersion,
                          color: const Color(0xFF3B82F6),
                          disabled: !ok,
                          onTap: () => onSend(
                            const RemoteControlPayload.versionQuery(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ============================================================
// 通用组件
// ============================================================

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ],
);

class _Card extends StatelessWidget {
  final String title;
  final Widget child;

  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// 操作分组：小标题 + 内容，区分「选什么 → 动什么」
class _OpGroup extends StatelessWidget {
  final String title;
  final Widget child;

  const _OpGroup({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _StatusGrid extends StatelessWidget {
  final List<Widget> children;
  const _StatusGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _StatusItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}

/// 动作按钮点击置灰时长
const Duration _kActionTapFlash = Duration(milliseconds: 500);

class _Btn extends StatefulWidget {
  final String label;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.color,
    this.disabled = false,
    required this.onTap,
  });

  const _Btn.full({
    required String label,
    required Color color,
    bool disabled = false,
    required VoidCallback onTap,
  }) : this(label: label, color: color, disabled: disabled, onTap: onTap);

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _flashing = false;

  Future<void> _handleTap() async {
    if (widget.disabled || _flashing) return;
    setState(() => _flashing = true);
    widget.onTap();
    await Future<void>.delayed(_kActionTapFlash);
    if (mounted) setState(() => _flashing = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.disabled && !_flashing;
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: enabled ? _handleTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? widget.color : const Color(0xFFE2E8F0),
          foregroundColor: enabled ? Colors.white : const Color(0xFF94A3B8),
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Text(
          widget.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// 动作按钮（实心色块 + 白字），与选择器样式区分
class _Chip extends StatefulWidget {
  final String label;
  final Color? color;
  final bool disabled;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    this.color,
    this.disabled = false,
    required this.onTap,
  });

  @override
  State<_Chip> createState() => _ChipState();
}

class _ChipState extends State<_Chip> {
  bool _flashing = false;

  Future<void> _handleTap() async {
    if (widget.disabled || _flashing) return;
    setState(() => _flashing = true);
    widget.onTap();
    await Future<void>.delayed(_kActionTapFlash);
    if (mounted) setState(() => _flashing = false);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.disabled && !_flashing;
    final base = widget.color ?? const Color(0xFF3B82F6);
    final bg = enabled ? base : const Color(0xFFE2E8F0);
    final fg = enabled ? Colors.white : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: enabled ? _handleTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 80),
        opacity: _flashing ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: base.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// 选择 chip（描边），用于管路/缓存等互斥选项，不是动作
class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.selected,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !disabled;
    final border = selected
        ? const Color(0xFF3B82F6)
        : const Color(0xFFCBD5E1);
    final bg = selected
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFFFFFFF);
    final fg = selected
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF64748B);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// 状态标签（门开/关/故障）
class _StatusTag extends StatelessWidget {
  final String label;
  final bool isOn;
  final bool isFault;

  const _StatusTag({
    required this.label,
    this.isOn = false,
    this.isFault = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isFault
        ? const Color(0xFFFEF2F2)
        : (isOn ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9));
    final fg = isFault
        ? const Color(0xFFEF4444)
        : (isOn ? const Color(0xFF10B981) : const Color(0xFF94A3B8));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// 继电器开关：状态色 + 可点时动作反馈
class _ToggleChip extends StatefulWidget {
  final String label;
  final bool value;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  const _ToggleChip({
    required this.label,
    required this.value,
    this.disabled = false,
    required this.onChanged,
  });

  @override
  State<_ToggleChip> createState() => _ToggleChipState();
}

class _ToggleChipState extends State<_ToggleChip> {
  bool _flashing = false;

  Future<void> _handleTap() async {
    if (widget.disabled || _flashing) return;
    setState(() => _flashing = true);
    widget.onChanged(!widget.value);
    await Future<void>.delayed(_kActionTapFlash);
    if (mounted) setState(() => _flashing = false);
  }

  @override
  Widget build(BuildContext context) {
    // 颜色只跟继电器开/关；无控制权时仍展示状态，仅禁止点击
    final on = widget.value;
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: on ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: on ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            on ? Icons.toggle_on : Icons.toggle_off,
            size: 18,
            color: on ? Colors.white : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 4),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: on ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
    return Opacity(
      opacity: widget.disabled
          ? 0.72
          : (_flashing ? 0.5 : 1),
      child: GestureDetector(
        onTap: widget.disabled ? null : _handleTap,
        child: chip,
      ),
    );
  }
}

/// 分段选择器（描边样式），用于门号/臂号等，不是动作按钮
class _Segmented<T> extends StatelessWidget {
  final T value;
  final Map<T, String> items;
  final bool disabled;
  final ValueChanged<T> onChanged;

  const _Segmented({
    required this.value,
    required this.items,
    this.disabled = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final entries = items.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(3),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          final sel = e.key == value;
          return GestureDetector(
            onTap: disabled ? null : () => onChanged(e.key),
            child: Opacity(
              opacity: disabled ? 0.5 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  // 选中：浅蓝底 + 蓝边 + 蓝字；未选中：透明，与实心动作按钮明显不同
                  color: sel
                      ? const Color(0xFFEFF6FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: sel
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sel
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
