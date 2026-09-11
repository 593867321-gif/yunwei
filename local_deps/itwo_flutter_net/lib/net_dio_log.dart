// 功能替代实现：itwo_flutter_net
//
// 项目内仅 lib/net/request_server.dart 使用本库的 DioLogInterceptor，
// 用于在 Dio 拦截器链中打印请求/响应日志。
//
// 关键步骤：只定义 DioLogInterceptor，不导出其它符号。request_server.dart 同时
// 导入 itwo_flutter_base 主库，若此处再导出同名符号会造成歧义导入。

import 'package:dio/dio.dart';

/// Dio 日志拦截器：打印请求与响应的关键信息，便于排查接口问题。
/// 仅做日志输出，不改变请求或响应内容。
class DioLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('[HTTP -->] ${options.method} ${options.uri}');
    final body = options.data;
    if (body != null) {
      // ignore: avoid_print
      print('[HTTP -->] body: $body');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('[HTTP <--] ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('[HTTP !!] ${err.type} ${err.requestOptions.uri} -> ${err.message}');
    handler.next(err);
  }
}
