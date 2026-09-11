import 'package:aliyun_push/aliyun_push.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/Const.dart';
import 'package:operation/ext/push_event_type.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/api_request.dart';
import 'package:operation/net/request_server.dart';
import 'package:operation/page/page_alert.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// 阿里云推送服务
///
/// 职责：
/// - 初始化阿里云推送 SDK 并获取 deviceId
/// - 登录成功后向服务端注册推送 token
/// - 退出登录 / token 失效时注销 token
/// - 通知点击后根据 eventType 跳转对应页面
///
/// Token 获取方式：
/// - 当前使用 `getDeviceId()` 作为推送 token（阿里云 SDK 不支持 onRegister 回调）
/// - SDK 初始化成功后，通过 `getDeviceId()` 获取设备唯一标识作为 pushToken
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final AliyunPush _aliyunPush = AliyunPush();

  /// deviceId（初始化完成后赋值）
  String? _pushToken;

  static const String _deviceIdCacheKey = 'local_device_id';
  String? _localDeviceId;

  /// init 异步任务引用，register/unregister 需要等待初始化完成
  Future<void>? _initFuture;

  String? get pushToken => _pushToken;

  /// 初始化推送 SDK，等待 _doInit 完成后返回
  Future<void> init() async {
    _initFuture = _doInit();
    await _initFuture;
  }

  /// 实际初始化流程：请求通知权限 → 初始化 SDK → 获取 deviceId → 注册点击回调
  Future<void> _doInit() async {
    if (kIsWeb) return;

    // 请求通知权限（Android 13+ 和 iOS 需要用户授权）
    await _requestNotificationPermission();

    // appKey/appSecret 通过 --dart-define-from-file 注入，空值时使用 SDK 默认配置
    const appKey = String.fromEnvironment('PUSH_APP_KEY');
    const appSecret = String.fromEnvironment('PUSH_APP_SECRET');
    final result = await _aliyunPush.initPush(
      appKey: appKey.isNotEmpty ? appKey : null,
      appSecret: appSecret.isNotEmpty ? appSecret : null,
    );
    if (result['code'] == kAliyunPushSuccessCode) {
      _pushToken = await _aliyunPush.getDeviceId();
      '推送初始化成功, deviceId: $_pushToken'.log();

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          _aliyunPush.setIOSForegroundNoticeMode(ForegroundNoticeMode.showAndCallback);
          final pushChannel = MethodChannel('aliyun_push');
          final delegate = await pushChannel
              .invokeMethod<String>('getNotificationCenterDelegate');
          'UNUserNotificationCenter delegate: $delegate'.log();
          final isRegistered = await pushChannel
              .invokeMethod<bool>('isRegisteredForRemoteNotifications');
          'isRegisteredForRemoteNotifications: $isRegistered'.log();
        } catch (e) {
          '查询推送状态失败: $e'.log();
        }
      }
    } else {
      '推送初始化失败, code: ${result['code']}, errorMsg: ${result['errorMsg']}'.log();
    }
    // 注意：阿里云推送 SDK 不支持 onRegister 回调，无法通过回调获取 token
    // 当前使用 getDeviceId() 作为推送 token（见第55行）
    _aliyunPush.addMessageReceiver(
      onNotification: (msg) async {
        'onNotification: 收到推送 $msg'.log();
        return null;
      },
      onMessage: (msg) async {
        'onMessage: 收到消息 $msg'.log();
        return null;
      },
      onNotificationOpened: _onNotificationOpened,
    );
  }

  /// 请求通知权限
  /// Android 13+ 和 iOS 需要显式请求通知权限
  /// 永久拒绝时引导用户前往系统设置开启
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      '通知权限请求结果: $result'.log();
    } else if (status.isPermanentlyDenied) {
      // 永久拒绝时，显示引导提示并跳转系统设置
      _showNotificationPermissionGuide();
    }
  }

  /// 显示通知权限引导，跳转系统设置
  void _showNotificationPermissionGuide() {
    // 使用 navigatorKey 获取当前 context
    final context = RouterUtil.navigatorKey.currentContext;
    if (context == null) return;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;

    // 显示 toast 提示
    l10n.pushNotificationPermissionDenied.toast();

    // 延迟后跳转系统设置
    Future.delayed(const Duration(seconds: 1), () {
      openAppSettings();
    });
  }

  /// 向服务端注册推送 token
  /// 需等待 init 完成后，token 和用户登录态均有效时执行
  /// 包含设备名称和应用版本信息
  Future<void> register() async {
    if (kIsWeb) return;
    await _initFuture;
    final token = _pushToken;
    if (token == null) {
      '推送注册跳过: pushToken 为 null'.log();
      return;
    }
    final user = await LoginCache.getUser();
    if (user == null) {
      '推送注册跳过: 用户未登录'.log();
      return;
    }
    try {
      _localDeviceId ??= await CacheUtil.get(_deviceIdCacheKey) as String?;
      _localDeviceId ??= const Uuid().v4();
      await CacheUtil.put(_deviceIdCacheKey, _localDeviceId!);

      final deviceName = await _getDeviceName();
      final appVersion = await _getAppVersion();
      await ApiServer.instance.pushRegister(PushRegisterRequestBody(
        platform: defaultTargetPlatform.name.toUpperCase(),
        deviceId: _localDeviceId!,
        pushToken: token,
        deviceName: deviceName,
        appVersion: appVersion,
      ));
    } catch (e) {
      '推送注册失败: $e'.log();
    }
  }

  /// 获取设备名称
  Future<String?> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      }
    } catch (e) {
      '获取设备信息失败: $e'.log();
    }
    return null;
  }

  /// 获取应用版本号
  Future<String?> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      '获取应用版本失败: $e'.log();
    }
    return null;
  }

  /// 向服务端注销推送 token
  Future<void> unregister() async {
    final token = _pushToken;
    if (kIsWeb || token == null) return;
    try {
      await ApiServer.instance.pushUnregister(PushUnregisterRequestBody(
        pushToken: token,
      ));
      _pushToken = null;
    } catch (e) {
      '推送注销失败: $e'.log();
    }
  }

  /// 通知点击回调，根据 eventType 和 alertId 跳转对应页面
  Future<dynamic> _onNotificationOpened(Map<dynamic, dynamic> message) async {
    'onNotificationOpened: 用户点击通知 $message'.log();
    final extras = message['extras'] as Map<dynamic, dynamic>?;
    final data = extras ?? message;
    final eventTypeStr = data['eventType'] as String?;
    final alertId = data['alertId'] as int?;

    // 使用枚举的 fromApiValue 方法解析
    final eventType = PushEventType.fromApiValue(eventTypeStr);
    if (eventType == null) return null;

    switch (eventType) {
      case PushEventType.faultAlert:
      case PushEventType.warningAlert:
      case PushEventType.stockOutAlert:
      case PushEventType.alertResolved:
        AlertPage.actionStart(alertId: alertId);
        break;
    }
    return null;
  }
}
