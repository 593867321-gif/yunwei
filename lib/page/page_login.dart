import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/Const.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/request_server.dart';
import 'package:operation/page/page_home.dart';

import '../net/api_request.dart';
import 'package:operation/ext/app_keys.dart';
import 'package:operation/services/push_service.dart';

/// author: wang   2026/4/18
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static void actionStart() {
    RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(builder: (context) => LoginPage()));
  }

  static void pushAndRemoveTo() {
    RouterUtil.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRouteLifecycle(builder: (context) => LoginPage()),
      (route) => false,
    );
  }

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _accountController = TextEditingController(text: "");
  final _passwordController = TextEditingController(text: "");

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const primaryContainer = Color(0xFF1E293B);
    const surface = Color(0xFFF7F9FB);
    const primary = Color(0xFF091426);
    const onTertiaryContainer = Color(0xFF8291A6);

    return Scaffold(
      backgroundColor: primaryContainer,
      body: Stack(children: [
        Positioned(top: -40, right: -40, child: _GlowSpotWidget(color: onTertiaryContainer.withValues(alpha: 0.2), size: 192)),
        Positioned(top: 200, left: -40, child: _GlowSpotWidget(color: onTertiaryContainer.withValues(alpha: 0.2), size: 192)),
        Column(children: [
          Container(
            padding: const EdgeInsets.only(top: 80, bottom: 60),
            width: double.infinity,
            child: Column(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.terminal, color: primary, size: 30)),
              const SizedBox(height: 40),
              const Text('OP Manager', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 4)),
              const SizedBox(height: 12),
              Text(l10n.loginWelcomeBack, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              Text(l10n.loginPleaseSignIn, style: const TextStyle(color: Color(0xFF8590A6), fontSize: 18, fontWeight: FontWeight.w500)),
            ]),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: surface, borderRadius: BorderRadius.vertical(top: Radius.circular(40)), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -10))]),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _LoginInputField(inputKey: AppKeys.loginAccountInput, label: l10n.loginAccountLabel, hint: l10n.loginAccountHint, icon: Icons.person, controller: _accountController),
                  const SizedBox(height: 24),
                  _LoginInputField(inputKey: AppKeys.loginPasswordInput, label: l10n.loginPasswordLabel, hint: l10n.loginPasswordHint, icon: Icons.lock, isPassword: true, controller: _passwordController),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [primary, primaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: primary.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: InkWell(
                      key: AppKeys.loginButton,
                      onTap: _commit,
                      borderRadius: BorderRadius.circular(16),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(l10n.loginButton, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  void _commit() => jobIO(() async {
        final l10n = AppLocalizations.of(context);
        final account = _accountController.text;
        final password = _passwordController.text;
        if (account.isEmpty || password.isEmpty) {
          l10n.loginErrorEmpty.toast();
          return;
        }
        EasyLoading.show();
        var md5encode = EncryptUtil.md5Encode(password);
        var request = LoginRequest(account: account, password: md5encode);
        var response = await ApiServer.instance.login(request);
        var info = response?.take();
        var token = info?.token;
        if (info == null || token.isNullOrEmpty == true) {
          l10n.loginErrorFailed.toast();
          return;
        }
        await LoginCache.putToken(token ?? "");
        final user = info.user;
        if (user != null) {
          await LoginCache.putUser(user);
        }
        PushService.instance.register();
        HomePage.pushReplacement();
      }, onFinally: () => EasyLoading.dismiss(), toastEnable: true);
}

/// 登录页输入框组件
class _LoginInputField extends StatelessWidget {
  /// 输入框 Key
  final Key? inputKey;
  /// 输入框标签
  final String label;
  /// 输入框占位文本
  final String hint;
  /// 输入框图标
  final IconData icon;
  /// 是否为密码输入
  final bool isPassword;
  /// 文本控制器
  final TextEditingController controller;

  const _LoginInputField({this.inputKey, required this.label, required this.hint, required this.icon, this.isPassword = false, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF45474C)))),
      TextField(
        key: inputKey,
        obscureText: isPassword,
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF75777D)),
          filled: true,
          fillColor: const Color(0xFFF2F4F6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
      ),
    ]);
  }
}

/// 背景光晕装饰
class _GlowSpotWidget extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowSpotWidget({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withValues(alpha: 80 / 255), color.withValues(alpha: 10 / 255), Colors.transparent], stops: const [0.0, 0.5, 1.0])),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), child: Container(color: Colors.transparent)),
    );
  }
}
