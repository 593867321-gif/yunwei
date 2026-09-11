// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginInfo _$LoginInfoFromJson(Map<String, dynamic> json) => LoginInfo(
  token: json['token'] as String?,
  user: json['user'] == null
      ? null
      : UserBean.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LoginInfoToJson(LoginInfo instance) => <String, dynamic>{
  'token': instance.token,
  'user': instance.user,
};

OperationDashboardVo _$OperationDashboardVoFromJson(
  Map<String, dynamic> json,
) => OperationDashboardVo(
  userName: json['userName'] as String?,
  todayOrderCount: (json['todayOrderCount'] as num?)?.toInt(),
  todayItemCount: (json['todayItemCount'] as num?)?.toInt(),
  todayRevenue: (json['todayRevenue'] as num?)?.toDouble(),
  todayOtherPayRevenue: (json['todayOtherPayRevenue'] as num?)?.toDouble(),
  todayBalanceRevenue: (json['todayBalanceRevenue'] as num?)?.toDouble(),
  onlineDeviceCount: (json['onlineDeviceCount'] as num?)?.toInt(),
  totalDeviceCount: (json['totalDeviceCount'] as num?)?.toInt(),
  inventoryAlertCount: (json['inventoryAlertCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$OperationDashboardVoToJson(
  OperationDashboardVo instance,
) => <String, dynamic>{
  'userName': instance.userName,
  'todayOrderCount': instance.todayOrderCount,
  'todayItemCount': instance.todayItemCount,
  'todayRevenue': instance.todayRevenue,
  'todayOtherPayRevenue': instance.todayOtherPayRevenue,
  'todayBalanceRevenue': instance.todayBalanceRevenue,
  'onlineDeviceCount': instance.onlineDeviceCount,
  'totalDeviceCount': instance.totalDeviceCount,
  'inventoryAlertCount': instance.inventoryAlertCount,
};

OperationDeviceItemVo _$OperationDeviceItemVoFromJson(
  Map<String, dynamic> json,
) => OperationDeviceItemVo(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  deviceCode: json['deviceCode'] as String?,
  model: json['model'] as String?,
  onlineStatus: onlineStatusFromJson(json['onlineStatus'] as String?),
  storeId: (json['storeId'] as num?)?.toInt(),
  storeName: json['storeName'] as String?,
  status: json['status'] as bool?,
);

Map<String, dynamic> _$OperationDeviceItemVoToJson(
  OperationDeviceItemVo instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'deviceCode': instance.deviceCode,
  'model': instance.model,
  'onlineStatus': onlineStatusToJson(instance.onlineStatus),
  'storeId': instance.storeId,
  'storeName': instance.storeName,
  'status': instance.status,
};

OperationStoreVo _$OperationStoreVoFromJson(Map<String, dynamic> json) =>
    OperationStoreVo(
      storeId: (json['storeId'] as num?)?.toInt(),
      storeName: json['storeName'] as String?,
      devices: (json['devices'] as List<dynamic>?)
          ?.map(
            (e) => OperationDeviceItemVo.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$OperationStoreVoToJson(OperationStoreVo instance) =>
    <String, dynamic>{
      'storeId': instance.storeId,
      'storeName': instance.storeName,
      'devices': instance.devices,
    };

OperationOperatorVo _$OperationOperatorVoFromJson(Map<String, dynamic> json) =>
    OperationOperatorVo(
      operatorId: (json['operatorId'] as num?)?.toInt(),
      operatorName: json['operatorName'] as String?,
      stores: (json['stores'] as List<dynamic>?)
          ?.map((e) => OperationStoreVo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OperationOperatorVoToJson(
  OperationOperatorVo instance,
) => <String, dynamic>{
  'operatorId': instance.operatorId,
  'operatorName': instance.operatorName,
  'stores': instance.stores,
};

MqttInfoVo _$MqttInfoVoFromJson(Map<String, dynamic> json) => MqttInfoVo(
  userName: json['userName'] as String?,
  password: json['password'] as String?,
  clientId: json['clientId'] as String?,
  groupId: json['groupId'] as String?,
  expirationTime: (json['expirationTime'] as num?)?.toInt(),
);

Map<String, dynamic> _$MqttInfoVoToJson(MqttInfoVo instance) =>
    <String, dynamic>{
      'userName': instance.userName,
      'password': instance.password,
      'clientId': instance.clientId,
      'groupId': instance.groupId,
      'expirationTime': instance.expirationTime,
    };

UserBean _$UserBeanFromJson(Map<String, dynamic> json) => UserBean(
  id: (json['id'] as num?)?.toInt(),
  createTime: (json['createTime'] as num?)?.toInt(),
  updateTime: (json['updateTime'] as num?)?.toInt(),
  deleteTime: json['deleteTime'],
  isDel: json['isDel'] as bool?,
  account: json['account'] as String?,
  nickname: json['nickname'] as String?,
  avatar: json['avatar'],
  isAdmin: json['isAdmin'] as bool?,
  departmentId: json['departmentId'],
  status: json['status'] as bool?,
  tokenIssuedAt: (json['tokenIssuedAt'] as num?)?.toInt(),
  interfaceDic: json['interfaceDic'] as List<dynamic>?,
  rolesId: (json['rolesId'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  rolesName: json['rolesName'] as List<dynamic>?,
  operators: json['operators'] as List<dynamic>?,
);

Map<String, dynamic> _$UserBeanToJson(UserBean instance) => <String, dynamic>{
  'id': instance.id,
  'createTime': instance.createTime,
  'updateTime': instance.updateTime,
  'deleteTime': instance.deleteTime,
  'isDel': instance.isDel,
  'account': instance.account,
  'nickname': instance.nickname,
  'avatar': instance.avatar,
  'isAdmin': instance.isAdmin,
  'departmentId': instance.departmentId,
  'status': instance.status,
  'tokenIssuedAt': instance.tokenIssuedAt,
  'interfaceDic': instance.interfaceDic,
  'rolesId': instance.rolesId,
  'rolesName': instance.rolesName,
  'operators': instance.operators,
};
