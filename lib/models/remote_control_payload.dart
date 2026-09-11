import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_control_payload.freezed.dart';
part 'remote_control_payload.g.dart';

/// MQTT 远程控制消息模型
///
/// 采用 discriminated union 模式，`cmd` 作为分发键，每种指令携带独立的 `data` 对象。
/// 协议定义见 operation-remote-control.md §4。

// ============================================================
// 硬件指令 data 子对象
// ============================================================

/// 继电器控制参数
@JsonSerializable()
class RelayToggleData {
  /// 继电器索引（1-24，0xFF=全开，0x00=全关）
  final int relayIndex;
  /// true=开，false=关
  final bool on;

  const RelayToggleData({required this.relayIndex, required this.on});

  factory RelayToggleData.fromJson(Map<String, dynamic> json) => _$RelayToggleDataFromJson(json);
  Map<String, dynamic> toJson() => _$RelayToggleDataToJson(this);
}

/// 机械臂操作参数
@JsonSerializable()
class RobotActionData {
  /// 机械臂编号（1=①号臂, 2=②号臂）
  final int arm;
  /// 操作码（0=无操作, 1=复位, 2=上使能, 3=下使能, 4=运行程序, 5=停止,
  /// 6=进入拖拽, 7=退出拖拽, 8=压盖位继续, 9=原点丢杯, 10=缓存丢杯, 11=出杯口丢杯）
  final int action;
  /// 丢杯目标（1=咖啡位, 2=缓存1, 3=缓存2, 4=缓存3），非丢杯类填 0
  final int dropTarget;
  /// 出餐门编号（1-4），不涉及填 0
  final int cupOut;
  /// 缓存位编号（1-4），不涉及填 0
  final int cacheDiscard;

  const RobotActionData({
    required this.arm,
    required this.action,
    required this.dropTarget,
    required this.cupOut,
    required this.cacheDiscard,
  });

  factory RobotActionData.fromJson(Map<String, dynamic> json) => _$RobotActionDataFromJson(json);
  Map<String, dynamic> toJson() => _$RobotActionDataToJson(this);
}

/// 咖啡机操作参数
@JsonSerializable()
class CoffeeActionData {
  /// 功能码：19=出咖啡，3=润湿（对齐 PageStep / remote-control.md）
  final int function;
  /// 咖啡机编号（1-based），出咖啡与润湿均传机号
  final int value;

  const CoffeeActionData({required this.function, required this.value});

  factory CoffeeActionData.fromJson(Map<String, dynamic> json) => _$CoffeeActionDataFromJson(json);
  Map<String, dynamic> toJson() => _$CoffeeActionDataToJson(this);
}

/// 出餐门控制参数
///
/// 对齐 PageStep：cupMotor / frontDoorMotor / linkControl 为 0=不控，**1=关，2=开**。
/// 三路默认 0；恰好一路为 1 或 2。
@JsonSerializable(includeIfNull: false)
class DoorControlData {
  /// 门索引（1-4）
  final int doorIndex;
  /// 杯托电机：0=不控，1=关，2=开
  final int? cupMotor;
  /// 前门电机：0=不控，1=关，2=开
  final int? frontDoorMotor;
  /// 联动：0=不控，1=关，2=开
  final int? linkControl;

  const DoorControlData({
    required this.doorIndex,
    this.cupMotor,
    this.frontDoorMotor,
    this.linkControl,
  });

  factory DoorControlData.fromJson(Map<String, dynamic> json) => _$DoorControlDataFromJson(json);
  Map<String, dynamic> toJson() => _$DoorControlDataToJson(this);
}

/// 落杯参数
@JsonSerializable()
class CupDispenseData {
  /// 落杯位索引
  final int index;
  /// 动作码（1=落杯, 2=复位）
  final int action;

  const CupDispenseData({required this.index, required this.action});

  factory CupDispenseData.fromJson(Map<String, dynamic> json) => _$CupDispenseDataFromJson(json);
  Map<String, dynamic> toJson() => _$CupDispenseDataToJson(this);
}

/// 落盖参数
@JsonSerializable()
class LidDispenseData {
  /// 落盖位索引
  final int index;
  /// 动作码（1=落盖, 2=复位）
  final int action;

  const LidDispenseData({required this.index, required this.action});

  factory LidDispenseData.fromJson(Map<String, dynamic> json) => _$LidDispenseDataFromJson(json);
  Map<String, dynamic> toJson() => _$LidDispenseDataToJson(this);
}

/// 制冰参数
@JsonSerializable()
class IceDispenseData {
  /// 模式（1=克重, 2=连续）
  final int mode;
  /// 目标值（克重模式=克数，连续模式忽略）
  final int target;

  const IceDispenseData({required this.mode, required this.target});

  factory IceDispenseData.fromJson(Map<String, dynamic> json) => _$IceDispenseDataFromJson(json);
  Map<String, dynamic> toJson() => _$IceDispenseDataToJson(this);
}

/// 果汁出料参数
@JsonSerializable()
class JuiceDispenseData {
  /// 管路号 1–12
  final int pipe;
  /// 目标克重（可小数）；设备端 pulse = floor(grams×10)，须落在 0…32767
  final num grams;

  const JuiceDispenseData({required this.pipe, required this.grams});

