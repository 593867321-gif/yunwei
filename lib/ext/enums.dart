import 'package:flutter/material.dart';

// ============================================================
// 库存模式枚举
// ============================================================

/// 库存管理模式，对应 StockModeEnum（5 种库存模式）
enum StockMode {
  /// 云端计算：库存数据由云端维护，可精确编辑
  CLOUD_CALC,

  /// 硬件采集：下位机传感器采集有无库存，无具体数量
  HW_COLLECT,

  /// 设备计算：下位机补货量 - 消耗量 = 剩余量
  HW_CALC,

  /// 未知：无法统计，设备报错后才知道缺货
  UNKNOWN,

  /// 无限：默认无限库存，始终可售
  INFINITE;

  /// 中文显示名称
  String get label {
    switch (this) {
      case StockMode.CLOUD_CALC:
        return "云端计算";
      case StockMode.HW_COLLECT:
        return "硬件采集";
      case StockMode.HW_CALC:
        return "设备计算";
      case StockMode.UNKNOWN:
        return "未知";
      case StockMode.INFINITE:
        return "无限";
    }
  }

  /// 模式标签背景色
  Color get badgeColor {
    switch (this) {
      case StockMode.CLOUD_CALC:
        return const Color(0xFFEFF6FF);
      case StockMode.HW_COLLECT:
        return const Color(0xFFECFDF5);
      case StockMode.HW_CALC:
        return const Color(0xFFF5F3FF);
      case StockMode.UNKNOWN:
        return const Color(0xFFFFFBEB);
      case StockMode.INFINITE:
        return const Color(0xFFF1F5F9);
    }
  }

  /// 模式标签文字颜色
  Color get badgeTextColor {
    switch (this) {
      case StockMode.CLOUD_CALC:
        return const Color(0xFF3B82F6);
      case StockMode.HW_COLLECT:
        return const Color(0xFF10B981);
      case StockMode.HW_CALC:
        return const Color(0xFF8B5CF6);
      case StockMode.UNKNOWN:
        return const Color(0xFFF59E0B);
      case StockMode.INFINITE:
        return const Color(0xFF94A3B8);
    }
  }

  /// 是否可编辑库存数量
  bool get isEditable => this == StockMode.CLOUD_CALC;

  /// 是否允许库存操作（编辑/补货/更换物料）
  bool get canOperate => this == StockMode.CLOUD_CALC || this == StockMode.HW_COLLECT || this == StockMode.HW_CALC || this == StockMode.UNKNOWN;

  /// 操作按钮文案：CLOUD_CALC/HW_CALC → "修改库存"，其余 → "补货"
  String get actionLabel => (this == StockMode.CLOUD_CALC || this == StockMode.HW_CALC) ? "修改库存" : "补货";

  /// 是否仅补货记录（不发 MQTT，数量可选）
  bool get isRefillOnly => this == StockMode.HW_COLLECT || this == StockMode.UNKNOWN;

  /// 从 API 字符串反序列化
  static StockMode fromApiValue(String? value) {
    switch (value) {
      case 'CLOUD_CALC':
        return StockMode.CLOUD_CALC;
      case 'HW_COLLECT':
        return StockMode.HW_COLLECT;
      case 'HW_CALC':
        return StockMode.HW_CALC;
      case 'UNKNOWN':
        return StockMode.UNKNOWN;
      case 'INFINITE':
        return StockMode.INFINITE;
      default:
        return StockMode.UNKNOWN;
    }
  }

  /// 序列化为 API 字符串
  String get apiValue => name;
}

// ============================================================
// 库存保存方式枚举
// ============================================================

/// 库存保存方式，对应后端 StockSaveModeEnum
/// 下位机支持两种指令："增加多少"（ADD）和"增加到多少"（SET）
enum StockSaveMode {
  /// 增量模式：在现有库存基础上增加指定数量（currentStock + amount）
  ADD,

  /// 绝对值模式：将库存直接设置为指定数量（currentStock = amount）
  SET;

  /// 中文显示名称
  String get label {
    switch (this) {
      case StockSaveMode.ADD:
        return "增加";
      case StockSaveMode.SET:
        return "设置为";
    }
  }

