import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:operation/net/api_stock.dart';
import 'package:operation/ext/enums.dart';

class StockService {
  final String baseUrl;

  StockService({required this.baseUrl});

  /// 查询设备库存列表
  ///
  /// 通过 POST /operation/stock/query 获取设备当前所有库存条目，
  /// 并反序列化为 [DeviceStockVo] 列表返回。
  Future<List<DeviceStockVo>> queryDeviceStock(int deviceId) async {
    final requestBody = OperationStockQueryRequestBody(deviceId: deviceId);
    final uri = Uri.parse('$baseUrl/operation/stock/query');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(requestBody.toJson()),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final list = (jsonData['data'] as Map<String, dynamic>)?['list'] as List<dynamic>? ?? [];
      return list.map((e) => DeviceStockVo.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to query device stock: status ${response.statusCode}');
    }
  }
}
