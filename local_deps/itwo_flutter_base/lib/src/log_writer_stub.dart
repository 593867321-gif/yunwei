// Web 平台占位实现：web 无 dart:io，日志仅输出到控制台，不写文件。
// 宿主在 web 下本就不会设置 Config.logFile（main.dart 有 kIsWeb 守卫）。

/// Web 下不写文件，静默忽略。
void appendLogLine(dynamic file, String line) {}