  /// 弹窗操作标题
  String get actionLabel {
    switch (this) {
      case StockSaveMode.ADD:
        return "增减库存";
      case StockSaveMode.SET:
        return "设定库存";
    }
  }

  /// 操作方式的提示说明
  String get hintLabel {
    switch (this) {
      case StockSaveMode.ADD:
        return "输入增减量（正数增加，负数减少）";
      case StockSaveMode.SET:
        return "输入目标库存数量";
    }
  }

  /// 预览标签
  String resultLabel(int currentStock, int inputValue) {
    switch (this) {
      case StockSaveMode.ADD:
        final result = currentStock + inputValue;
        final sign = inputValue >= 0 ? "+" : "";
        return "当前 $currentStock $sign$inputValue → $result";
      case StockSaveMode.SET:
        return "当前 $currentStock → $inputValue";
    }
  }

  /// 模式选择器背景色
  Color get badgeColor {
    switch (this) {
      case StockSaveMode.ADD:
        return const Color(0xFFECFDF5);
      case StockSaveMode.SET:
        return const Color(0xFFEFF6FF);
    }
  }

  /// 模式选择器文字颜色
  Color get badgeTextColor {
    switch (this) {
      case StockSaveMode.ADD:
        return const Color(0xFF10B981);
      case StockSaveMode.SET:
        return const Color(0xFF3B82F6);
    }
  }

  /// 从 API 字符串反序列化
  static StockSaveMode fromApiValue(String? value) {
    switch (value) {
      case 'ADD':
        return StockSaveMode.ADD;
      case 'SET':
        return StockSaveMode.SET;
      default:
        return StockSaveMode.SET;
    }
  }

  /// 序列化为 API 字符串
  String get apiValue => name;
}

// ============================================================
// 物料类型枚举（命名 GoodsMaterialType 避免与 Flutter MaterialType 冲突）
// ============================================================

/// 物料类型，对应多态物料模型中的物料分类
enum GoodsMaterialType {
  /// 杯子
  CUP,

  /// 盖子
  CAP,

  /// 牛奶
  MILK,

  /// 咖啡豆
  coffeeBean,

  /// 水
  WATER,

  /// 糖浆
  SYRUP,

  /// 二氧化碳
  CO2;

  /// 中文显示名称
  String get label {
    switch (this) {
      case GoodsMaterialType.CUP:
        return "杯子";
      case GoodsMaterialType.CAP:
        return "盖子";
      case GoodsMaterialType.MILK:
        return "牛奶";
      case GoodsMaterialType.coffeeBean:
        return "咖啡豆";
      case GoodsMaterialType.WATER:
        return "水";
      case GoodsMaterialType.SYRUP:
        return "糖浆";
      case GoodsMaterialType.CO2:
        return "二氧化碳";
    }
  }

  /// 从 API 字符串反序列化（兼容 CoffeeBean 大小写）
  /// 返回 null 当 value 为 null 或无法识别时
  static GoodsMaterialType? fromApiValue(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'CUP':
        return GoodsMaterialType.CUP;
      case 'CAP':
        return GoodsMaterialType.CAP;
      case 'MILK':
        return GoodsMaterialType.MILK;
      case 'CoffeeBean':
      case 'coffeeBean':
        return GoodsMaterialType.coffeeBean;
      case 'WATER':
        return GoodsMaterialType.WATER;
      case 'SYRUP':
        return GoodsMaterialType.SYRUP;
      case 'CO2':
        return GoodsMaterialType.CO2;
      default:
        return null;
    }
  }

  /// 序列化为 API 字符串
  String get apiValue => name;
}

// ============================================================
// 库存级别枚举（告警状态）
// ============================================================

/// 库存级别，对应后端 StockLevelEnum
/// 用于 HW_COLLECT / UNKNOWN 模式的状态值（2/1/0）展示
enum StockLevelEnum {
  /// 库存充足（状态值=2）
  NORMAL,
  /// 缺料预警（状态值=1）
  LOW_STOCK,
  /// 售罄（状态值=0）
  SOLD_OUT;

  /// 中文显示名称
  String get label {
    switch (this) {
      case StockLevelEnum.NORMAL:
        return "库存充足";
      case StockLevelEnum.LOW_STOCK:
        return "需补货";
      case StockLevelEnum.SOLD_OUT:
        return "售罄";
    }
  }

