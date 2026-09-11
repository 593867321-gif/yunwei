import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:itwo_flutter_net/net_dio_log.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:operation/ext/Const.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/api_alert.dart';
import 'package:operation/net/api_device.dart';
import 'package:operation/net/api_device_detail.dart';
import 'package:operation/net/api_order.dart';
import 'package:operation/net/api_request.dart';
import 'package:operation/net/api_stock.dart';
import 'package:operation/net/api_stock_record.dart';
import 'package:operation/page/page_login.dart';
import 'package:operation/services/push_service.dart';
import 'package:retrofit/retrofit.dart';

import 'api_response.dart';

part 'request_server.g.dart';

class ApiServer {
  static RequestServer get instance => _getInstance();
  static RequestServer? _instance;

  ApiServer._internal();

  static Dio? _dio;

  static Dio get dio {
    _dio ??= Dio(BaseOptions(baseUrl: Env.ROOT_URL, connectTimeout: const Duration(seconds: 30), receiveTimeout: const Duration(seconds: 30)))..interceptors.addAll([_HeaderInterceptor(), DioLogInterceptor(), _AuthInterceptor()]);
    final d = _dio;
    if (d == null) throw StateError('dio not initialized');
    return d;
  }

  static RequestServer _getInstance() {
    _instance ??= RequestServer(dio, baseUrl: Env.ROOT_URL);
    final instance = _instance;
    if (instance == null) throw StateError('instance not initialized');
    return instance;
  }
}

class _HeaderInterceptor extends Interceptor {
  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra["no-auth"] == true) {
      return handler.next(options);
    }
    // 需要验证的逻辑
    final token = await LoginCache.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers["Authorization"] = token;
    }

    handler.next(options);
  }
}

class _AuthInterceptor extends Interceptor {
  static bool _isRedirecting = false;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.data is Map && response.data['retCode'] == 10002) {
      _handleUnauthorized();
      handler.reject(DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: '登录已过期',
      ));
      return;
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _handleUnauthorized();
    }
    handler.next(err);
  }

  void _handleUnauthorized() {
    if (_isRedirecting) return;
    _isRedirecting = true;
    LoginCache.removeAll();
    PushService.instance.unregister();

    // 使用 i18n 国际化文本
    final context = RouterUtil.navigatorKey.currentContext;
    if (context != null) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        l10n.authExpired.toast();
      } else {
        "登录已过期，请重新登录".toast();
      }
    } else {
      "登录已过期，请重新登录".toast();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoginPage.pushAndRemoveTo();
    });
    Future.delayed(const Duration(seconds: 2), () {
      _isRedirecting = false;
    });
  }
}

extension DioExceptionExt on DioException {
  String toHumanMessage() {
    // 获取 context 用于 i18n
    final context = RouterUtil.navigatorKey.currentContext;
    final l10n = context != null ? AppLocalizations.of(context) : null;

    // 如果无法获取 l10n，使用中文 fallback
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return l10n?.networkTimeout ?? "网络连接超时，请检查网络设置";
      case DioExceptionType.badCertificate:
        return l10n?.networkBadCertificate ?? "网络证书校验失败";
      case DioExceptionType.badResponse:
        final code = response?.statusCode;
        switch (code) {
          case 400:
            return l10n?.networkError400 ?? "错误的请求 (400)";
          case 401:
            return l10n?.networkError401 ?? "登录已过期，请重新登录";
          case 403:
            return l10n?.networkError403 ?? "拒绝访问 (403)";
          case 404:
            return l10n?.networkError404 ?? "请求资源不存在 (404)";
          case 500:
            return l10n?.networkError500 ?? "服务器内部错误 (500)";
          case 502:
            return l10n?.networkError502 ?? "服务器正在维护或网关错误 (502)";
          case 503:
            return l10n?.networkError503 ?? "服务暂时不可用 (503)";
          default:
            // 替换动态文本中的占位符
            final defaultMsg = "服务器响应异常 ($code)";
            if (l10n != null) {
              return l10n.networkErrorDefault(code ?? 0);
            }
            return defaultMsg;
        }
      case DioExceptionType.cancel:
        return l10n?.networkRequestCancelled ?? "请求已取消";
      case DioExceptionType.connectionError:
        return l10n?.networkConnectionError ?? "无法连接到服务器，请检查网络";
      case DioExceptionType.unknown:
        if (message?.contains("SocketException") ?? false) {
          return l10n?.networkSocketError ?? "网络不可用，请检查连接";
        }
        return l10n?.networkUnknownError ?? "未知网络错误";
      default:
        return l10n?.networkRequestFailed ?? "网络请求失败，请稍后重试";
    }
  }
}

@JsonSerializable(genericArgumentFactories: true)
class HttpResponse<T> {
  const HttpResponse({this.retCode, this.data, this.errorMsg});

