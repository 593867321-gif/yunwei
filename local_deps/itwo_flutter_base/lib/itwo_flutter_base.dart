// 功能替代实现：itwo_flutter_base
//
// 背景：原包位于私有 Codeup 仓库（组织 647843c4...），本机账号无权限（HTTP 403），
// 且该库在可达组织下无任何同名/变体路径。为使项目可构建出「能正常运行」的测试包，
// 依据项目内 195 处真实调用点反推契约，实现行为等价的替代版本。
//
// 与「签名桩」的区别：签名桩只让编译通过、运行必然失败（如 md5Encode 原样返回明文，
// 而后端用 BCrypt 校验 MD5 串，登录必失败）。本实现要求每个 API 行为正确。
//
// 覆盖的 16 个符号：StreamData / streamData / IBaseStreamBloc / streamDispose /
// jobIO / trySingle / JobConfig / ConcurrencyManager / Config / CacheUtil /
// EncryptUtil / RouterUtil / MaterialPageRouteLifecycle / onClickRelease /
// String 扩展(log/toast/isNullOrEmpty) / DateTime.format
//
// 未在本实现范围内（itwo_flutter_net 提供）：DioLogInterceptor

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 条件导入：IO 平台写文件，web 平台空实现。
// 这样本库在 Android/iOS/桌面/web 全平台均可编译，且 log() 无需 dynamic 调用。
import 'src/log_writer_stub.dart' if (dart.library.io) 'src/log_writer_io.dart';

// ===========================================================================
// 响应式状态容器
// ===========================================================================

/// 单值响应式容器：写入 [value] 即向订阅者推流。
///
/// 关键步骤：必须用 broadcast StreamController 真实推流。若返回 Stream.value()，
/// StreamBuilder 订阅后收不到后续更新，页面状态将永远停在初始值（库存修改、
/// 设备列表筛选等交互全部失效）。
class StreamData<T> {
  StreamData();

  final StreamController<T?> _controller = StreamController<T?>.broadcast();

  T? _value;

  /// 当前值，未写入过时为 null
  T? get value => _value;

  /// 写入并推送新值给所有订阅者
  set value(T? v) {
    _value = v;
    if (!_controller.isClosed) _controller.add(v);
  }

  /// 订阅流。新订阅者会立即收到一次当前值（模拟 BehaviorSubject 语义），
  /// 保证 StreamBuilder 首帧即有数据，不依赖 initialData。
  Stream<T?> get stream async* {
    yield _value;
    yield* _controller.stream;
  }

  /// 释放资源
  void dispose() {
    if (!_controller.isClosed) _controller.close();
  }
}

/// 把任意值包装为 [StreamData]，初始值即该值。
extension StreamDataExt<T> on T {
  StreamData<T> get streamData => StreamData<T>()..value = this;
}

/// 混入型接口：持有 StreamData 的状态类需实现 [streamDispose] 释放全部流。
mixin IBaseStreamBloc {
  void streamDispose() {}
}

// ===========================================================================
// 全局配置
// ===========================================================================

/// 全局钩子配置。toast 由宿主注入（本项目注入 Fluttertoast）。
class Config {
  Config._();

  /// toast 回调，未注入时静默丢弃
  static void Function(String message)? toast;

  /// 日志输出文件，宿主用 createFile() 注入
  static dynamic logFile;
}

/// 异步任务错误信息解析器配置
class JobConfig {
  JobConfig._();

  static String? Function(dynamic error)? _parser;

  /// 注册自定义解析器，返回 null 时回退到 error.toString()
  static void setParser(String? Function(dynamic error) parser) {
    _parser = parser;
  }

  /// 解析错误为可读文案
  static String? parse(dynamic error) => _parser?.call(error);
}

// ===========================================================================
// 并发控制
// ===========================================================================

/// 并发任务数限制。宿主设置 maxCount 后，超出的 jobIO 排队等待。
class ConcurrencyManager {
  ConcurrencyManager._();

  static final ConcurrencyManager instance = ConcurrencyManager._();

