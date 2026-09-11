import 'package:json_annotation/json_annotation.dart';
import 'package:operation/ext/enums.dart';

part 'api_response.g.dart';

@JsonSerializable()
class LoginInfo {
  @JsonKey(name: "token")
  final String? token;
  @JsonKey(name: "user")
  final UserBean? user;

  LoginInfo({this.token, this.user});

  factory LoginInfo.fromJson(Map<String, dynamic> json) {
    return _$LoginInfoFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$LoginInfoToJson(this);
  }
}

@JsonSerializable()
class OperationDashboardVo {
  @JsonKey(name: "userName")
  final String? userName;
  /// 今日订单数（不含已取消与已全额退款）
  @JsonKey(name: "todayOrderCount")
  final int? todayOrderCount;
  /// 今日工单数（制作中 + 已完成）
  @JsonKey(name: "todayItemCount")
  final int? todayItemCount;
  /// 今日营业额（元，实收口径已扣除退款）= 其他支付收入 + 余额支付收入
  @JsonKey(name: "todayRevenue")
  final double? todayRevenue;
  /// 今日其他支付实收收入（元，除余额外的支付方式，当前为微信）
  @JsonKey(name: "todayOtherPayRevenue")
  final double? todayOtherPayRevenue;
  /// 今日用户余额支付实收收入（元）
  @JsonKey(name: "todayBalanceRevenue")
  final double? todayBalanceRevenue;
  @JsonKey(name: "onlineDeviceCount")
  final int? onlineDeviceCount;
  @JsonKey(name: "totalDeviceCount")
  final int? totalDeviceCount;
  @JsonKey(name: "inventoryAlertCount")
  final int? inventoryAlertCount;

  OperationDashboardVo({this.userName, this.todayOrderCount, this.todayItemCount, this.todayRevenue, this.todayOtherPayRevenue, this.todayBalanceRevenue, this.onlineDeviceCount, this.totalDeviceCount, this.inventoryAlertCount});

  factory OperationDashboardVo.fromJson(Map<String, dynamic> json) => _$OperationDashboardVoFromJson(json);

  Map<String, dynamic> toJson() => _$OperationDashboardVoToJson(this);
}

@JsonSerializable()
class OperationDeviceItemVo {
  @JsonKey(name: "id")
  final int? id;
  @JsonKey(name: "name")
  final String? name;
  @JsonKey(name: "deviceCode")
  final String? deviceCode;
  @JsonKey(name: "model")
  final String? model;
  @JsonKey(name: "onlineStatus", fromJson: onlineStatusFromJson, toJson: onlineStatusToJson)
  final OnlineStatus? onlineStatus;
  @JsonKey(name: "storeId")
  final int? storeId;
  @JsonKey(name: "storeName")
  final String? storeName;
  @JsonKey(name: "status")
  final bool? status;

  OperationDeviceItemVo({this.id, this.name, this.deviceCode, this.model, this.onlineStatus, this.storeId, this.storeName, this.status});

  factory OperationDeviceItemVo.fromJson(Map<String, dynamic> json) => _$OperationDeviceItemVoFromJson(json);

  Map<String, dynamic> toJson() => _$OperationDeviceItemVoToJson(this);
}

@JsonSerializable()
class OperationStoreVo {
  @JsonKey(name: "storeId")
  final int? storeId;
  @JsonKey(name: "storeName")
  final String? storeName;
  @JsonKey(name: "devices")
  final List<OperationDeviceItemVo>? devices;

  OperationStoreVo({this.storeId, this.storeName, this.devices});

  factory OperationStoreVo.fromJson(Map<String, dynamic> json) => _$OperationStoreVoFromJson(json);

  Map<String, dynamic> toJson() => _$OperationStoreVoToJson(this);
}

@JsonSerializable()
class OperationOperatorVo {
  @JsonKey(name: "operatorId")
  final int? operatorId;
  @JsonKey(name: "operatorName")
  final String? operatorName;
  @JsonKey(name: "stores")
  final List<OperationStoreVo>? stores;

  OperationOperatorVo({this.operatorId, this.operatorName, this.stores});

  factory OperationOperatorVo.fromJson(Map<String, dynamic> json) => _$OperationOperatorVoFromJson(json);

  Map<String, dynamic> toJson() => _$OperationOperatorVoToJson(this);
}

@JsonSerializable()
class MqttInfoVo {
  @JsonKey(name: "userName")
  final String? userName;
  @JsonKey(name: "password")
  final String? password;
  @JsonKey(name: "clientId")
  final String? clientId;
  @JsonKey(name: "groupId")
  final String? groupId;
  @JsonKey(name: "expirationTime")
  final int? expirationTime;

  MqttInfoVo({this.userName, this.password, this.clientId, this.groupId, this.expirationTime});

  factory MqttInfoVo.fromJson(Map<String, dynamic> json) => _$MqttInfoVoFromJson(json);

  Map<String, dynamic> toJson() => _$MqttInfoVoToJson(this);
}

@JsonSerializable()
class UserBean {
  @JsonKey(name: "id")
  final int? id;
  @JsonKey(name: "createTime")
  final int? createTime;
  @JsonKey(name: "updateTime")
  final int? updateTime;
  @JsonKey(name: "deleteTime")
  final dynamic? deleteTime;
  @JsonKey(name: "isDel")
  final bool? isDel;
  @JsonKey(name: "account")
  final String? account;
  @JsonKey(name: "nickname")
  final String? nickname;
  @JsonKey(name: "avatar")
  final dynamic? avatar;
  @JsonKey(name: "isAdmin")
  final bool? isAdmin;
  @JsonKey(name: "departmentId")
  final dynamic? departmentId;
  @JsonKey(name: "status")
  final bool? status;
  @JsonKey(name: "tokenIssuedAt")
  final int? tokenIssuedAt;
  @JsonKey(name: "interfaceDic")
  final List<dynamic>? interfaceDic;
  @JsonKey(name: "rolesId")
  final List<int>? rolesId;
  @JsonKey(name: "rolesName")
  final List<dynamic>? rolesName;
  @JsonKey(name: "operators")
  final List<dynamic>? operators;

  UserBean({this.id, this.createTime, this.updateTime, this.deleteTime, this.isDel, this.account, this.nickname, this.avatar, this.isAdmin, this.departmentId, this.status, this.tokenIssuedAt, this.interfaceDic, this.rolesId, this.rolesName, this.operators});

  factory UserBean.fromJson(Map<String, dynamic> json) {
    return _$UserBeanFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$UserBeanToJson(this);
  }
}
