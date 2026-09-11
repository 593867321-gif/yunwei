// ============================================================
// 订单列表 DTO
// ============================================================

/// 运营端订单列表项，对应后端 OperationOrderQueryVo
class OperationOrderQueryVo {
  /// 订单编号
  final String? orderSn;
  /// 用户ID
  final int? userId;
  /// 用户账号
  final String? userAccount;
  /// 订单类型：PRODUCT_BUY / USER_RECHARGE
  final String? orderType;
  /// 订单来源：MINI_APP / DEVICE_SCREEN / BACKEND
  final String? source;
  /// 订单总金额
  final double? totalAmount;
  /// 最终应付金额
  final double? actualAmount;
  /// 优惠总额
  final double? discountAmount;
  /// 支付状态：UNPAID / PAID / REFUNDED / CANCELLED / PARTIALLY_REFUNDED
  final String? payStatus;
  /// 订单状态：WAITING_PAYMENT / PAID / PROCESSING / COMPLETED / CANCELLED / REFUNDED / PARTIALLY_REFUNDED
  final String? orderStatus;
  /// 支付方式列表
  final List<String>? payTypeMask;
  /// 交付模式：IMMEDIATE / STORED
  final String? deliveryType;
  /// 商品名称
  final String? productName;
  /// 商品ID
  final int? productId;
  /// 店铺名称
  final String? storeName;
  /// 设备编码
  final String? deviceCode;
  /// 订单完成时间（毫秒时间戳）
  final int? finishedTime;
  /// 订单支付时间（毫秒时间戳）
  final int? payTime;
  /// 订单创建时间（毫秒时间戳）
  final int? createTime;

  OperationOrderQueryVo({
    this.orderSn,
    this.userId,
    this.userAccount,
    this.orderType,
    this.source,
    this.totalAmount,
    this.actualAmount,
    this.discountAmount,
    this.payStatus,
    this.orderStatus,
    this.payTypeMask,
    this.deliveryType,
    this.productName,
    this.productId,
    this.storeName,
    this.deviceCode,
    this.finishedTime,
    this.payTime,
    this.createTime,
  });

  factory OperationOrderQueryVo.fromJson(Map<String, dynamic> json) => OperationOrderQueryVo(
    orderSn: json['orderSn'] as String?,
    userId: json['userId'] as int?,
    userAccount: json['userAccount'] as String?,
    orderType: json['orderType'] as String?,
    source: json['source'] as String?,
    totalAmount: (json['totalAmount'] as num?)?.toDouble(),
    actualAmount: (json['actualAmount'] as num?)?.toDouble(),
    discountAmount: (json['discountAmount'] as num?)?.toDouble(),
    payStatus: json['payStatus'] as String?,
    orderStatus: json['orderStatus'] as String?,
    payTypeMask: (json['payTypeMask'] as List?)?.map((e) => e.toString()).toList(),
    deliveryType: json['deliveryType'] as String?,
    productName: json['productName'] as String?,
    productId: json['productId'] as int?,
    storeName: json['storeName'] as String?,
    deviceCode: json['deviceCode'] as String?,
    finishedTime: json['finishedTime'] as int?,
    payTime: json['payTime'] as int?,
    createTime: json['createTime'] as int?,
  );
}

/// 分页结果，对应后端 SuccessPageResult
class OrderPageResult {
  /// 总条数
  final int? total;
  /// 订单列表
  final List<OperationOrderQueryVo>? list;

  OrderPageResult({this.total, this.list});

