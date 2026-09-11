// 子入口：itwo_flutter_base/util/util.dart
//
// lib/ext/Const.dart 只导入本子库（不导入主库），需要从这里拿到 CacheUtil 与
// String.isNullOrEmpty，因此转导出主库。
//
// 不会造成歧义：全项目仅 Const.dart 导入本路径，且它不同时导入主库。
export '../itwo_flutter_base.dart';