  /// 标签背景色
  Color get badgeColor {
    switch (this) {
      case StockLevelEnum.NORMAL:
        return const Color(0xFFECFDF5);
      case StockLevelEnum.LOW_STOCK:
        return const Color(0xFFFFFBEB);
      case StockLevelEnum.SOLD_OUT:
        return const Color(0xFFFEF2F2);
    }
  }

  /// 标签文字颜色
  Color get badgeTextColor {
    switch (this) {
      case StockLevelEnum.NORMAL:
        return const Color(0xFF10B981);
      case StockLevelEnum.LOW_STOCK:
        return const Color(0xFFF59E0B);
      case StockLevelEnum.SOLD_OUT:
        return const Color(0xFFEF4444);
    }
  }

  /// 从当前库存状态值（0/1/2）转换
  /// [value] 设备上报的状态值：2=库存充足, 1=需补货, 0=售罄
  static StockLevelEnum? fromStatusValue(int? value) {
    switch (value) {
      case 2:
        return StockLevelEnum.NORMAL;
      case 1:
        return StockLevelEnum.LOW_STOCK;
      case 0:
        return StockLevelEnum.SOLD_OUT;
      default:
        return null;
    }
  }

  /// 从 API 字符串反序列化
  static StockLevelEnum fromApiValue(String? value) {
    switch (value) {
      case 'NORMAL':
        return StockLevelEnum.NORMAL;
      case 'LOW_STOCK':
        return StockLevelEnum.LOW_STOCK;
      case 'SOLD_OUT':
        return StockLevelEnum.SOLD_OUT;
      default:
        return StockLevelEnum.NORMAL;
    }
  }

  /// 序列化为 API 字符串
  String get apiValue => name;
}

// ============================================================
// 设备在线状态枚举
// ============================================================

/// 设备在线状态
enum OnlineStatus {
  /// 在线
  ONLINE,

  /// 重连中
  RECONNECTION,

  /// 离线
  OFFLINE;

  /// 状态指示灯颜色
  Color get dotColor {
    switch (this) {
      case OnlineStatus.ONLINE:
        return const Color(0xFF10B981);
      case OnlineStatus.RECONNECTION:
        return const Color(0xFFF59E0B);
      case OnlineStatus.OFFLINE:
        return const Color(0xFF94A3B8);
    }
  }

  /// 从 API 字符串反序列化
  static OnlineStatus fromApiValue(String? value) {
    switch (value) {
      case 'ONLINE':
        return OnlineStatus.ONLINE;
      case 'Reconnection':
        return OnlineStatus.RECONNECTION;
      default:
        return OnlineStatus.OFFLINE;
    }
  }

  /// 序列化为 API 字符串
  String get apiValue {
    switch (this) {
      case OnlineStatus.ONLINE:
        return "ONLINE";
      case OnlineStatus.RECONNECTION:
        return "Reconnection";
      case OnlineStatus.OFFLINE:
        return "OFFLINE";
    }
  }
}

// ============================================================
// api_response.dart JSON 序列化辅助函数
// ============================================================

/// 从 JSON 字符串反序列化 OnlineStatus
OnlineStatus? onlineStatusFromJson(String? value) => value != null ? OnlineStatus.fromApiValue(value) : null;

/// 序列化 OnlineStatus 为 JSON 字符串
String? onlineStatusToJson(OnlineStatus? value) => value?.apiValue;

// ============================================================
// 库存事务类型枚举
// ============================================================

/// 库存变动事务类型，对应后端 TransactionTypeEnum
enum TransactionType {
  /// 预扣（订单创建时预扣库存）
  PRE_DEDUCT,
  /// 设备校准（下位机校准上报）
  ADJUSTMENT,
  /// 回滚（订单取消/超时退回库存）
  ROLLBACK,
  /// 补货（运维端补货操作）
  REFILL,
  /// 浪费（报废/损耗）
  WASTE;

  /// 中文显示名称
  String get label {
    switch (this) {
      case TransactionType.PRE_DEDUCT:
        return "预扣";
      case TransactionType.ADJUSTMENT:
        return "校准";
      case TransactionType.ROLLBACK:
        return "回滚";
      case TransactionType.REFILL:
        return "补货";
      case TransactionType.WASTE:
        return "浪费";
    }
  }

