// IO 平台实现：把日志行追加写入宿主提供的 File 对象。
// 仅在 dart:io 可用的平台（Android/iOS/桌面）被条件导入。
import 'dart:io';

/// 追加一行日志到 [file]。写入失败不得抛出，避免影响业务流程。
void appendLogLine(dynamic file, String line) {
  if (file is! File) return;
  try {
    file.writeAsStringSync('$line\n', mode: FileMode.append, flush: false);
  } catch (_) {}
}