  int _maxCount = 5;
  final List<void Function()> _waiters = [];
  int _running = 0;

  /// 最大并发数
  int get maxCount => _maxCount;

  set maxCount(int v) {
    _maxCount = v < 1 ? 1 : v;
    _drain();
  }

  /// 取得一个执行名额，达上限时挂起等待
  Future<void> acquire() async {
    if (_running < _maxCount) {
      _running++;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(() {
      _running++;
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  /// 释放一个名额并唤醒等待者
  void release() {
    _running--;
    if (_running < 0) _running = 0;
    _drain();
  }

  void _drain() {
    while (_running < _maxCount && _waiters.isNotEmpty) {
      final next = _waiters.removeAt(0);
      next();
    }
  }
}

// ===========================================================================
// 异步任务助手
// ===========================================================================

/// 执行 [task]，统一处理 loading、错误提示与并发限制（「重」封装）。
///
/// 与 [trySingle]（「轻」封装：无 loading、无 toast）的区别，依据项目调用惯例推定：
/// 十余处 jobIO 调用点均未自行 EasyLoading.show()，却都在 onFinally 里 dismiss()，
/// 而 trySingle 调用点（page_stock.dart 提交库存）则手动 show(status:)，
/// 且其注释明确写着「trySingle 轻量错误处理」。故 jobIO 自带 loading。
///
/// - [onError]：异常回调，返回 true 表示已自行处理、不再 toast
/// - [onFinally]：无论成败都执行（宿主在此关闭下拉刷新等）
/// - [toastEnable]：异常时是否弹出错误提示
///
/// 关键步骤：EasyLoading.show()/dismiss() 是 async 函数，未初始化时（宿主未挂载
/// EasyLoading.init、或单元测试环境）会在「异步阶段」抛 AssertionError。
/// 因此必须 await 后再 catch —— 仅用同步 try/catch 包不住，异常会逃逸到 Zone
/// 变成未处理错误。加载动画属纯展示，绝不能因它失败而中断业务或吞掉真实错误。
Future<dynamic> jobIO(Future<dynamic> Function() task, {bool Function(dynamic error)? onError, VoidCallback? onFinally, bool toastEnable = true}) async {
  await ConcurrencyManager.instance.acquire();
  try {
    await EasyLoading.show();
  } catch (_) {}
  try {
    return await task();
  } catch (e) {
    // 优先用注册的解析器转可读文案，否则回退 toString
    final msg = JobConfig.parse(e) ?? e.toString();
    final handled = onError?.call(e) ?? false;
    if (!handled && toastEnable) {
      Config.toast?.call(msg);
    }
    return null;
  } finally {
    try {
      await EasyLoading.dismiss();
    } catch (_) {}
    // 名额必须在 onFinally 之前释放，否则回调里再发起 jobIO 会永久排队
    ConcurrencyManager.instance.release();
    onFinally?.call();
  }
}

/// 执行一次 [task]，吞掉全部异常返回 null（「轻」封装：不显示 loading、不弹 toast）。
/// 用于不需要界面反馈的轻量调用；宿主如需 loading 自行 EasyLoading.show(status:)。
///
/// 关键步骤：必须用泛型 [T] 保留 task 的返回类型，禁止写成 Future<dynamic>。
/// 原因：宿主代码会在返回值上直接调用扩展方法（如 page_home.dart 扫码分支的
/// `result.isNullOrEmpty`）。扩展方法是静态解析的，若静态类型为 dynamic，
/// Dart 会改成实例方法查找，运行时抛 NoSuchMethodError；而该异常发生在无人
/// await 的 async 回调里会被静默吞掉，表现为「后续代码（含弹窗）整段不执行」。
Future<T?> trySingle<T>(Future<T?> Function() task) async {
  try {
    return await task();
  } catch (_) {
    return null;
  }
}

// ===========================================================================
// 本地键值缓存
// ===========================================================================

/// 键值缓存。基于 shared_preferences 真实持久化。
///
/// 关键步骤：必须真持久化。若用内存 Map，APP 重启后 token 丢失、
/// 登录态无法保持，每次启动都被踢回登录页。
class CacheUtil {
  CacheUtil._();

  static SharedPreferences? _prefs;

  /// 预热实例，避免并发 get 时重复初始化
  static Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  /// 写入值（自动 JSON 序列化非基础类型）
  static Future<void> put(String key, dynamic value) async {
    final p = await _instance();
    if (value == null) {
      await p.remove(key);
    } else if (value is String) {
      await p.setString(key, value);
    } else if (value is bool) {
      await p.setBool(key, value);
    } else if (value is int) {
      await p.setInt(key, value);
    } else if (value is double) {
      await p.setDouble(key, value);
    } else {
      await p.setString(key, json.encode(value));
    }
  }

  /// 读取值，不存在时返回 null
  static Future<dynamic> get(String key) async {
    final p = await _instance();
    return p.get(key);
  }

  /// 删除键，返回是否成功
  static Future<bool> remove(String key) async {
    final p = await _instance();
    return p.remove(key);
  }
}

// ===========================================================================
// 加密
// ===========================================================================

/// 加密工具。
class EncryptUtil {
  EncryptUtil._();

  /// 标准 MD5，输出 32 位小写十六进制。
  ///
  /// 关键步骤：必须是真 MD5，不能原样返回。后端 AuthService 用
  /// BCryptPasswordEncoder.matches(rawPassword, hash) 校验，而入库时
  /// encrypt 的输入正是前端传来的 MD5 串，故此处返回明文必然登录失败。
  static String md5Encode(String input) => md5.convert(utf8.encode(input)).toString();
}

// ===========================================================================
// 路由
// ===========================================================================

/// 全局路由助手：提供 navigatorKey 与路由观察者。
class RouterUtil extends NavigatorObserver {
  RouterUtil._();

  static final RouterUtil instance = RouterUtil._();

  /// 全局导航键，宿主注入 MaterialApp.navigatorKey
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 以 [home] 作为首页构建路由入口
  static Widget initRouter(Widget home) => home;

  /// 清空路由栈（退出登录时用）
  static void clear() {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}

/// 带生命周期感知的路由。等价于 MaterialPageRoute。
///
/// 关键步骤：泛型上界必须写 `T extends Object?`。调用方普遍省略类型参数，
/// 若上界缺省 Dart 会推断为 dynamic，而 Navigator.push 要求 `Route<Object?>`，
/// `Route<dynamic>` 无法赋值，会报 argument_type_not_assignable。
class MaterialPageRouteLifecycle<T extends Object?> extends MaterialPageRoute<T> {
  MaterialPageRouteLifecycle({required super.builder, super.settings, super.maintainState, super.fullscreenDialog});
}

// ===========================================================================
// Widget 扩展
// ===========================================================================

/// 给任意 Widget 附加点击回调并返回自身，便于链式书写。
extension WidgetClickReleaseExt on Widget {
  Widget onClickRelease(VoidCallback onTap) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: this);
}

// ===========================================================================
// String / DateTime 扩展
// ===========================================================================

extension NullableStringExt on String? {
  /// 是否为 null 或空串
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// 输出日志：控制台 + 宿主注入的日志文件
  void log() {
    final line = '[${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}] ${this ?? ""}';
    debugPrint(line);
    // 写入由平台实现负责（IO 写文件 / web 忽略），内部已吞异常，不影响业务流程
    appendLogLine(Config.logFile, line);
  }

  /// 弹出轻提示
  void toast() {
    final s = this;
    if (s == null || s.isEmpty) return;
    Config.toast?.call(s);
  }
}

extension DateTimeFormatExt on DateTime {
  /// 按模式格式化。项目实际仅用到 "yyyy-MM-dd" 与 "yyyy-MM-dd HH:mm:ss"，
  /// 二者均为 intl.DateFormat 的标准语法，直接委托即可。
  String format(String pattern) => DateFormat(pattern).format(this);
}