  final int? retCode;
  final T? data;
  final String? errorMsg;

  // @override
  int iCode() => retCode ?? -1;

  // @override
  String? iMessage() => errorMsg;

  // @override
  bool iSuccess() => retCode == 200;

  factory HttpResponse.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) => _$HttpResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) => _$HttpResponseToJson(this, toJsonT);
}

extension IResponseTake<T> on HttpResponse<T> {
  T? take({bool errorShow = true}) {
    if (!iSuccess()) {
      if (retCode == 401 || retCode == 10002) {
        return null;
      }
      if (errorShow == true) {
        errorMsg?.toast();
      }
      return null;
    }
    return data;
  }
}

@RestApi()
abstract class RequestServer {
  factory RequestServer(Dio dio, {String? baseUrl}) = _RequestServer;

  @POST("/auth/operation/login")
  @Extra({'no-auth': true}) // 关键点：添加自定义标记
  Future<HttpResponse<LoginInfo?>?> login(@Body() LoginRequest body);

  @POST("/operation/scan")
  @FormUrlEncoded()
  Future<HttpResponse<String?>?> scan(@Field("ciphertext") String ciphertext);

  @POST("/operation/dashboard")
  Future<HttpResponse<OperationDashboardVo?>?> dashboard(@Body() DashboardRequestBody body);

  @POST("/operation/devices")
  Future<HttpResponse<List<OperationOperatorVo>?>?> devices();

  @POST("/operation/devices/status")
  Future<HttpResponse<List<OperationDeviceStatusVo>?>?> devicesStatus(@Body() OperationDeviceStatusRequestBody body);

  @POST("/operation/mqtt/info")
  Future<HttpResponse<MqttInfoVo?>?> operationMqttInfo();

  @POST("/operation/stock/query")
  Future<HttpResponse<List<DeviceStockVo>?>?> stockQuery(@Body() OperationStockQueryRequestBody body);

  @POST("/operation/stock/save")
  Future<HttpResponse<bool?>?> stockSave(@Body() OperationStockSaveRequestBody body);

  @POST("/operation/product/materiel/query/all")
  Future<HttpResponse<dynamic>?> materielQueryAll();

  @POST("/operation/stock/record/query")
  Future<HttpResponse<StockRecordPageResult?>?> stockRecordQuery(@Body() StockRecordQueryRequestBody body);

  @POST("/operation/order/list")
  Future<HttpResponse<OrderPageResult?>?> orderList(@Body() OperationOrderQueryRequestBody body);

  @POST("/operation/order/detail")
  Future<HttpResponse<AdminOrderDetailVo?>?> orderDetail(@Body() OperationOrderDetailQueryRequestBody body);

  @GET("/operation/order/item/detail")
  Future<HttpResponse<AdminOrderItemQueryVo?>?> orderItemDetail(@Query("itemId") int itemId);

  @POST("/operation/order/statistics")
  Future<HttpResponse<OperationOrderStatisticsVo?>?> orderStatistics(@Body() OperationOrderStatisticsRequestBody body);

  @POST("/operation/order/order/item/discard")
  Future<HttpResponse<bool?>?> orderItemDiscard(@Body() AdminOrderItemDiscardRequestBody body);

  @POST("/operation/order/item/batch/cancel")
  Future<HttpResponse<bool?>?> orderItemBatchCancel(@Body() OrderItemBatchCancelRequestBody body);

  @POST("/operation/device/onlineEvents")
  Future<HttpResponse<OnlineEventsPage?>?> deviceOnlineEvents(@Body() OperationDeviceEventsRequestBody body);

  @POST("/operation/device/faultHistory")
  Future<HttpResponse<FaultHistoryPage?>?> deviceFaultHistory(@Body() OperationDeviceEventsRequestBody body);

  @POST("/operation/device/electricalChart")
  Future<HttpResponse<List<ElectricalChartPointVo>?>?> deviceElectricalChart(@Body() OperationElectricalChartRequestBody body);

  @POST("/operation/alert/query")
  Future<HttpResponse<AlertPageResult?>?> alertQuery(@Body() AlertQueryRequestBody body);

  @POST("/operation/alert/count")
  Future<HttpResponse<AlertCountVo?>?> alertCount();

  @POST("/operation/alert/acknowledge")
  Future<HttpResponse<String?>?> alertAcknowledge(@Body() AlertBatchRequestBody body);

  @POST("/operation/alert/resolve")
  Future<HttpResponse<String?>?> alertResolve(@Body() AlertBatchRequestBody body);

  @POST("/operation/push/register")
  Future<HttpResponse<bool?>?> pushRegister(@Body() PushRegisterRequestBody body);

  @POST("/operation/push/unregister")
  Future<HttpResponse<String?>?> pushUnregister(@Body() PushUnregisterRequestBody body);
}