  /// Badge 背景色
  Color get badgeColor {
    switch (this) {
      case TransactionType.PRE_DEDUCT:
        return const Color(0xFFEFF6FF);
      case TransactionType.ADJUSTMENT:
        return const Color(0xFFF5F3FF);
      case TransactionType.ROLLBACK:
        return const Color(0xFFFFFBEB);
      case TransactionType.REFILL:
        return const Color(0xFFECFDF5);
      case TransactionType.WASTE:
        return const Color(0xFFFEF2F2);
    }
  }

  /// Badge 文字颜色
  Color get badgeTextColor {
    switch (this) {
      case TransactionType.PRE_DEDUCT:
        return const Color(0xFF3B82F6);
      case TransactionType.ADJUSTMENT:
        return const Color(0xFF8B5CF6);
      case TransactionType.ROLLBACK:
        return const Color(0xFFF59E0B);
      case TransactionType.REFILL:
        return const Color(0xFF10B981);
      case TransactionType.WASTE:
        return const Color(0xFFEF4444);
    }
  }

  /// 从 API 字符串反序列化
  static TransactionType fromApiValue(String? value) {
    switch (value) {
      case 'PRE_DEDUCT':
        return TransactionType.PRE_DEDUCT;
      case 'ADJUSTMENT':
        return TransactionType.ADJUSTMENT;
      case 'ROLLBACK':
        return TransactionType.ROLLBACK;
      case 'REFILL':
        return TransactionType.REFILL;
      case 'WASTE':
        return TransactionType.WASTE;
      default:
        return TransactionType.REFILL;
    }
  }

  /// 序列化为 API 字符串
  String get apiValue => name;
}

// ============================================================
// 库存事务状态枚举
// ============================================================

/// 库存变动事务状态，对应后端 TransactionStatusEnum
enum TransactionStatus {
  /// 待处理
  PENDING,
  /// 已完成
  COMPLETED,
  /// 已回滚
  ROLLED_BACK,
  /// 已失败
  FAILED;

  /// 中文显示名称
  String get label {
    switch (this) {
      case TransactionStatus.PENDING:
        return "待处理";
      case TransactionStatus.COMPLETED:
        return "已完成";
      case TransactionStatus.ROLLED_BACK:
        return "已回滚";
      case TransactionStatus.FAILED:
        return "已失败";
    }
  }

  /// 从 API 字符串反序列化
  static TransactionStatus fromApiValue(String? value) {
    switch (value) {
      case 'PENDING':
        return TransactionStatus.PENDING;
      case 'COMPLETED':
        return TransactionStatus.COMPLETED;
      case 'ROLLED_BACK':
        return TransactionStatus.ROLLED_BACK;
      case 'FAILED':
        return TransactionStatus.FAILED;
      default:
        return TransactionStatus.COMPLETED;
    }
  }
}

// ============================================================
// 设备运行状态枚举
// ============================================================

/// 设备运行状态，对应后端 DeviceStatusEnum
enum DeviceRunState {
  /// 运行中
  power("运行中"),
  /// 停机中
  down("停机中"),
  /// 未知（设备状态异常时的兜底值）
  unknown("未知");

  final String label;
  const DeviceRunState(this.label);

  /// 状态标签背景色
  Color get badgeColor {
    switch (this) {
      case DeviceRunState.power: return const Color(0xFFECFDF5);
      case DeviceRunState.down: return const Color(0xFFFEF2F2);
      case DeviceRunState.unknown: return const Color(0xFFF1F5F9);
    }
  }

  /// 状态标签文字颜色
  Color get badgeTextColor {
    switch (this) {
      case DeviceRunState.power: return const Color(0xFF10B981);
      case DeviceRunState.down: return const Color(0xFFEF4444);
      case DeviceRunState.unknown: return const Color(0xFF94A3B8);
    }
  }

  /// 从 API 字符串反序列化
  static DeviceRunState fromApiValue(String? value) {
    switch (value) {
      case 'power': return DeviceRunState.power;
      case 'down': return DeviceRunState.down;
      default: return DeviceRunState.unknown;
    }
  }
}

// ============================================================
// 设备故障码枚举
// ============================================================