  factory JuiceDispenseData.fromJson(Map<String, dynamic> json) => _$JuiceDispenseDataFromJson(json);
  Map<String, dynamic> toJson() => _$JuiceDispenseDataToJson(this);
}

/// 系统指令参数
@JsonSerializable(includeIfNull: false)
class SystemCommandData {
  /// 动作类型（"reset" | "restart" | "cleanOrder"）
  final String action;
  /// 指定门号（cleanOrder 时可选，省略=全清）
  final int? doorSelect;
  /// 指定缓存位（cleanOrder 时可选，省略=全清）
  final int? cacheSelect;

  const SystemCommandData({required this.action, this.doorSelect, this.cacheSelect});

  factory SystemCommandData.fromJson(Map<String, dynamic> json) => _$SystemCommandDataFromJson(json);
  Map<String, dynamic> toJson() => _$SystemCommandDataToJson(this);
}

// ============================================================
// 主 Payload（discriminated union: cmd → 子类型）
// ============================================================

@Freezed(unionKey: 'cmd')
sealed class RemoteControlPayload with _$RemoteControlPayload {
  // --- 控制权管理 ---

  /// 申请控制权
  @FreezedUnionValue('acquireControl')
  const factory RemoteControlPayload.acquireControl() = AcquireControl;

  /// 释放控制权
  @FreezedUnionValue('releaseControl')
  const factory RemoteControlPayload.releaseControl() = ReleaseControl;

  /// 心跳维持（30s 间隔）
  @FreezedUnionValue('heartbeat')
  const factory RemoteControlPayload.heartbeat() = Heartbeat;

  // --- 状态查看 ---

  /// 开启状态推送
  @FreezedUnionValue('startStatusPush')
  const factory RemoteControlPayload.startStatusPush() = StartStatusPush;

  /// 关闭状态推送
  @FreezedUnionValue('stopStatusPush')
  const factory RemoteControlPayload.stopStatusPush() = StopStatusPush;

  // --- 硬件控制 ---

  /// 继电器控制
  @FreezedUnionValue('relayToggle')
  const factory RemoteControlPayload.relayToggle({required RelayToggleData data}) = RelayToggle;

  /// 机械臂操作
  @FreezedUnionValue('robotAction')
  const factory RemoteControlPayload.robotAction({required RobotActionData data}) = RobotAction;

  /// 咖啡机操作
  @FreezedUnionValue('coffeeAction')
  const factory RemoteControlPayload.coffeeAction({required CoffeeActionData data}) = CoffeeAction;

  /// 出餐门控制
  @FreezedUnionValue('doorControl')
  const factory RemoteControlPayload.doorControl({required DoorControlData data}) = DoorControl;

  /// 落杯
  @FreezedUnionValue('cupDispense')
  const factory RemoteControlPayload.cupDispense({required CupDispenseData data}) = CupDispense;

  /// 落盖
  @FreezedUnionValue('lidDispense')
  const factory RemoteControlPayload.lidDispense({required LidDispenseData data}) = LidDispense;

  /// 制冰
  @FreezedUnionValue('iceDispense')
  const factory RemoteControlPayload.iceDispense({required IceDispenseData data}) = IceDispense;

  /// 果汁出料
  @FreezedUnionValue('juiceDispense')
  const factory RemoteControlPayload.juiceDispense({required JuiceDispenseData data}) = JuiceDispense;

  /// 查询固件版本
  @FreezedUnionValue('versionQuery')
  const factory RemoteControlPayload.versionQuery() = VersionQuery;

  /// 系统指令（复位/重启/清理订单）
  @FreezedUnionValue('systemCommand')
  const factory RemoteControlPayload.systemCommand({required SystemCommandData data}) = SystemCommand;

  // --- 协议 §8 后续优化 ---

  /// 强制释放控制权（管理员）
  @FreezedUnionValue('forceRelease')
  const factory RemoteControlPayload.forceRelease() = ForceRelease;

  /// 查询当前控制权状态
  @FreezedUnionValue('queryControl')
  const factory RemoteControlPayload.queryControl() = QueryControl;

  factory RemoteControlPayload.fromJson(Map<String, dynamic> json) => _$RemoteControlPayloadFromJson(json);
}

// ============================================================
// 回复消息模型
// ============================================================

/// 远程控制指令回复
///
/// success: {"cmd": "...", "status": "ok"}
/// fail:    {"cmd": "...", "status": "fail", "reason": "NotController"}
@JsonSerializable()
class ReplyPayload {
  /// 对应指令的 cmd
  final String cmd;
  /// "ok" 或 "fail"
  final String status;
  /// 失败原因标识符（仅 status="fail" 时出现）
  final String? reason;
  /// 当前控制者 cId（仅 acquireControl 被占用时出现）
  final String? controller;
  /// 版本查询结果字符串（仅 versionQuery 成功时出现）
  final String? data;
  /// 当前查看者列表（仅 queryControl 回复时出现）
  final List<String>? viewers;

  const ReplyPayload({
    required this.cmd,
    required this.status,
    this.reason,
    this.controller,
    this.data,
    this.viewers,
  });

  /// 是否成功
  bool get isOk => status == 'ok';

  factory ReplyPayload.fromJson(Map<String, dynamic> json) => _$ReplyPayloadFromJson(json);
  Map<String, dynamic> toJson() => _$ReplyPayloadToJson(this);
}
