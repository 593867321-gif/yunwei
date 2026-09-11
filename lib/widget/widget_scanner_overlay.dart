import 'package:flutter/material.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// 扫描框遮罩组件：实现中间亮、四周暗的效果
class ScannerOverlay extends StatelessWidget {
  final Rect scanWindow;

  const ScannerOverlay({super.key, required this.scanWindow});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 半透明黑色背景
        ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.srcOut),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut),
              ),
              // 中间掏空的矩形
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: scanWindow.width,
                  height: scanWindow.height,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        // 白色边框线
        Align(
          alignment: Alignment.center,
          child: Container(
            width: scanWindow.width,
            height: scanWindow.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

/// 通用扫码 Widget
class CommonScannerWidget extends StatefulWidget {
  final Function(String code) onDetect;

  const CommonScannerWidget({super.key, required this.onDetect});

  @override
  State<CommonScannerWidget> createState() => _CommonScannerWidgetState();
}

class _CommonScannerWidgetState extends State<CommonScannerWidget> {
  late MobileScannerController controller;

  // 定义识别窗口（相对于屏幕中心）
  final Rect scanWindow = Rect.fromCenter(
    center: const Offset(0, 0), // 这里的 Offset 在 mobile_scanner 内部会自动处理居中
    width: 250,
    height: 250,
  );

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.qrCode], // 只识别二维码，提高速度
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          // scanWindow: scanWindow,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final String? code = barcodes.first.rawValue;
              if (code != null) {
                // 扫码成功，回调结果
                widget.onDetect(code);
              }
            }
          },
          onDetectError: (error, stackTrace) {
            "onDetectError $error $stackTrace".log();
          },
        ),
        // 叠加遮罩层
        ScannerOverlay(scanWindow: scanWindow),
      ],
    );
  }
}
