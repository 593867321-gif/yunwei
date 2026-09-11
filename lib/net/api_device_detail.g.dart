// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_device_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OnlineEventVo _$OnlineEventVoFromJson(Map<String, dynamic> json) =>
    OnlineEventVo(
      ts: (json['ts'] as num).toInt(),
      online: json['online'] as String?,
    );

Map<String, dynamic> _$OnlineEventVoToJson(OnlineEventVo instance) =>
    <String, dynamic>{'ts': instance.ts, 'online': instance.online};

OnlineEventsPage _$OnlineEventsPageFromJson(Map<String, dynamic> json) =>
    OnlineEventsPage(
      content:
          (json['content'] as List<dynamic>?)
              ?.map((e) => OnlineEventVo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$OnlineEventsPageToJson(OnlineEventsPage instance) =>
    <String, dynamic>{
      'content': instance.content,
      'total': instance.total,
      'number': instance.number,
      'size': instance.size,
    };

FaultHistoryVo _$FaultHistoryVoFromJson(
  Map<String, dynamic> json,
) => FaultHistoryVo(
  ts: (json['ts'] as num).toInt(),
  errors:
      (json['errors'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  warnings:
      (json['warnings'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$FaultHistoryVoToJson(FaultHistoryVo instance) =>
    <String, dynamic>{
      'ts': instance.ts,
      'errors': instance.errors,
      'warnings': instance.warnings,
    };

FaultHistoryPage _$FaultHistoryPageFromJson(Map<String, dynamic> json) =>
    FaultHistoryPage(
      content:
          (json['content'] as List<dynamic>?)
              ?.map((e) => FaultHistoryVo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$FaultHistoryPageToJson(FaultHistoryPage instance) =>
    <String, dynamic>{
      'content': instance.content,
      'total': instance.total,
      'number': instance.number,
      'size': instance.size,
    };

ElectricalChartPointVo _$ElectricalChartPointVoFromJson(
  Map<String, dynamic> json,
) => ElectricalChartPointVo(
  ts: (json['ts'] as num).toInt(),
  value: (json['value'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ElectricalChartPointVoToJson(
  ElectricalChartPointVo instance,
) => <String, dynamic>{'ts': instance.ts, 'value': instance.value};