  factory OrderPageResult.fromJson(Map<String, dynamic> json) => OrderPageResult(
    total: json['total'] as int?,
    list: (json['list'] as List?)?.map((e) => OperationOrderQueryVo.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

/// 订单列表查询请求体，对应后端 OperationOrderQueryRequestBody
class OperationOrderQueryRequestBody {
  /// 运营商ID（管理域）
  final int? operatorId;
  /// 店铺ID（管理域）
  final int? storeId;
  /// 设备ID（管理域，优先级最高）
  final int? deviceId;
  /// 订单编号，模糊查询
  final String? orderSn;
  /// 支付状态
  final String? payStatus;
  /// 订单状态
  final String? orderStatus;
  /// 创建时间-开始（毫秒时间戳）
  final int? startTime;
  /// 创建时间-结束（毫秒时间戳）
  final int? endTime;
  /// 每页条数
  final int? limit;
  /// 偏移量
  final int? offset;

  OperationOrderQueryRequestBody({
    this.operatorId,
    this.storeId,
    this.deviceId,
    this.orderSn,
    this.payStatus,
    this.orderStatus,
    this.startTime,
    this.endTime,
    this.limit,
    this.offset,
  });

  factory OperationOrderQueryRequestBody.fromJson(Map<String, dynamic> json) => OperationOrderQueryRequestBody(
    operatorId: json['operatorId'] as int?,
    storeId: json['storeId'] as int?,
    deviceId: json['deviceId'] as int?,
    orderSn: json['orderSn'] as String?,
    payStatus: json['payStatus'] as String?,
    orderStatus: json['orderStatus'] as String?,
    startTime: json['startTime'] as int?,
    endTime: json['endTime'] as int?,
    limit: json['limit'] as int?,
    offset: json['offset'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'operatorId': operatorId,
    'storeId': storeId,
    'deviceId': deviceId,
    'orderSn': orderSn,
    'payStatus': payStatus,
    'orderStatus': orderStatus,
    'startTime': startTime,
    'endTime': endTime,
    'limit': limit,
    'offset': offset,
  };
}

// ============================================================
// 订单详情 DTO
// ============================================================

/// 订单详情查询请求体，对应后端 OperationOrderDetailQueryRequestBody
class OperationOrderDetailQueryRequestBody {
  /// 订单编号
  final String orderSn;

  OperationOrderDetailQueryRequestBody({required this.orderSn});

  Map<String, dynamic> toJson() => {'orderSn': orderSn};
}

/// 订单详情中的门店信息
class AdminOrderDetailStoreVo {
  /// 门店ID
  final int? id;
  /// 门店名称
  final String? name;
  /// 门店封面
  final String? cover;
  /// 门店地址
  final String? fullAddress;
  /// 联系方式
  final String? contact;

  AdminOrderDetailStoreVo({this.id, this.name, this.cover, this.fullAddress, this.contact});

  factory AdminOrderDetailStoreVo.fromJson(Map<String, dynamic> json) => AdminOrderDetailStoreVo(
    id: json['id'] as int?,
    name: json['name'] as String?,
    cover: json['cover'] as String?,
    fullAddress: json['fullAddress'] as String?,
    contact: json['contact'] as String?,
  );
}

/// 工单商品快照
class OrderItemProductSnap {
  /// 商品名称
  final String? productName;
  /// 商品封面
  final String? productCover;
  /// SKU名称
  final String? skuName;
  /// SKU封面
  final String? skuCover;

  OrderItemProductSnap({this.productName, this.productCover, this.skuName, this.skuCover});

  factory OrderItemProductSnap.fromJson(Map<String, dynamic> json) => OrderItemProductSnap(
    productName: json['productName'] as String?,
    productCover: json['productCover'] as String?,
    skuName: json['skuName'] as String?,
    skuCover: json['skuCover'] as String?,
  );
}

/// 工单制作物料快照
class OrderItemMaterialSnap {
  /// 关联的物料实体ID
  final int? productMaterielId;
  /// 物料名称
  final String? productMaterielName;
  /// 物料类型
  final String? productMaterielType;
  /// 选择方式：SYSTEM_DEFAULT / USER_SELECTED / CUSTOM_INPUT
  final String? selectionType;
  /// 显示名称
  final String? displayName;
  /// 属性值名称
  final String? valueName;
  /// 属性值
  final String? value;
  /// 基准值
  final String? baseValue;
  /// 基准单位
  final String? baseUnit;
  /// 单位
  final String? unit;
  /// 组件编码
  final String? compCode;
  /// 组件顺序
  final int? compIndex;

  OrderItemMaterialSnap({
    this.productMaterielId,
    this.productMaterielName,
    this.productMaterielType,
    this.selectionType,
    this.displayName,
    this.valueName,
    this.value,
    this.baseValue,
    this.baseUnit,
    this.unit,
    this.compCode,
    this.compIndex,
  });

  factory OrderItemMaterialSnap.fromJson(Map<String, dynamic> json) => OrderItemMaterialSnap(
    productMaterielId: json['productMaterielId'] as int?,
    productMaterielName: json['productMaterielName'] as String?,
    productMaterielType: json['productMaterielType'] as String?,
    selectionType: json['selectionType'] as String?,
    displayName: json['displayName'] as String?,
    valueName: json['valueName'] as String?,
    value: json['value'] as String?,
    baseValue: json['baseValue'] as String?,
    baseUnit: json['baseUnit'] as String?,
    unit: json['unit'] as String?,
    compCode: json['compCode'] as String?,
    compIndex: json['compIndex'] as int?,
  );
}

/// 工单子项快照
class OrderItemSnap {
  /// 商品快照
  final OrderItemProductSnap? product;
  /// 物料列表
  final List<OrderItemMaterialSnap>? material;
  /// 工艺列表（预留，可能为空对象列表）
  final List<dynamic>? recipe;

  OrderItemSnap({this.product, this.material, this.recipe});

  factory OrderItemSnap.fromJson(Map<String, dynamic> json) => OrderItemSnap(
    product: json['product'] != null ? OrderItemProductSnap.fromJson(json['product'] as Map<String, dynamic>) : null,
    material: (json['material'] as List?)?.map((e) => OrderItemMaterialSnap.fromJson(e as Map<String, dynamic>)).toList(),
    recipe: json['recipe'] as List?,
  );
}

/// 订单详情中的工单子项，对应后端 AdminOrderDetailItemVo
class AdminOrderDetailItemVo {
  /// 工单ID
  final int? itemId;
  /// SKU ID
  final int? skuId;
  /// 工单顺序
  final int? itemIndex;
  /// 商品名称
  final String? name;
  /// 商品封面
  final String? cover;
  /// 数量
  final int? quantity;
  /// 单价
  final double? unitPrice;
  /// 工单状态
  final String? makeStatus;
  /// 存储位置
  final String? slotNo;
  /// 取货码
  final String? pickupCode;
  /// 取消原因
  final String? cancelReason;
  /// 工单配方快照
  final OrderItemSnap? snap;

  AdminOrderDetailItemVo({
    this.itemId,
    this.skuId,
    this.itemIndex,
    this.name,
    this.cover,
    this.quantity,
    this.unitPrice,
    this.makeStatus,
    this.slotNo,
    this.pickupCode,
    this.cancelReason,
    this.snap,
  });

  factory AdminOrderDetailItemVo.fromJson(Map<String, dynamic> json) => AdminOrderDetailItemVo(
    itemId: json['itemId'] as int?,
    skuId: json['skuId'] as int?,
    itemIndex: json['itemIndex'] as int?,
    name: json['name'] as String?,
    cover: json['cover'] as String?,
    quantity: json['quantity'] as int?,
    unitPrice: (json['unitPrice'] as num?)?.toDouble(),
    makeStatus: json['makeStatus'] as String?,
    slotNo: json['slotNo'] as String?,
    pickupCode: json['pickupCode'] as String?,
    cancelReason: json['cancelReason'] as String?,
    snap: json['snap'] != null ? OrderItemSnap.fromJson(json['snap'] as Map<String, dynamic>) : null,
  );
}

/// 订单详情，对应后端 AdminOrderDetailVo
class AdminOrderDetailVo {
  /// 订单编号
  final String? orderSn;
  /// 订单来源
  final String? source;
  /// 支付方式
  final String? payType;
  /// 订单总金额
  final double? totalAmount;
  /// 最终应付金额
  final double? actualAmount;
  /// 优惠金额
  final double? discountAmount;
  /// 支付状态
  final String? payStatus;
  /// 订单状态
  final String? orderStatus;
  /// 交付模式
  final String? deliveryType;
  /// 支付时间（毫秒时间戳）
  final int? payTime;
  /// 完成时间（毫秒时间戳）
  final int? finishedTime;
  /// 创建时间（毫秒时间戳）
  final int? createTime;
  /// 过期时间（毫秒时间戳）
  final int? expirationTime;
  /// 设备ID
  final int? deviceId;
  /// 门店信息
  final AdminOrderDetailStoreVo? store;
  /// 工单子项列表
  final List<AdminOrderDetailItemVo>? items;

  AdminOrderDetailVo({
    this.orderSn,
    this.source,
    this.payType,
    this.totalAmount,
    this.actualAmount,
    this.discountAmount,
    this.payStatus,
    this.orderStatus,
    this.deliveryType,
    this.payTime,
    this.finishedTime,
    this.createTime,
    this.expirationTime,
    this.deviceId,
    this.store,
    this.items,
  });

  factory AdminOrderDetailVo.fromJson(Map<String, dynamic> json) => AdminOrderDetailVo(
    orderSn: json['orderSn'] as String?,
    source: json['source'] as String?,
    payType: json['payType'] as String?,
    totalAmount: (json['totalAmount'] as num?)?.toDouble(),
    actualAmount: (json['actualAmount'] as num?)?.toDouble(),
    discountAmount: (json['discountAmount'] as num?)?.toDouble(),
    payStatus: json['payStatus'] as String?,
    orderStatus: json['orderStatus'] as String?,
    deliveryType: json['deliveryType'] as String?,
    payTime: json['payTime'] as int?,
    finishedTime: json['finishedTime'] as int?,
    createTime: json['createTime'] as int?,
    expirationTime: json['expirationTime'] as int?,
    deviceId: json['deviceId'] as int?,
    store: json['store'] != null ? AdminOrderDetailStoreVo.fromJson(json['store'] as Map<String, dynamic>) : null,
    items: (json['items'] as List?)?.map((e) => AdminOrderDetailItemVo.fromJson(e as Map<String, dynamic>)).toList(),
  );
}

// ============================================================
// 工单详情 DTO
// ============================================================

/// 工单详情，对应后端 AdminOrderItemQueryVo
class AdminOrderItemQueryVo {
  /// 工单ID
  final int? id;
  /// 订单编号
  final String? orderSn;
  /// 商品名称
  final String? productName;
  /// SKU名称
  final String? skuName;
  /// SKU ID
  final int? skuId;
  /// 工单索引
  final int? itemIndex;
  /// 制作状态
  final String? makeStatus;
  /// 支付方式
  final String? payType;
  /// 支付状态
  final String? payStatus;
  /// 单价
  final double? unitPrice;
  /// 槽位号
  final String? slotNo;
  /// 交付模式
  final String? deliveryType;
  /// 创建时间（毫秒时间戳）
  final int? createTime;
  /// 制作开始时间（毫秒时间戳）
  final int? makeStartTime;
  /// 制作完成时间（毫秒时间戳）
  final int? makeEndTime;
  /// 取货时间（毫秒时间戳）
  final int? makePickupTime;
  /// 待取走时间（毫秒时间戳）
  final int? makeReadyTime;
  /// 存储时间（毫秒时间戳）
  final int? storageTime;
  /// 支付时间（毫秒时间戳）
  final int? payTime;
  /// 设备 ID
  final int? deviceId;
  /// 取消原因
  final String? cancelReason;
  /// 工单快照
  final OrderItemSnap? snap;

  AdminOrderItemQueryVo({
    this.id,
    this.orderSn,
    this.productName,
    this.skuName,
    this.skuId,
    this.itemIndex,
    this.makeStatus,
    this.payType,
    this.payStatus,
    this.unitPrice,
    this.slotNo,
    this.deliveryType,
    this.createTime,
    this.makeStartTime,
    this.makeEndTime,
    this.makePickupTime,
    this.makeReadyTime,
    this.storageTime,
    this.payTime,
    this.deviceId,
    this.cancelReason,
    this.snap,
  });

  factory AdminOrderItemQueryVo.fromJson(Map<String, dynamic> json) => AdminOrderItemQueryVo(
    id: json['id'] as int?,
    orderSn: json['orderSn'] as String?,
    productName: json['productName'] as String?,
    skuName: json['skuName'] as String?,
    skuId: json['skuId'] as int?,
    itemIndex: json['itemIndex'] as int?,
    makeStatus: json['makeStatus'] as String?,
    payType: json['payType'] as String?,
    payStatus: json['payStatus'] as String?,
    unitPrice: (json['unitPrice'] as num?)?.toDouble(),
    slotNo: json['slotNo'] as String?,
    deliveryType: json['deliveryType'] as String?,
    createTime: json['createTime'] as int?,
    makeStartTime: json['makeStartTime'] as int?,
    makeEndTime: json['makeEndTime'] as int?,
    makePickupTime: json['makePickupTime'] as int?,
    makeReadyTime: json['makeReadyTime'] as int?,
    storageTime: json['storageTime'] as int?,
    payTime: json['payTime'] as int?,
    deviceId: json['deviceId'] as int?,
    cancelReason: json['cancelReason'] as String?,
    snap: json['snap'] != null ? OrderItemSnap.fromJson(json['snap'] as Map<String, dynamic>) : null,
  );
}

// ============================================================
// 订单统计 DTO
// ============================================================

/// 订单统计响应，对应后端 OperationOrderStatisticsVo
class OperationOrderStatisticsVo {
  /// 订单总数（含全部状态，包括已取消与已退款）
  final int? totalOrderCount;
  /// 总营业额（元，保留两位小数；后端已剔除已取消与已全额退款订单，口径同运营看板今日营业额）
  final double? totalRevenue;
  /// 待支付订单数
  final int? unpaidCount;
  /// 已支付订单数
  final int? paidCount;
  /// 已完成订单数
  final int? completedCount;
  /// 已取消订单数
  final int? cancelledCount;
  /// 已退款订单数（含部分退款 PARTIALLY_REFUNDED）
  final int? refundedCount;

  OperationOrderStatisticsVo({
    this.totalOrderCount,
    this.totalRevenue,
    this.unpaidCount,
    this.paidCount,
    this.completedCount,
    this.cancelledCount,
    this.refundedCount,
  });

  factory OperationOrderStatisticsVo.fromJson(Map<String, dynamic> json) => OperationOrderStatisticsVo(
    totalOrderCount: json['totalOrderCount'] as int?,
    totalRevenue: (json['totalRevenue'] as num?)?.toDouble(),
    unpaidCount: json['unpaidCount'] as int?,
    paidCount: json['paidCount'] as int?,
    completedCount: json['completedCount'] as int?,
    cancelledCount: json['cancelledCount'] as int?,
    refundedCount: json['refundedCount'] as int?,
  );
}

/// 订单统计请求体，对应后端 OperationOrderStatisticsRequestBody
class OperationOrderStatisticsRequestBody {
  /// 运营商ID（管理域）
  final int? operatorId;
  /// 店铺ID（管理域）
  final int? storeId;
  /// 设备ID（管理域，优先级最高）
  final int? deviceId;
  /// 创建时间-开始（毫秒时间戳）
  final int? startTime;
  /// 创建时间-结束（毫秒时间戳）
  final int? endTime;

  OperationOrderStatisticsRequestBody({
    this.operatorId,
    this.storeId,
    this.deviceId,
    this.startTime,
    this.endTime,
  });

  Map<String, dynamic> toJson() => {
    'operatorId': operatorId,
    'storeId': storeId,
    'deviceId': deviceId,
    'startTime': startTime,
    'endTime': endTime,
  };
}

// ============================================================
// 中文标签映射（静态方法，避免在 UI 层散落硬编码）
// ============================================================

/// 订单状态中文标签
String orderStatusLabel(String? status) {
  switch (status) {
    case 'WAITING_PAYMENT': return '待支付';
    case 'PAID': return '已支付';
    case 'PROCESSING': return '处理中';
    case 'COMPLETED': return '已完成';
    case 'CANCELLED': return '已取消';
    case 'REFUNDED': return '已退款';
    case 'PARTIALLY_REFUNDED': return '部分退款';
    default: return status ?? '-';
  }
}

/// 丢杯请求体，对应后端 AdminOrderItemDiscardRequestBody
class AdminOrderItemDiscardRequestBody {
  /// 工单ID
  final int orderItemId;
  /// 丢弃原因，选填
  final String? reason;
  /// 是否退款，选填
  final bool? refund;

  AdminOrderItemDiscardRequestBody({required this.orderItemId, this.reason, this.refund});

  Map<String, dynamic> toJson() => {
    'orderItemId': orderItemId,
    'reason': reason,
    'refund': refund,
  };
}

/// 批量取消工单请求体，对应后端 AdminOrderItemBatchCancelRequestBody
class OrderItemBatchCancelRequestBody {
  /// 工单ID列表
  final List<int>? itemIds;
  /// 取消原因，选填
  final String? reason;
  /// 是否退款，选填
  final bool? refund;

  OrderItemBatchCancelRequestBody({this.itemIds, this.reason, this.refund});

  Map<String, dynamic> toJson() => {
    'itemIds': itemIds,
    'reason': reason,
    'refund': refund,
  };
}

/// 支付状态中文标签
String payStatusLabel(String? status) {
  switch (status) {
    case 'UNPAID': return '未支付';
    case 'PAID': return '已支付';
    case 'REFUNDED': return '已退款';
    case 'CANCELLED': return '已取消';
    case 'PARTIALLY_REFUNDED': return '部分退款';
    default: return status ?? '-';
  }
}

/// 支付方式中文标签
String payTypeLabel(String? type) {
  switch (type) {
    case 'WECHAT': return '微信';
    case 'ALIPAY': return '支付宝';
    case 'BALANCE': return '余额';
    case 'EMPLOYEE_CARD': return '员工卡';
    case 'COUPON': return '优惠券';
    case 'INTEGRAL': return '积分';
    case 'SYSTEM_RECHARGE': return '系统充值';
    case 'MARKETING_GIFT': return '营销赠送';
    default: return type ?? '-';
  }
}

/// 订单来源中文标签
String sourceLabel(String? source) {
  switch (source) {
    case 'MINI_APP': return '小程序';
    case 'DEVICE_SCREEN': return '设备屏幕';
    case 'BACKEND': return '后台';
    default: return source ?? '-';
  }
}

/// 交付模式中文标签
String deliveryTypeLabel(String? type) {
  switch (type) {
    case 'IMMEDIATE': return '即时取走';
    case 'STORED': return '存储取走';
    default: return type ?? '-';
  }
}

/// 工单制作状态中文标签
String makeStatusLabel(String? status) {
  switch (status) {
    case 'WITHHOLD': return '预留';
    case 'WAITING': return '待制作';
    case 'MAKING': return '制作中';
    case 'STORED': return '已存储';
    case 'READY': return '待取餐';
    case 'TAKEN': return '已取走';
    case 'FAILED': return '失败';
    case 'CANCEL': return '已取消';
    default: return status ?? '-';
  }
}

/// 订单类型中文标签
String orderTypeLabel(String? type) {
  switch (type) {
    case 'PRODUCT_BUY': return '商品购买';
    case 'USER_RECHARGE': return '用户充值';
    default: return type ?? '-';
  }
}

/// 取消原因中文标签
String cancelReasonLabel(String? reason) {
  switch (reason) {
    case '超时取消': return '超时未支付，系统自动取消';
    case '超时未取餐，系统自动退款': return '超时未取餐，系统已退款';
    case '用户取消': return '用户主动取消';
    default: return reason ?? '-';
  }
}

/// 毫秒时间戳 → DateTime 格式化（完整）
String formatTimestampFull(int? ms) {
  if (ms == null) return '-';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
}

/// 毫秒时间戳 → 时:分（简短格式）
String formatTimestampShort(int? ms) {
  if (ms == null) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
