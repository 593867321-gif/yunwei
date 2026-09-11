import 'dart:convert';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/enums.dart';

/// MQTT alertNotify 消息解析 Bean
class MqttAlertBean {
  /// 告警ID
  final int? alertId;
  /// 设备ID
  final int? deviceId;
  /// 设备编码
  final String? deviceCode;
  /// 设备名称
  final String? deviceName;
  /// 告警类型
  final AlertTypeEnum? alertType;
  /// 告警状态
  final AlertStatusEnum? alertStatus;
  /// 故障/告警码
  final String? errorCode;
  /// 故障/告警描述
  final String? errorDescription;
  /// 严重程度
  final int? severity;
  /// 时间戳（毫秒）
  final int? timestamp;

  MqttAlertBean({
    this.alertId,
    this.deviceId,
    this.deviceCode,
    this.deviceName,
    this.alertType,
    this.alertStatus,
    this.errorCode,
    this.errorDescription,
    this.severity,
    this.timestamp,
  });

  /// 从 JSON Map 构建
  factory MqttAlertBean.fromJson(Map<String, dynamic> json) {
    return MqttAlertBean(
      alertId: json['alertId'] as int?,
      deviceId: json['deviceId'] as int?,
      deviceCode: json['deviceCode'] as String?,
      deviceName: json['deviceName'] as String?,
      alertType: AlertTypeEnum.fromApiValue(json['alertType'] as String?),
      alertStatus: AlertStatusEnum.fromApiValue(json['alertStatus'] as String?),
      errorCode: json['errorCode'] as String?,
      errorDescription: json['errorDescription'] as String?,
      severity: json['severity'] as int?,
      timestamp: json['timestamp'] as int?,
    );
  }
}

/// MQTT 告警消息处理器
/// 解析 alertNotify action 的 payload 并分发给订阅者
class MqttAlertHandler {
  static final MqttAlertHandler instance = MqttAlertHandler._();
  MqttAlertHandler._();

  final List<void Function(MqttAlertBean bean)> _listeners = [];

  /// 注册告警监听器
  void addListener(void Function(MqttAlertBean bean) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// 移除告警监听器
  void removeListener(void Function(MqttAlertBean bean) listener) {
    _listeners.remove(listener);
  }

  /// 处理原始 topic 和 payload
  void handleMessage(String topic, String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return;
      final action = json['action'] as String?;
      if (action != 'alertNotify') return;
      final bean = MqttAlertBean.fromJson(json);
      _notifyListeners(bean);
    } catch (e) {
      "MQTT 告警消息解析失败: $e".log();
    }
  }

  void _notifyListeners(MqttAlertBean bean) {
    for (final listener in _listeners) {
      try {
        listener(bean);
      } catch (e) {
        "告警回调执行失败: $e".log();
      }
    }
  }

  /// 清理所有监听器
  void dispose() {
    _listeners.clear();
  }
}
