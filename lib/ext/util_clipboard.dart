import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

/// 剪贴板工具
class ClipboardUtil {
  /// 复制文本到剪贴板并提示
  static Future<void> copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    EasyLoading.showSuccess('已复制');
  }
}
