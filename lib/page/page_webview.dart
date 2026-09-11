import 'package:flutter/material.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 通用 WebView 页面
///
/// 以 AppBar + 全屏 WebView 展示指定 URL。
/// [onPageFinished] 回调在页面加载完成时被调用，
/// 可用于执行 `runJavaScript` 注入数据。
class PageWebView extends StatefulWidget {
  final String title;
  final String url;
  final void Function(WebViewController controller)? onPageFinished;

  const PageWebView({
    super.key,
    required this.title,
    required this.url,
    this.onPageFinished,
  });

  static void actionStart({
    required String title,
    required String url,
    void Function(WebViewController controller)? onPageFinished,
  }) {
    RouterUtil.navigatorKey.currentState?.push(
      MaterialPageRouteLifecycle(
        builder: (_) => PageWebView(
          title: title,
          url: url,
          onPageFinished: onPageFinished,
        ),
      ),
    );
  }

  @override
  State<PageWebView> createState() => _PageWebViewState();
}

class _PageWebViewState extends State<PageWebView> {
  WebViewController? _controller;
  bool _pageLoaded = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!_pageLoaded) {
              _pageLoaded = true;
              widget.onPageFinished?.call(_controller!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(child: WebViewWidget(controller: _controller!)),
    );
  }
}
