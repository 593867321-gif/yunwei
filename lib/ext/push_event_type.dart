/// 推送事件类型枚举
///
/// 用于通知点击后根据 eventType 跳转对应页面
enum PushEventType {
  /// 设备故障告警
  faultAlert('fault_alert', '故障告警'),

  /// 设备预警
  warningAlert('warning_alert', '设备预警'),

  /// 缺货预警
  stockOutAlert('stock_out_alert', '缺货预警'),

  /// 告警已消除
  alertResolved('alert_resolved', '告警已恢复');

  /// 构造函数
  const PushEventType(this.apiValue, this.label);

  /// API 返回的字符串值
  final String apiValue;

  /// 中文显示名
  final String label;

  /// 从 API 字符串值解析枚举
  ///
  /// [value] API 返回的字符串值
  /// @return 对应的枚举值，未找到时返回 null
  static PushEventType? fromApiValue(String? value) {
    if (value == null) return null;
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}
