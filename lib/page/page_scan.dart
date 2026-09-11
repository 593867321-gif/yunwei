import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:itwo_flutter_base/route/itwo_flutter_route.dart';
import 'package:operation/ext/app_keys.dart';

import '../widget/widget_scanner_overlay.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  static Future<String?> actionStart() async {
    return RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(builder: (context) => ScannerPage()));
  }

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  // 关键：哨兵变量，防止多次 pop
  bool _isFinished = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 背景设为黑色防止相机加载前的闪白
      backgroundColor: Colors.black,
      // 让相机预览延伸到 AppBar 下方
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "扫一扫",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          key: AppKeys.scanBackButton,
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 预留位置，如果以后想加切换手电筒可以在这里加控制逻辑
          const SizedBox(width: 48),
        ],
      ),
      body: CommonScannerWidget(
        onDetect: (code) {
          if (_isFinished) return; // 如果已经扫码成功正在退出，则拦截后续回调
          _isFinished = true;
          // 逻辑处理：识别到二维码后立即震动并返回
          HapticFeedback.mediumImpact(); // 需要导入 services.dart
          Navigator.pop(context, code);
        },
      ),
    );
  }
}
