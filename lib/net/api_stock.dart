import 'package:operation/ext/enums.dart';

// ============================================================
// 库存查询响应 DTO
// ============================================================

/// 设备库存条目，对应后端 DeviceStockVo
class DeviceStockVo {
  /// 库存ID（device_stock 主键）
  final int? id;
  /// 库存名称
  final String? name;
  /// 组件编码
  final String? compCode;
  /// 设备组件名称（如"豆仓A"、"水箱"）
  final String? compName;
  /// 组件内序号
  final int? index;
  /// 当前绑定的物料ID
  final int? productMaterielId;
  /// 当前绑定的物料名称
  final String? productMaterielName;
  /// 库存模式：CLOUD_CALC / HW_COLLECT / INFINITE / UNKNOWN / HW_CALC
  final StockMode? stockMode;
  /// 物料类型：CUP / CAP / MILK / CoffeeBean / WATER / SYRUP / CO2
  final GoodsMaterialType? productMaterielType;
  /// 物料详情类型
  final String? detailType;
  /// 当前库存数量
  final int? currentStock;
  /// 最大库存数量（可能为 null 或 0）
  final int? maxStock;
  /// 库存单位
  final String? unit;
  /// 创建时间（Unix 时间戳，秒）
  final int? createTime;
  /// 更新时间（Unix 时间戳，秒）
  final int? updateTime;

  DeviceStockVo({
    this.id,
    this.name,
    this.compCode,
    this.compName,
    this.index,
    this.productMaterielId,
    this.productMaterielName,
    this.stockMode,
    this.productMaterielType,
    this.detailType,
    this.currentStock,
    this.maxStock,
    this.unit,
    this.createTime,
    this.updateTime,
  });

  factory DeviceStockVo.fromJson(Map<String, dynamic> json) => DeviceStockVo(
    id: json['id'] as int?,
    name: json['name'] as String?,
    compCode: json['compCode'] as String?,
    compName: json['compName'] as String?,
    index: json['index'] as int?,
    productMaterielId: json['productMaterielId'] as int?,
    productMaterielName: json['productMaterielName'] as String?,
    stockMode: StockMode.fromApiValue(json['stockMode'] as String?),
    productMaterielType: GoodsMaterialType.fromApiValue(json['productMaterielType'] as String?),
    detailType: json['detailType'] as String?,
    currentStock: json['currentStock'] as int?,
    maxStock: json['maxStock'] as int?,
    unit: json['unit'] as String?,
    createTime: json['createTime'] as int?,
    updateTime: json['updateTime'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'compCode': compCode,
    'compName': compName,
    'index': index,
    'productMaterielId': productMaterielId,
    'productMaterielName': productMaterielName,
    'stockMode': stockMode?.apiValue,
    'productMaterielType': productMaterielType?.apiValue,
    'detailType': detailType,
    'currentStock': currentStock,
    'maxStock': maxStock,
    'unit': unit,
    'createTime': createTime,
    'updateTime': updateTime,
  };
}

// ============================================================
// 库存查询请求体
// ============================================================

/// 查询设备库存请求，对应后端 OperationStockQueryRequestBody
class OperationStockQueryRequestBody {
  /// 设备ID
  final int deviceId;

  OperationStockQueryRequestBody({required this.deviceId});

  factory OperationStockQueryRequestBody.fromJson(Map<String, dynamic> json) =>
      OperationStockQueryRequestBody(deviceId: json['deviceId'] as int);

  Map<String, dynamic> toJson() => {'deviceId': deviceId};
}

// ============================================================
// 库存保存请求体
// ============================================================

/// 单条库存保存项，对应后端 DeviceStockSaveRequestBody
class DeviceStockSaveItem {
  /// 库存记录ID
  final int id;
  /// 物料ID
  final int productMaterielId;
  /// 当前数量 / 补货量（HW_COLLECT/UNKNOWN 模式可为 null）
  final int? stock;
  /// 保存方式：ADD（增量） / SET（绝对值）
  final StockSaveMode? saveMode;

  DeviceStockSaveItem({required this.id, required this.productMaterielId, this.stock, this.saveMode});

  factory DeviceStockSaveItem.fromJson(Map<String, dynamic> json) => DeviceStockSaveItem(
    id: json['id'] as int,
    productMaterielId: json['productMaterielId'] as int,
    stock: json['stock'] as int?,
    saveMode: StockSaveMode.fromApiValue(json['saveMode'] as String?),
  );

  Map<String, dynamic> toJson() => {'id': id, 'productMaterielId': productMaterielId, 'stock': stock, 'saveMode': saveMode?.apiValue};
}

/// 保存设备库存请求，对应后端 OperationStockSaveRequestBody
class OperationStockSaveRequestBody {
  /// 设备ID
  final int deviceId;
  /// 库存变更列表
  final List<DeviceStockSaveItem> list;

  OperationStockSaveRequestBody({required this.deviceId, required this.list});

  factory OperationStockSaveRequestBody.fromJson(Map<String, dynamic> json) => OperationStockSaveRequestBody(
    deviceId: json['deviceId'] as int,
    list: (json['list'] as List).map((e) => DeviceStockSaveItem.fromJson(e as Map<String, dynamic>)).toList(),
  );

  Map<String, dynamic> toJson() => {'deviceId': deviceId, 'list': list.map((e) => e.toJson()).toList()};
}

// ============================================================
// 物料 DTO
// ============================================================

/// 物料信息，对应后端 ProductMaterielVo
class ProductMaterielVo {
  /// 物料ID
  final int? id;
  /// 物料名称
  final String? name;
  /// 物料类型：CUP / CAP / MILK / CoffeeBean / WATER / SYRUP / CO2
  final GoodsMaterialType? type;
  /// 物料描述
  final String? description;
  /// 创建时间（毫秒级时间戳）
  final int? createTime;
  /// 更新时间（毫秒级时间戳）
  final int? updateTime;

  ProductMaterielVo({this.id, this.name, this.type, this.description, this.createTime, this.updateTime});

  factory ProductMaterielVo.fromJson(Map<String, dynamic> json) => ProductMaterielVo(
    id: json['id'] as int?,
    name: json['name'] as String?,
    type: GoodsMaterialType.fromApiValue(json['type'] as String?),
    description: json['description'] as String?,
    createTime: json['createTime'] as int?,
    updateTime: json['updateTime'] as int?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'type': type?.apiValue, 'description': description, 'createTime': createTime, 'updateTime': updateTime};
}
