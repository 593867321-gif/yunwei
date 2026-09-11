import 'dart:convert';
import 'package:operation/ext/enums.dart';

// ============================================================
// 设备实时状态响应 DTO
// ============================================================

/// 设备不可用组件槽位，对应后端 CompUnavailableSlot
class CompUnavailableSlot {
  /// 组件编码
  final String? compCode;
  /// 槽位索引
  final int? index;

  CompUnavailableSlot({this.compCode, this.index});

  factory CompUnavailableSlot.fromJson(Map<String, dynamic> json) => CompUnavailableSlot(
    compCode: json['compCode'] as String?,
    index: (json['index'] as num?)?.toInt(),
  );
}

/// 设备实时状态，对应后端 OperationDeviceStatusVo
class OperationDeviceStatusVo {
  /// 设备ID
  final int? deviceId;
  /// 设备编码
  final String? deviceCode;
  /// 设备名称
  final String? deviceName;
  /// 设备型号
  final String? model;
  /// 设备运行状态
  final DeviceRunState? runState;
  /// 故障码列表（枚举名字符串）
  final List<DeviceErrorKey> errors;
  /// 告警码列表（枚举名字符串）
  final List<DeviceWaringKey> warnings;
  /// 电气数据快照（设备未上报时为 null）
  final OperationDeviceElectricalVo? electrical;
  /// 库存预警明细（仅返回非正常项）
  final List<DeviceStockAlertVo> stockAlerts;
  /// 当前不可用的设备组件槽位
  final List<CompUnavailableSlot> compUnavailable;

  OperationDeviceStatusVo({
    this.deviceId,
    this.deviceCode,
    this.deviceName,
    this.model,
    this.runState,
    this.errors = const [],
    this.warnings = const [],
    this.electrical,
    this.stockAlerts = const [],
    this.compUnavailable = const [],
  });