/// 设备故障码，对应后端 ErrorKey
enum DeviceErrorKey {
  /// 缺水故障
  E00("缺水故障"),
  /// 机械臂通电故障
  E10("机械臂通电故障"),
  /// 机械臂全故障
  E11("机械臂全故障"),
  /// 出餐门全部故障
  E20("出餐门全部故障"),
  /// 落杯器全故障
  E30("落杯器全故障"),
  /// 落盖器全故障
  E40("落盖器全故障"),
  /// 饮料机全故障
  E50("饮料机全故障"),
  /// 设备离线故障（服务端推断）
  E_OFFLINE("设备离线"),
  /// 未知故障
  UNKNOWN("未知故障");

  final String label;
  const DeviceErrorKey(this.label);

  /// 故障标签颜色（统一红色）
  Color get badgeColor => const Color(0xFFFEF2F2);

  /// 故障标签文字颜色
  Color get badgeTextColor => const Color(0xFFEF4444);

  /// 从 API 枚举名字符串反序列化
  static DeviceErrorKey fromApiString(String? value) {
    switch (value) {
      case 'E00': return DeviceErrorKey.E00;
      case 'E10': return DeviceErrorKey.E10;
      case 'E11': return DeviceErrorKey.E11;
      case 'E20': return DeviceErrorKey.E20;
      case 'E30': return DeviceErrorKey.E30;
      case 'E40': return DeviceErrorKey.E40;
      case 'E50': return DeviceErrorKey.E50;
      case 'E_OFFLINE': return DeviceErrorKey.E_OFFLINE;
      default: return DeviceErrorKey.UNKNOWN;
    }
  }
}

// ============================================================
// 设备告警码枚举
// ============================================================

/// 设备告警码，对应后端 WaringKey
enum DeviceWaringKey {
  /// 水相关
  W000("冷水通讯报警", true),
  W001("热水通讯报警", true),

  /// 机械臂相关
  W100("机械臂1通讯报警", false),
  W101("机械臂2通讯报警", false),
  W102("机械臂1故障", false),
  W103("机械臂2故障", false),

  /// 出餐门相关
  W200("出餐门1通讯报警", false),
  W201("出餐门2通讯报警", false),
  W202("出餐门3通讯报警", false),
  W203("出餐门4通讯报警", false),
  W204("出餐门1杯托故障报警", false),
  W205("出餐门1前门故障报警", false),
  W206("出餐门2杯托故障报警", false),
  W207("出餐门2前门故障报警", false),
  W208("出餐门3杯托故障报警", false),
  W209("出餐门3前门故障报警", false),
  W210("出餐门4杯托故障报警", false),
  W211("出餐门4前门故障报警", false),

  /// 落杯器相关
  W300("落杯器1通讯报警", true),
  W301("落杯器2通讯报警", true),
  W302("落杯器3通讯报警", true),
  W303("落杯器4通讯报警", true),
  W304("落杯1卡碗报警", true),
  W305("落杯2卡碗报警", true),
  W306("落杯3卡碗报警", true),
  W307("落杯4卡碗报警", true),

  /// 落盖器相关
  W400("落盖器1通讯报警", true),
  W401("落盖器2通讯报警", true),
  W402("落盖1卡盖报警", true),
  W403("落盖2卡盖报警", true),

  /// 饮料机相关
  W500("饮料机1-4路通讯报警", true),
  W501("饮料机5-8路通讯报警", true),
  W502("饮料机9-12路通讯报警", true),
  W503("饮料机管路1堵报警", true),
  W504("饮料机管路2堵报警", true),
  W505("饮料机管路3堵报警", true),
  W506("饮料机管路4堵报警", true),
  W507("饮料机管路5堵报警", true),
  W508("饮料机管路6堵报警", true),
  W509("饮料机管路7堵报警", true),
  W510("饮料机管路8堵报警", true),
  W511("饮料机管路9堵报警", true),
  W512("饮料机管路10堵报警", true),
  W513("饮料机管路11堵报警", true),
  W514("饮料机管路12堵报警", true),

  /// 咖啡机相关
  W600("咖啡机通电报警", true),
  W601("咖啡机通讯报警", true),
  W602("咖啡机报警", true),

