// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HttpResponse<T> _$HttpResponseFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => HttpResponse<T>(
  retCode: (json['retCode'] as num?)?.toInt(),
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  errorMsg: json['errorMsg'] as String?,
);

Map<String, dynamic> _$HttpResponseToJson<T>(
  HttpResponse<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'retCode': instance.retCode,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
  'errorMsg': instance.errorMsg,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

// dart format off

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations,unused_element_parameter,avoid_unused_constructor_parameters,unreachable_from_main,avoid_redundant_argument_values

class _RequestServer implements RequestServer {
  _RequestServer(this._dio, {this.baseUrl, this.errorLogger});

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<HttpResponse<LoginInfo?>?> login(LoginRequest body) async {
    final _extra = <String, dynamic>{'no-auth': true};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<LoginInfo?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/auth/operation/login',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<LoginInfo?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<LoginInfo?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : LoginInfo.fromJson(json as Map<String, dynamic>),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<String?>?> scan(String ciphertext) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = {'ciphertext': ciphertext};
    final _options = _setStreamType<HttpResponse<String?>?>(
      Options(
            method: 'POST',
            headers: _headers,
            extra: _extra,
            contentType: 'application/x-www-form-urlencoded',
          )
          .compose(
            _dio.options,
            '/operation/scan',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<String?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<String?>.fromJson(
              _result.data!,
              (json) => json as String?,
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<OperationDashboardVo?>?> dashboard(
    DashboardRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<OperationDashboardVo?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/dashboard',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<OperationDashboardVo?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<OperationDashboardVo?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : OperationDashboardVo.fromJson(json as Map<String, dynamic>),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<List<OperationOperatorVo>?>?> devices() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<HttpResponse<List<OperationOperatorVo>?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/devices',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<List<OperationOperatorVo>?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<List<OperationOperatorVo>?>.fromJson(
              _result.data!,
              (json) => json is List<dynamic>
                  ? json
                        .map<OperationOperatorVo>(
                          (i) => OperationOperatorVo.fromJson(
                            i as Map<String, dynamic>,
                          ),
                        )
                        .toList()
                  : List.empty(),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<List<OperationDeviceStatusVo>?>?> devicesStatus(
    OperationDeviceStatusRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options =
        _setStreamType<HttpResponse<List<OperationDeviceStatusVo>?>?>(
          Options(method: 'POST', headers: _headers, extra: _extra)
              .compose(
                _dio.options,
                '/operation/devices/status',
                queryParameters: queryParameters,
                data: _data,
              )
              .copyWith(
                baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
              ),
        );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<List<OperationDeviceStatusVo>?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<List<OperationDeviceStatusVo>?>.fromJson(
              _result.data!,
              (json) => json is List<dynamic>
                  ? json
                        .map<OperationDeviceStatusVo>(
                          (i) => OperationDeviceStatusVo.fromJson(
                            i as Map<String, dynamic>,
                          ),
                        )
                        .toList()
                  : List.empty(),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<MqttInfoVo?>?> operationMqttInfo() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<HttpResponse<MqttInfoVo?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/mqtt/info',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<MqttInfoVo?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<MqttInfoVo?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : MqttInfoVo.fromJson(json as Map<String, dynamic>),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<List<DeviceStockVo>?>?> stockQuery(
    OperationStockQueryRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<List<DeviceStockVo>?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/stock/query',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<List<DeviceStockVo>?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<List<DeviceStockVo>?>.fromJson(
              _result.data!,
              (json) => json is List<dynamic>
                  ? json
                        .map<DeviceStockVo>(
                          (i) =>
                              DeviceStockVo.fromJson(i as Map<String, dynamic>),
                        )
                        .toList()
                  : List.empty(),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<bool?>?> stockSave(
    OperationStockSaveRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<bool?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/stock/save',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<bool?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<bool?>.fromJson(
              _result.data!,
              (json) => json as bool?,
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<dynamic>?> materielQueryAll() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<HttpResponse<dynamic>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/product/materiel/query/all',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<dynamic>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<dynamic>.fromJson(
              _result.data!,
              (json) => json as dynamic,
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<StockRecordPageResult?>?> stockRecordQuery(
    StockRecordQueryRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<StockRecordPageResult?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/stock/record/query',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<StockRecordPageResult?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<StockRecordPageResult?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : StockRecordPageResult.fromJson(
                      json as Map<String, dynamic>,
                    ),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<OrderPageResult?>?> orderList(
    OperationOrderQueryRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<OrderPageResult?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/order/list',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<OrderPageResult?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<OrderPageResult?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : OrderPageResult.fromJson(json as Map<String, dynamic>),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<AdminOrderDetailVo?>?> orderDetail(
    OperationOrderDetailQueryRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<AdminOrderDetailVo?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/order/detail',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<AdminOrderDetailVo?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<AdminOrderDetailVo?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : AdminOrderDetailVo.fromJson(json as Map<String, dynamic>),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<AdminOrderItemQueryVo?>?> orderItemDetail(
    int itemId,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'itemId': itemId};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<HttpResponse<AdminOrderItemQueryVo?>?>(
      Options(method: 'GET', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/order/item/detail',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<AdminOrderItemQueryVo?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<AdminOrderItemQueryVo?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : AdminOrderItemQueryVo.fromJson(
                      json as Map<String, dynamic>,
                    ),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<OperationOrderStatisticsVo?>?> orderStatistics(
    OperationOrderStatisticsRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<OperationOrderStatisticsVo?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/order/statistics',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<OperationOrderStatisticsVo?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<OperationOrderStatisticsVo?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : OperationOrderStatisticsVo.fromJson(
                      json as Map<String, dynamic>,
                    ),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<bool?>?> orderItemDiscard(
    AdminOrderItemDiscardRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<bool?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/order/order/item/discard',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<bool?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<bool?>.fromJson(
              _result.data!,
              (json) => json as bool?,
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<bool?>?> orderItemBatchCancel(
    OrderItemBatchCancelRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<bool?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/order/item/batch/cancel',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<bool?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<bool?>.fromJson(
              _result.data!,
              (json) => json as bool?,
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<OnlineEventsPage?>?> deviceOnlineEvents(
    OperationDeviceEventsRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<OnlineEventsPage?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/device/onlineEvents',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<OnlineEventsPage?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<OnlineEventsPage?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : OnlineEventsPage.fromJson(json as Map<String, dynamic>),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<FaultHistoryPage?>?> deviceFaultHistory(
    OperationDeviceEventsRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<FaultHistoryPage?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/device/faultHistory',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<FaultHistoryPage?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<FaultHistoryPage?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : FaultHistoryPage.fromJson(json as Map<String, dynamic>),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<List<ElectricalChartPointVo>?>?> deviceElectricalChart(
    OperationElectricalChartRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options =
        _setStreamType<HttpResponse<List<ElectricalChartPointVo>?>?>(
          Options(method: 'POST', headers: _headers, extra: _extra)
              .compose(
                _dio.options,
                '/operation/device/electricalChart',
                queryParameters: queryParameters,
                data: _data,
              )
              .copyWith(
                baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl),
              ),
        );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<List<ElectricalChartPointVo>?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<List<ElectricalChartPointVo>?>.fromJson(
              _result.data!,
              (json) => json is List<dynamic>
                  ? json
                        .map<ElectricalChartPointVo>(
                          (i) => ElectricalChartPointVo.fromJson(
                            i as Map<String, dynamic>,
                          ),
                        )
                        .toList()
                  : List.empty(),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<AlertPageResult?>?> alertQuery(
    AlertQueryRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<AlertPageResult?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/alert/query',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<AlertPageResult?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<AlertPageResult?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : AlertPageResult.fromJson(json as Map<String, dynamic>),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<AlertCountVo?>?> alertCount() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<HttpResponse<AlertCountVo?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/alert/count',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<AlertCountVo?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<AlertCountVo?>.fromJson(
              _result.data!,
              (json) => json == null
                  ? null
                  : AlertCountVo.fromJson(json as Map<String, dynamic>),
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<String?>?> alertAcknowledge(
    AlertBatchRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<String?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/alert/acknowledge',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<String?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<String?>.fromJson(
              _result.data!,
              (json) => json as String?,
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<String?>?> alertResolve(
    AlertBatchRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<String?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/alert/resolve',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<String?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<String?>.fromJson(
              _result.data!,
              (json) => json as String?,
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<bool?>?> pushRegister(
    PushRegisterRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<bool?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/push/register',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<bool?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<bool?>.fromJson(
              _result.data!,
              (json) => json as bool?,
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<String?>?> pushUnregister(
    PushUnregisterRequestBody body,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(body.toJson());
    final _options = _setStreamType<HttpResponse<String?>?>(
      Options(method: 'POST', headers: _headers, extra: _extra)
          .compose(
            _dio.options,
            '/operation/push/unregister',
            queryParameters: queryParameters,
            data: _data,
          )
          .copyWith(baseUrl: _combineBaseUrls(_dio.options.baseUrl, baseUrl)),
    );
    final _result = await _dio.fetch<Map<String, dynamic>?>(_options);
    late HttpResponse<String?>? _value;
    try {
      _value = _result.data == null
          ? null
          : HttpResponse<String?>.fromJson(
              _result.data!,
              (json) => json as String?,
            );
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options, response: _result);
      rethrow;
    }
    return _value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }

  String _combineBaseUrls(String dioBaseUrl, String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}

// dart format on
