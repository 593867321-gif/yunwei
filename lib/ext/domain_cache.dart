import 'package:operation/widget/widget_device_drawer.dart';

/// 全局管理域缓存单例
/// 记录用户最近一次选择的管理域（运营商/店铺/设备），供跨页面共享
/// 使用方式类似 LoginCache，静态方法直接调用，无需实例化
class DomainCache {
  DomainCache._();

  /// 当前全局选中的管理域
  static DeviceSelection? _current;

  /// 获取当前选中的管理域，无选择时返回 null
  static DeviceSelection? get current => _current;

  /// 更新全局管理域，首页或任意页面的抽屉选择后调用
  static void update(DeviceSelection selection) {
    _current = selection;
  }

  /// 清除管理域选择
  static void clear() {
    _current = null;
  }

  /// 当前是否为设备级别选择（deviceId 非空）
  static bool get hasDevice => _current?.deviceId != null;
}
