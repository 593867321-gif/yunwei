// 子入口：itwo_flutter_base/itwo_base_config.dart
//
// 刻意保持为空、不导出任何符号。
// lib/main.dart 同时导入本子库与主库 itwo_flutter_base.dart，
// 若此处转导出主库，Config / JobConfig / ConcurrencyManager / RouterUtil
// 会同时从两个库可见，触发 ambiguous_import 编译错误。配置符号统一由主库提供。
