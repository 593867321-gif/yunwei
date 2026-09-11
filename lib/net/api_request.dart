class LoginRequest {
  String? account;
  String? password;

  LoginRequest({this.account, this.password});

  factory LoginRequest.fromJson(Map<String, dynamic> json) => LoginRequest(account: json["account"], password: json["password"]);

  Map<String, dynamic> toJson() => {"account": account, "password": password};
}

/// 时间范围，对应后端 InstantRange
class InstantRange {
  final int? start;
  final int? end;

  InstantRange({this.start, this.end});

  factory InstantRange.fromJson(Map<String, dynamic> json) => InstantRange(start: json["start"] as int?, end: json["end"] as int?);

  Map<String, dynamic> toJson() => {"start": start, "end": end};
}

/// 工作台数据看板请求体，dateRange 为 null 表示查询今日数据
class DashboardRequestBody {
  final InstantRange? dateRange;
  final int? operatorId;
  final int? storeId;
  final int? deviceId;

  DashboardRequestBody({this.dateRange, this.operatorId, this.storeId, this.deviceId});

  factory DashboardRequestBody.fromJson(Map<String, dynamic> json) => DashboardRequestBody(dateRange: json["dateRange"] != null ? InstantRange.fromJson(json["dateRange"]) : null, operatorId: json["operatorId"] as int?, storeId: json["storeId"] as int?, deviceId: json["deviceId"] as int?);

  Map<String, dynamic> toJson() => {"dateRange": dateRange?.toJson(), "operatorId": operatorId, "storeId": storeId, "deviceId": deviceId};
}

/// 设备实时状态查询请求体，对应后端 OperationDeviceStatusRequestBody
class OperationDeviceStatusRequestBody {
  /// 设备名称/编号/型号模糊查询关键字，为 null 表示不过滤
  final String? keyword;

  OperationDeviceStatusRequestBody({this.keyword});

  factory OperationDeviceStatusRequestBody.fromJson(Map<String, dynamic> json) => OperationDeviceStatusRequestBody(keyword: json["keyword"] as String?);

  Map<String, dynamic> toJson() => {"keyword": keyword};
}

/// 推送 Token 注册请求体
class PushRegisterRequestBody {
  final String platform;
  final String deviceId;
  final String pushToken;
  final String? deviceName;
  final String? appVersion;

  PushRegisterRequestBody({required this.platform, required this.deviceId, required this.pushToken, this.deviceName, this.appVersion});

  Map<String, dynamic> toJson() => {
    "platform": platform,
    "deviceId": deviceId,
    "pushToken": pushToken,
    if (deviceName != null) "deviceName": deviceName,
    if (appVersion != null) "appVersion": appVersion,
  };
}

/// 推送 Token 注销请求体
class PushUnregisterRequestBody {
  final String pushToken;

  PushUnregisterRequestBody({required this.pushToken});

  Map<String, dynamic> toJson() => {"pushToken": pushToken};
}