  factory OperationDeviceStatusVo.fromJson(Map<String, dynamic> json) => OperationDeviceStatusVo(
    deviceId: (json['deviceId'] as num?)?.toInt(),
    deviceCode: json['deviceCode'] as String?,
    deviceName: json['deviceName'] as String?,
    model: json['model'] as String?,
    runState: DeviceRunState.fromApiValue(json['runState'] as String?),
    errors: (json['errors'] as List?)?.map((e) => DeviceErrorKey.fromApiString(e.toString())).toList() ?? [],
    warnings: (json['warnings'] as List?)?.map((e) => DeviceWaringKey.fromApiString(e.toString())).toList() ?? [],
    electrical: json['electrical'] != null ? OperationDeviceElectricalVo.fromJson(json['electrical'] as Map<String, dynamic>) : null,
    stockAlerts: (json['stockAlerts'] as List?)?.map((e) => DeviceStockAlertVo.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    compUnavailable: (json['compUnavailable'] as List?)?.map((e) => CompUnavailableSlot.fromJson(e as Map<String, dynamic>)).toList() ?? [],
  );

  /// JSON 字符串批量反序列化
  static List<OperationDeviceStatusVo> listFromRawJson(String str) {
    final Iterable iterable = json.decode(str);
    return iterable.map((e) => OperationDeviceStatusVo.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// 库存是否预售罄（SOLD_OUT）
  bool get hasSoldOut => stockAlerts.any((a) => a.level == StockAlertLevel.SOLD_OUT);

  /// 库存是否低库存预警（LOW_STOCK）
  bool get hasLowStock => stockAlerts.any((a) => a.level == StockAlertLevel.LOW_STOCK);
}

// ============================================================
// 电气数据 DTO
// ============================================================

/// 设备电气数据快照，对应后端 OperationDeviceElectricalVo
class OperationDeviceElectricalVo {
  /// 输入电压（接口已换算，单位 V）
  final double? currentVoltage;
  /// 电流（接口已换算，单位 A）
  final double? currentCurrent;
  /// 有功功率（单位 W）
  final int? activeActivePower;
  /// 有功电能（接口已换算，单位 kWh）
  final double? reactivePower;
  /// 用水量（接口已换算，单位 L）
  final double? waterUsage;
  /// 底仓温度（1℃）
  final int? bottomTemp;
  /// 上仓温度（1℃）
  final int? topTemp;
  /// 冷水温度（1℃）
  final int? coldTemp;
  /// 冰藏箱温度（1℃）
  final int? iceTemp;
  /// 进水温度（1℃）
  final int? waterPressureTemp;
  /// 水管表面温度（1℃）
  final int? waterSurfaceTemp;
  /// 进水压力（接口已换算，单位 bar）
  final double? waterPressure;
  /// 进水TDS（1ppm）
  final int? waterTDS;
  /// 奶路称重1（1g）
  final int? milkClog1;
  /// 奶路称重2（1g）
  final int? milkClog2;
  /// 系统缺水标记
  final bool? systemWater;

  OperationDeviceElectricalVo({
    this.currentVoltage,
    this.currentCurrent,
    this.activeActivePower,
    this.reactivePower,
    this.waterUsage,
    this.bottomTemp,
    this.topTemp,
    this.coldTemp,
    this.iceTemp,
    this.waterPressureTemp,
    this.waterSurfaceTemp,
    this.waterPressure,
    this.waterTDS,
    this.milkClog1,
    this.milkClog2,
    this.systemWater,
  });

  factory OperationDeviceElectricalVo.fromJson(Map<String, dynamic> json) => OperationDeviceElectricalVo(
    currentVoltage: (json['currentVoltage'] as num?)?.toDouble(),
    currentCurrent: (json['currentCurrent'] as num?)?.toDouble(),
    activeActivePower: (json['activeActivePower'] as num?)?.toInt(),
    reactivePower: (json['reactivePower'] as num?)?.toDouble(),
    waterUsage: (json['waterUsage'] as num?)?.toDouble(),
    bottomTemp: (json['bottomTemp'] as num?)?.toInt(),
    topTemp: (json['topTemp'] as num?)?.toInt(),
    coldTemp: (json['coldTemp'] as num?)?.toInt(),
    iceTemp: (json['iceTemp'] as num?)?.toInt(),
    waterPressureTemp: (json['waterPressureTemp'] as num?)?.toInt(),
    waterSurfaceTemp: (json['waterSurfaceTemp'] as num?)?.toInt(),
    waterPressure: (json['waterPressure'] as num?)?.toDouble(),
    waterTDS: (json['waterTDS'] as num?)?.toInt(),
    milkClog1: (json['milkClog1'] as num?)?.toInt(),
    milkClog2: (json['milkClog2'] as num?)?.toInt(),
    systemWater: json['systemWater'] as bool?,
  );
}

// ============================================================
// 库存预警 DTO
// ============================================================

/// 库存预警级别，对应后端 StockAlertLevel
enum StockAlertLevel {
  /// 正常 — 库存高于预警阈值
  NORMAL,
  /// 缺料预警 — 库存低于预警阈值但高于告警阈值
  LOW_STOCK,
  /// 售罄 — 库存低于告警阈值，关联商品不可售
  SOLD_OUT;

  /// 中文标签
  String get label {
    switch (this) {
      case StockAlertLevel.NORMAL: return "正常";
      case StockAlertLevel.LOW_STOCK: return "低库存";
      case StockAlertLevel.SOLD_OUT: return "缺货";
    }
  }

  /// 对应颜色
  int get colorValue {
    switch (this) {
      case StockAlertLevel.NORMAL: return 0xFF10B981;
      case StockAlertLevel.LOW_STOCK: return 0xFFF59E0B;
      case StockAlertLevel.SOLD_OUT: return 0xFFEF4444;
    }
  }

  static StockAlertLevel fromApiValue(String? value) {
    switch (value) {
      case 'NORMAL': return StockAlertLevel.NORMAL;
      case 'LOW_STOCK': return StockAlertLevel.LOW_STOCK;
      case 'SOLD_OUT': return StockAlertLevel.SOLD_OUT;
      default: return StockAlertLevel.NORMAL;
    }
  }
}

/// 库存预警条目，对应后端 DeviceStockAlertVo
class DeviceStockAlertVo {
  /// 库存组件编码
  final String? compCode;
  /// 物料ID
  final int? materialId;
  /// 物料名称（库存组件名称）
  final String? materialName;
  /// 预警级别
  final StockAlertLevel level;

  DeviceStockAlertVo({this.compCode, this.materialId, this.materialName, this.level = StockAlertLevel.NORMAL});

  factory DeviceStockAlertVo.fromJson(Map<String, dynamic> json) => DeviceStockAlertVo(
    compCode: json['compCode'] as String?,
    materialId: (json['materialId'] as num?)?.toInt(),
    materialName: json['materialName'] as String?,
    level: StockAlertLevel.fromApiValue(json['level'] as String?),
  );
}
