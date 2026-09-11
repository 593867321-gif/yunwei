import 'dart:convert';
import 'dart:ui';

import 'package:itwo_flutter_base/util/util.dart';

import '../net/api_response.dart';

class Env {
  Env._();

  static const ENV = String.fromEnvironment("ENV", defaultValue: 'release');
  static const ROOT_URL = String.fromEnvironment("API_HOST", defaultValue: 'https://youdake.cn/team/');
}

class MyColors {
  MyColors._();

  static const Color BACK_GROUND = Color(0xFFF8FAFC);
  static const Color PRIMARY_COLOR = Color(0xFF1E293B);
}

class Const {
  Const._();
}

class LoginCache {
  LoginCache._();

  static const _cacheKeyUserInfo = "CACHE_KEY_USER_INFO";
  static const _cacheKeyToken = "CACHE_KEY_TOKEN";

  static String? _memToken;
  static UserBean? _memUser;

  static Future<bool> isLogin() async {
    var s = await getToken();
    return s != null && s.isNotEmpty;
  }

  /// 缓存用户信息（登录成功后调用）
  static Future<void> putUser(UserBean user) async {
    _memUser = user;
    CacheUtil.put(_cacheKeyUserInfo, json.encode(user.toJson()));
  }

  /// 获取缓存的用户信息
  static Future<UserBean?> getUser() async {
    if (_memUser != null) return _memUser;
    var cache = (await CacheUtil.get(_cacheKeyUserInfo)) as String?;
    if (cache.isNullOrEmpty) return null;
    try {
      _memUser = UserBean.fromJson(json.decode(cache ?? ""));
      return _memUser;
    } catch (_) {
      return null;
    }
  }

  /// 获取当前用户 ID
  static Future<int?> getUserId() async {
    var user = await getUser();
    return user?.id;
  }

  static Future<void> putToken(String token) async {
    _memToken = token;
    CacheUtil.put(_cacheKeyToken, token);
  }

  static Future<String?> getToken() async {
    if (_memToken.isNullOrEmpty != true) {
      return _memToken;
    }
    var cache = (await CacheUtil.get(_cacheKeyToken)) as String?;
    if (cache.isNullOrEmpty) return null;
    _memToken = cache;
    return cache;
  }

  /// 清除所有缓存（退出登录）
  static Future<void> removeAll() async {
    _memToken = null;
    _memUser = null;
    await CacheUtil.remove(_cacheKeyToken);
    await CacheUtil.remove(_cacheKeyUserInfo);
  }

  static Future<bool> removeToken() async {
    _memToken = null;
    return CacheUtil.remove(_cacheKeyToken);
  }
}