  /// 制冰机相关
  W700("制冰机通电报警", true),
  W701("制冰机通讯报警", true),
  W702("制冰机缺冰报警", true),
  W703("制冰机不制冰故障", true),
  W704("制冰机电机故障", true),
  W705("制冰机无水故障", true),
  W706("制冰机温度过高故障", true),

  /// 气泡机相关
  W800("气泡机通电报警", true),
  W801("气泡机通讯报警", true),
  W802("气泡机缺汽", true),
  W803("气泡机缺水", true),

  /// 其他
  W900("丢杯口路通讯报警", false),
  W901("丢杯口杯托故障报警", false),
  W902("丢杯口杯托推杯电机报警", false),

  /// 未知
  UNKNOWN("未知告警", false);

  /// 中文描述
  final String label;
  /// 是否与物料库存相关
  final bool relatedMaterial;

  const DeviceWaringKey(this.label, this.relatedMaterial);

  /// 告警标签背景色
  Color get badgeColor => const Color(0xFFFFFBEB);

  /// 告警标签文字颜色
  Color get badgeTextColor => const Color(0xFFF59E0B);

  /// 从 API 枚举名字符串反序列化
  static DeviceWaringKey fromApiString(String? value) {
    switch (value) {
      case 'W000': return DeviceWaringKey.W000;
      case 'W001': return DeviceWaringKey.W001;
      case 'W100': return DeviceWaringKey.W100;
      case 'W101': return DeviceWaringKey.W101;
      case 'W102': return DeviceWaringKey.W102;
      case 'W103': return DeviceWaringKey.W103;
      case 'W200': return DeviceWaringKey.W200;
      case 'W201': return DeviceWaringKey.W201;
      case 'W202': return DeviceWaringKey.W202;
      case 'W203': return DeviceWaringKey.W203;
      case 'W204': return DeviceWaringKey.W204;
      case 'W205': return DeviceWaringKey.W205;
      case 'W206': return DeviceWaringKey.W206;
      case 'W207': return DeviceWaringKey.W207;
      case 'W208': return DeviceWaringKey.W208;
      case 'W209': return DeviceWaringKey.W209;
      case 'W210': return DeviceWaringKey.W210;
      case 'W211': return DeviceWaringKey.W211;
      case 'W300': return DeviceWaringKey.W300;
      case 'W301': return DeviceWaringKey.W301;
      case 'W302': return DeviceWaringKey.W302;
      case 'W303': return DeviceWaringKey.W303;
      case 'W304': return DeviceWaringKey.W304;
      case 'W305': return DeviceWaringKey.W305;
      case 'W306': return DeviceWaringKey.W306;
      case 'W307': return DeviceWaringKey.W307;
      case 'W400': return DeviceWaringKey.W400;
      case 'W401': return DeviceWaringKey.W401;
      case 'W402': return DeviceWaringKey.W402;
      case 'W403': return DeviceWaringKey.W403;
      case 'W500': return DeviceWaringKey.W500;
      case 'W501': return DeviceWaringKey.W501;
      case 'W502': return DeviceWaringKey.W502;
      case 'W503': return DeviceWaringKey.W503;
      case 'W504': return DeviceWaringKey.W504;
      case 'W505': return DeviceWaringKey.W505;
      case 'W506': return DeviceWaringKey.W506;
      case 'W507': return DeviceWaringKey.W507;
      case 'W508': return DeviceWaringKey.W508;
      case 'W509': return DeviceWaringKey.W509;
      case 'W510': return DeviceWaringKey.W510;
      case 'W511': return DeviceWaringKey.W511;
      case 'W512': return DeviceWaringKey.W512;
      case 'W513': return DeviceWaringKey.W513;
      case 'W514': return DeviceWaringKey.W514;
      case 'W600': return DeviceWaringKey.W600;
      case 'W601': return DeviceWaringKey.W601;
      case 'W602': return DeviceWaringKey.W602;
      case 'W700': return DeviceWaringKey.W700;
      case 'W701': return DeviceWaringKey.W701;
      case 'W702': return DeviceWaringKey.W702;
      case 'W703': return DeviceWaringKey.W703;
      case 'W704': return DeviceWaringKey.W704;
      case 'W705': return DeviceWaringKey.W705;
      case 'W706': return DeviceWaringKey.W706;
      case 'W800': return DeviceWaringKey.W800;
      case 'W801': return DeviceWaringKey.W801;
      case 'W802': return DeviceWaringKey.W802;
      case 'W803': return DeviceWaringKey.W803;
      case 'W900': return DeviceWaringKey.W900;
      case 'W901': return DeviceWaringKey.W901;
      case 'W902': return DeviceWaringKey.W902;
      default: return DeviceWaringKey.UNKNOWN;
    }
  }
}

