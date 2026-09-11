import 'package:json_annotation/json_annotation.dart';
import 'package:operation/ext/enums.dart';

part 'api_alert.g.dart';

// ============================================================
// JSON 序列化辅助函数
// ============================================================

/// AlertTypeEnum 反序列化
AlertTypeEnum? alertTypeFromJson(String? value) =>
    value != null ? AlertTypeEnum.fromApiValue(value) : null;

/// AlertTypeEnum 序列化
String? alertTypeToJson(AlertTypeEnum? value) => value?.apiValue;

/// AlertStatusEnum 反序列化
AlertStatusEnum? alertStatusFromJson(String? value) =>
    value != null ? AlertStatusEnum.fromApiValue(value) : null;

/// AlertStatusEnum 序列化
String? alertStatusToJson(AlertStatusEnum? value) => value?.apiValue;

// ============================================================
// 告警项 VO
// ============================================================

/// 告警项，对应后端 AlertItemVo
@JsonSerializable()
class AlertItemVo {
  /// 告警ID
  @JsonKey(name: "id")
  final int? id;
  /// 设备ID
  @JsonKey(name: "deviceId")
  final int? deviceId;
  /// 设备名称
  @JsonKey(name: "deviceName")
  final String? deviceName;
  /// 设备编码
  @JsonKey(name: "deviceCode")
  final String? deviceCode;
  /// 告警类型
  @JsonKey(name: "alertType", fromJson: alertTypeFromJson, toJson: alertTypeToJson)
  final AlertTypeEnum? alertType;
  /// 故障/告警码
  @JsonKey(name: "errorCode")
  final String? errorCode;
  /// 故障/告警描述
  @JsonKey(name: "errorDescription")
  final String? errorDescription;
  /// 告警状态
  @JsonKey(name: "status", fromJson: alertStatusFromJson, toJson: alertStatusToJson)
  final AlertStatusEnum? status;
  /// 发生次数
  @JsonKey(name: "occurrenceCount")
  final int? occurrenceCount;
  /// 扩展数据（JSONB，按 alertType 不同存不同结构）
  @JsonKey(name: "extra")
  final Map<String, dynamic>? extra;
  /// 首次发生时间（毫秒级时间戳）
  @JsonKey(name: "firstOccurTime")
  final int? firstOccurTime;
  /// 确认时间（毫秒级时间戳）
  @JsonKey(name: "ackTime")
  final int? ackTime;
  /// 消除时间（毫秒级时间戳）
  @JsonKey(name: "resolveTime")
  final int? resolveTime;
  /// 更新时间（毫秒级时间戳）
  @JsonKey(name: "updateTime")
  final int? updateTime;

  AlertItemVo({
    this.id,
    this.deviceId,
    this.deviceName,
    this.deviceCode,
    this.alertType,
    this.errorCode,
    this.errorDescription,
    this.status,
    this.occurrenceCount,
    this.extra,
    this.firstOccurTime,
    this.ackTime,
    this.resolveTime,
    this.updateTime,
  });

  factory AlertItemVo.fromJson(Map<String, dynamic> json) => _$AlertItemVoFromJson(json);

  Map<String, dynamic> toJson() => _$AlertItemVoToJson(this);
}

// ============================================================
// 告警统计 VO
// ============================================================

/// 告警数量统计，对应后端 AlertCountVo
@JsonSerializable()
class AlertCountVo {
  /// 新故障数
  @JsonKey(name: "faultCount")
  final int? faultCount;
  /// 新告警数
  @JsonKey(name: "warningCount")
  final int? warningCount;
  /// 新缺货数
  @JsonKey(name: "stockOutCount")
  final int? stockOutCount;

  AlertCountVo({this.faultCount, this.warningCount, this.stockOutCount});

  factory AlertCountVo.fromJson(Map<String, dynamic> json) => _$AlertCountVoFromJson(json);

  Map<String, dynamic> toJson() => _$AlertCountVoToJson(this);
}

// ============================================================
// API 请求体
// ============================================================

/// 告警列表查询请求体，对应后端 AlertQueryRequestBody
class AlertQueryRequestBody {
  /// 设备ID（可选过滤）
  final int? deviceId;
  /// 告警类型（可选过滤）
  final String? alertType;
  /// 故障/告警码（可选过滤）
  final String? errorCode;
  /// 告警状态（可选过滤）
  final String? status;
  /// 时间区间起点（毫秒级时间戳）
  final int? startTime;
  /// 时间区间终点（毫秒级时间戳）
  final int? endTime;
  /// 每页条数
  final int? limit;
  /// 偏移量
  final int? offset;

  AlertQueryRequestBody({this.deviceId, this.alertType, this.errorCode, this.status, this.startTime, this.endTime, this.limit, this.offset});

  Map<String, dynamic> toJson() => {
    "deviceId": deviceId,
    "alertType": alertType,
    "errorCode": errorCode,
    "status": status,
    "startTime": startTime,
    "endTime": endTime,
    "limit": limit,
    "offset": offset,
  };
}

/// 告警批量操作请求体，对应后端 AlertBatchRequestBody
class AlertBatchRequestBody {
  /// 告警ID列表
  final List<int> alertIds;

  AlertBatchRequestBody({required this.alertIds});

  Map<String, dynamic> toJson() => {"alertIds": alertIds};
}

/// 告警分页结果
@JsonSerializable()
class AlertPageResult {
  /// 总条数
  @JsonKey(name: "total")
  final int? total;
  /// 告警列表
  @JsonKey(name: "list")
  final List<AlertItemVo>? list;

  AlertPageResult({this.total, this.list});

  factory AlertPageResult.fromJson(Map<String, dynamic> json) => _$AlertPageResultFromJson(json);

  Map<String, dynamic> toJson() => _$AlertPageResultToJson(this);
}
