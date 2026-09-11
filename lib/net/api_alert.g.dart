// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AlertItemVo _$AlertItemVoFromJson(Map<String, dynamic> json) => AlertItemVo(
  id: (json['id'] as num?)?.toInt(),
  deviceId: (json['deviceId'] as num?)?.toInt(),
  deviceName: json['deviceName'] as String?,
  deviceCode: json['deviceCode'] as String?,
  alertType: alertTypeFromJson(json['alertType'] as String?),
  errorCode: json['errorCode'] as String?,
  errorDescription: json['errorDescription'] as String?,
  status: alertStatusFromJson(json['status'] as String?),
  occurrenceCount: (json['occurrenceCount'] as num?)?.toInt(),
  extra: json['extra'] as Map<String, dynamic>?,
  firstOccurTime: (json['firstOccurTime'] as num?)?.toInt(),
  ackTime: (json['ackTime'] as num?)?.toInt(),
  resolveTime: (json['resolveTime'] as num?)?.toInt(),
  updateTime: (json['updateTime'] as num?)?.toInt(),
);

Map<String, dynamic> _$AlertItemVoToJson(AlertItemVo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'deviceCode': instance.deviceCode,
      'alertType': alertTypeToJson(instance.alertType),
      'errorCode': instance.errorCode,
      'errorDescription': instance.errorDescription,
      'status': alertStatusToJson(instance.status),
      'occurrenceCount': instance.occurrenceCount,
      'extra': instance.extra,
      'firstOccurTime': instance.firstOccurTime,
      'ackTime': instance.ackTime,
      'resolveTime': instance.resolveTime,
      'updateTime': instance.updateTime,
    };

AlertCountVo _$AlertCountVoFromJson(Map<String, dynamic> json) => AlertCountVo(
  faultCount: (json['faultCount'] as num?)?.toInt(),
  warningCount: (json['warningCount'] as num?)?.toInt(),
  stockOutCount: (json['stockOutCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$AlertCountVoToJson(AlertCountVo instance) =>
    <String, dynamic>{
      'faultCount': instance.faultCount,
      'warningCount': instance.warningCount,
      'stockOutCount': instance.stockOutCount,
    };

AlertPageResult _$AlertPageResultFromJson(Map<String, dynamic> json) =>
    AlertPageResult(
      total: (json['total'] as num?)?.toInt(),
      list: (json['list'] as List<dynamic>?)
          ?.map((e) => AlertItemVo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AlertPageResultToJson(AlertPageResult instance) =>
    <String, dynamic>{'total': instance.total, 'list': instance.list};