// ============================================================
// 告警类型枚举
// ============================================================

/// 告警类型，对应后端 AlertTypeEnum
enum AlertTypeEnum {
  /// 设备故障
  DEVICE_FAULT,
  /// 设备告警
  DEVICE_WARNING,
  /// 设备缺货
  STOCK_OUT;

  /// 中文显示名称
  String get label {
    switch (this) {
      case AlertTypeEnum.DEVICE_FAULT:
        return "设备故障";
      case AlertTypeEnum.DEVICE_WARNING:
        return "设备告警";
      case AlertTypeEnum.STOCK_OUT:
        return "缺货预警";
    }
  }

  /// 标签背景色
  Color get badgeColor {
    switch (this) {
      case AlertTypeEnum.DEVICE_FAULT:
        return const Color(0xFFFEF2F2);
      case AlertTypeEnum.DEVICE_WARNING:
        return const Color(0xFFFFFBEB);
      case AlertTypeEnum.STOCK_OUT:
        return const Color(0xFFFEF3C7);
    }
  }

  /// 标签文字颜色
  Color get badgeTextColor {
    switch (this) {
      case AlertTypeEnum.DEVICE_FAULT:
        return const Color(0xFFEF4444);
      case AlertTypeEnum.DEVICE_WARNING:
        return const Color(0xFFF59E0B);
      case AlertTypeEnum.STOCK_OUT:
        return const Color(0xFFD97706);
    }
  }

  /// 从 API 字符串反序列化
  static AlertTypeEnum fromApiValue(String? value) {
    switch (value) {
      case 'DEVICE_FAULT':
        return AlertTypeEnum.DEVICE_FAULT;
      case 'DEVICE_WARNING':
        return AlertTypeEnum.DEVICE_WARNING;
      case 'STOCK_OUT':
        return AlertTypeEnum.STOCK_OUT;
      default:
        return AlertTypeEnum.DEVICE_FAULT;
    }
  }

  /// 序列化为 API 字符串
  String get apiValue => name;
}

// ============================================================
// 告警状态枚举
// ============================================================

/// 告警状态，对应后端 AlertStatusEnum
enum AlertStatusEnum {
  /// 新告警
  NEW,
  /// 已确认
  ACKNOWLEDGED,
  /// 已消除
  RESOLVED;

  /// 中文显示名称
  String get label {
    switch (this) {
      case AlertStatusEnum.NEW:
        return "新告警";
      case AlertStatusEnum.ACKNOWLEDGED:
        return "已确认";
      case AlertStatusEnum.RESOLVED:
        return "已消除";
    }
  }

  /// 标签背景色
  Color get badgeColor {
    switch (this) {
      case AlertStatusEnum.NEW:
        return const Color(0xFFFEF2F2);
      case AlertStatusEnum.ACKNOWLEDGED:
        return const Color(0xFFFFFBEB);
      case AlertStatusEnum.RESOLVED:
        return const Color(0xFFF1F5F9);
    }
  }

  /// 标签文字颜色
  Color get badgeTextColor {
    switch (this) {
      case AlertStatusEnum.NEW:
        return const Color(0xFFEF4444);
      case AlertStatusEnum.ACKNOWLEDGED:
        return const Color(0xFFF59E0B);
      case AlertStatusEnum.RESOLVED:
        return const Color(0xFF94A3B8);
    }
  }

  /// 从 API 字符串反序列化
  static AlertStatusEnum fromApiValue(String? value) {
    switch (value) {
      case 'NEW':
        return AlertStatusEnum.NEW;
      case 'ACKNOWLEDGED':
        return AlertStatusEnum.ACKNOWLEDGED;
      case 'RESOLVED':
        return AlertStatusEnum.RESOLVED;
      default:
        return AlertStatusEnum.NEW;
    }
  }

  /// 序列化为 API 字符串
  String get apiValue => name;
}
