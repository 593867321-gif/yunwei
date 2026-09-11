import 'package:operation/ext/enums.dart';

// ============================================================
// 库存记录查询请求体
// ============================================================

/// 查询设备库存变动记录请求体，对应后端 OperationStockRecordQueryRequestBody
class StockRecordQueryRequestBody {
  /// 设备ID
  final int deviceId;
  /// 物料ID（可选筛选）
  final int? materialId;
  /// 事务类型（可选筛选）
  final TransactionType? transactionType;
  /// 事务状态（可选筛选）
  final TransactionStatus? status;
  /// 创建时间-开始（含，毫秒级时间戳）
  final int? startTime;
  /// 创建时间-结束（含，毫秒级时间戳）
  final int? endTime;
  /// 分页大小 (1-1000)
  final int limit;
  /// 页码（从 0 开始，非数据库 offset）
  final int offset;

  StockRecordQueryRequestBody({
    required this.deviceId,
    this.materialId,
    this.transactionType,
    this.status,
    this.startTime,
    this.endTime,
    this.limit = 20,
    this.offset = 0,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'materialId': materialId,
    'transactionType': transactionType?.apiValue,
    'status': status?.name,
    'startTime': startTime,
    'endTime': endTime,
    'limit': limit,
    'offset': offset,
  };
}

// ============================================================
// 库存记录条目 DTO
// ============================================================

/// 设备库存变动记录，对应后端 OperationStockRecordVo
class StockRecordVo {
  /// 记录ID
  final int? id;
  /// 设备ID
  final int? deviceId;
  /// 设备库存组件ID
  final int? deviceStockId;
  /// 物料ID
  final int? materialId;
  /// 物料名称
  final String? materialName;
  /// 事务类型
  final TransactionType? transactionType;
  /// 事务状态
  final TransactionStatus? status;
  /// 变动数量
  final num? changeAmount;
  /// 变动前库存
  final num? stockBefore;
  /// 变动后库存
  final num? stockAfter;
  /// 备注
  final String? memo;
  /// 操作人ID
  final int? operatorId;
  /// 操作人账号
  final String? operatorAccount;
  /// 创建时间（毫秒级时间戳）
  final int? createTime;

  StockRecordVo({
    this.id,
    this.deviceId,
    this.deviceStockId,
    this.materialId,
    this.materialName,
    this.transactionType,
    this.status,
    this.changeAmount,
    this.stockBefore,
    this.stockAfter,
    this.memo,
    this.operatorId,
    this.operatorAccount,
    this.createTime,
  });

  factory StockRecordVo.fromJson(Map<String, dynamic> json) => StockRecordVo(
    id: json['id'] as int?,
    deviceId: json['deviceId'] as int?,
    deviceStockId: json['deviceStockId'] as int?,
    materialId: json['materialId'] as int?,
    materialName: json['materialName'] as String?,
    transactionType: TransactionType.fromApiValue(json['transactionType'] as String?),
    status: TransactionStatus.fromApiValue(json['status'] as String?),
    changeAmount: json['changeAmount'] as num?,
    stockBefore: json['stockBefore'] as num?,
    stockAfter: json['stockAfter'] as num?,
    memo: json['memo'] as String?,
    operatorId: json['operatorId'] as int?,
    operatorAccount: json['operatorAccount'] as String?,
    createTime: json['createTime'] as int?,
  );
}

// ============================================================
// 库存记录分页响应
// ============================================================

/// 库存记录分页结果，对应后端 SuccessPageResultListOperationStockRecordVo
class StockRecordPageResult {
  /// 总记录数
  final int? total;
  /// 记录列表
  final List<StockRecordVo> list;

  StockRecordPageResult({this.total, this.list = const []});

  factory StockRecordPageResult.fromJson(Map<String, dynamic> json) => StockRecordPageResult(
    total: json['total'] as int?,
    list: (json['list'] as List<dynamic>?)?.map((e) => StockRecordVo.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );
}
