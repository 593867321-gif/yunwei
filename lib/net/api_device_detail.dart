import 'package:json_annotation/json_annotation.dart';

part 'api_device_detail.g.dart';

// ============================================================
// 注意：所有时间戳均为 int64 毫秒值
// ============================================================

// ============================================================
// 设备在线事件 DTO
// ============================================================

/// 在线事件条目
@JsonSerializable()
class OnlineEventVo {
  /// 事件时间戳（毫秒）
  @JsonKey(name: 'ts')
  final int ts;
  /// 在线状态字符串
  @JsonKey(name: 'online')
  final String? online;

  const OnlineEventVo({required this.ts, this.online});

  factory OnlineEventVo.fromJson(Map<String, dynamic> json) => _$OnlineEventVoFromJson(json);
  Map<String, dynamic> toJson() => _$OnlineEventVoToJson(this);
}

/// 在线事件分页结果
@JsonSerializable()
class OnlineEventsPage {
  /// 在线事件列表
  @JsonKey(name: 'content')
  final List<OnlineEventVo> content;
  /// 总记录数
  @JsonKey(name: 'total')
  final int total;
  /// 当前页号
  @JsonKey(name: 'number')
  final int number;
  /// 每页大小
  @JsonKey(name: 'size')
  final int size;

  const OnlineEventsPage({this.content = const [], this.total = 0, this.number = 0, this.size = 0});

  factory OnlineEventsPage.fromJson(Map<String, dynamic> json) => _$OnlineEventsPageFromJson(json);
  Map<String, dynamic> toJson() => _$OnlineEventsPageToJson(this);
}

// ============================================================
// 设备故障/告警历史 DTO
// ============================================================

/// 故障历史条目
@JsonSerializable()
class FaultHistoryVo {
  /// 事件时间戳（毫秒）
  @JsonKey(name: 'ts')
  final int ts;
  /// 故障码字符串列表
  @JsonKey(name: 'errors')
  final List<String> errors;
  /// 告警码字符串列表
  @JsonKey(name: 'warnings')
  final List<String> warnings;

  const FaultHistoryVo({required this.ts, this.errors = const [], this.warnings = const []});

  factory FaultHistoryVo.fromJson(Map<String, dynamic> json) => _$FaultHistoryVoFromJson(json);
  Map<String, dynamic> toJson() => _$FaultHistoryVoToJson(this);
}

/// 故障历史分页结果
@JsonSerializable()
class FaultHistoryPage {
  /// 故障历史列表
  @JsonKey(name: 'content')
  final List<FaultHistoryVo> content;
  /// 总记录数
  @JsonKey(name: 'total')
  final int total;
  /// 当前页号
  @JsonKey(name: 'number')
  final int number;
  /// 每页大小
  @JsonKey(name: 'size')
  final int size;

  const FaultHistoryPage({this.content = const [], this.total = 0, this.number = 0, this.size = 0});

  factory FaultHistoryPage.fromJson(Map<String, dynamic> json) => _$FaultHistoryPageFromJson(json);
  Map<String, dynamic> toJson() => _$FaultHistoryPageToJson(this);
}

// ============================================================
// 电气曲线 DTO
// ============================================================

/// 电气曲线数据点
@JsonSerializable()
class ElectricalChartPointVo {
  /// 采样时间戳（毫秒）
  @JsonKey(name: 'ts')
  final int ts;
  /// 平均值
  @JsonKey(name: 'value')
  final double? value;

  const ElectricalChartPointVo({required this.ts, this.value});

  factory ElectricalChartPointVo.fromJson(Map<String, dynamic> json) => _$ElectricalChartPointVoFromJson(json);
  Map<String, dynamic> toJson() => _$ElectricalChartPointVoToJson(this);
}

// ============================================================
// 请求体 DTO（手动编写，无需代码生成）
// ============================================================

/// 设备在线事件 / 故障历史请求体（共用结构）
class OperationDeviceEventsRequestBody {
  /// 设备编码
  final String deviceCode;
  /// 开始时间（毫秒时间戳，可选）
  final int? startTime;
  /// 结束时间（毫秒时间戳，可选）
  final int? endTime;
  /// 每页条数（1-200）
  final int limit;
  /// 页码（从 0 开始）
  final int offset;

  const OperationDeviceEventsRequestBody({
    required this.deviceCode,
    this.startTime,
    this.endTime,
    this.limit = 50,
    this.offset = 0,
  });

  Map<String, dynamic> toJson() => {
    'deviceCode': deviceCode,
    if (startTime != null) 'startTime': startTime,
    if (endTime != null) 'endTime': endTime,
    'limit': limit,
    'offset': offset,
  };
}

/// 电气曲线请求体
class OperationElectricalChartRequestBody {
  /// 设备编码
  final String deviceCode;
  /// 查询日期（某天零点毫秒时间戳）
  final int date;
  /// 电气指标编码
  final String metric;

  const OperationElectricalChartRequestBody({
    required this.deviceCode,
    required this.date,
    required this.metric,
  });

  Map<String, dynamic> toJson() => {
    'deviceCode': deviceCode,
    'date': date,
    'metric': metric,
  };
}
