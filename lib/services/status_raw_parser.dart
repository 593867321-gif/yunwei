import 'dart:typed_data';

/// statusRaw 二进制载荷解析器
///
/// Payload 格式（operation-remote-control.md §5 / slave-protocol.md §4.2）：
/// ```
/// | ts int64 BE (8) | Addr uint8 (1) | DataCount uint16 BE (2) | FunCode uint8 (1) | Seq uint8 (1) | ModuleData |
/// ```
///
/// rawFrame：帧头 DataCount 为 BE；ModuleData 为 18 个模块，
/// 每个模块 `[len(1)][data(len 字节)]`，len=0 表示无数据。
/// 模块内多字节数值（uint16/int16/uint32/int32/float32）按 **Big Endian** 解析，
/// 与设备端 `StatusParse` / `getShortBeSafe`/`getIntBeSafe`/`getFloatBeSafe` 一致
///（协议文档曾写 LE，以设备端可正确显示 220.1V 等为准）。
/// 模块顺序与字段偏移见 device-slave-protocol.md §3。
class StatusRawParser {
  /// 解析完整 statusRaw payload，失败返回 null
  ///
  /// [userPropertyTs]：MQTT User Property `ts`（毫秒）。有值时优先使用，
  /// 否则回退 payload 前 8 字节 int64 BE。
  static StatusRawData? parse(Uint8List bytes, {int? userPropertyTs}) {
    if (bytes.length < 13) return null;

    // 使用 sublistView，避免 bytes 自身为 view 时偏移错误
    final buffer = ByteData.sublistView(bytes);
    int offset = 0;

    // 1. 时间戳（8 字节 int64 Big Endian）；业务优先用 User Property ts
    final payloadTs = buffer.getInt64(offset, Endian.big);
    final ts = userPropertyTs ?? payloadTs;
    offset += 8;

    // 2. 帧头
    final addr = bytes[offset];
    offset += 1;
    final dataCount = buffer.getUint16(offset, Endian.big);
    offset += 2;
    final funCode = bytes[offset];
    offset += 1;
    final seq = bytes[offset];
    offset += 1;

    // 3. 从帧头之后遍历模块（与 Android PageStep.split 一致，不按 DataCount 截断）
    final moduleData = Uint8List.sublistView(bytes, offset);
    final modules = _splitModules(moduleData);

    // 4. 解析 18 个模块
    return StatusRawData(
      timestampMs: ts,
      addr: addr,
      dataCount: dataCount,
      funCode: funCode,
      seq: seq,
      modules: modules,
      rawBytes: bytes,
      relayStates: _parseRelayStates(modules),
      ioInputSignals: _parseIoInputSignals(modules),
      moduleLinkStatus: _parseModuleLinkStatus(modules),
      robotArm1: _parseRobotStatus(modules, 0),
      robotArm2: _parseRobotStatus(modules, 1),
      cupLidStatus: _parseCupLidStatus(modules),
      doorStates: _parseDoorStates(modules),
      sensorReadings: _parseSensorReadings(modules),
      iceStatus: _parseIceStatus(modules),
      bubbleStatus: _parseBubbleStatus(modules),
      juiceStatus: _parseJuiceStatus(modules),
      waterHotStatus: _parseWaterHotStatus(modules),
      dropStatus: _parseDropStatus(modules),
      coffeeStatus: _parseCoffeeStatus(modules),
      orderFlowStatus: _parseOrderFlowStatus(modules),
      cachePosition: _parseCachePosition(modules),
      doorOutOrder: _parseDoorOutOrderIds(modules),
      doorOutOrderTaking: _parseDoorOutOrderTakingIds(modules),
      moduleVersions: _parseModuleVersions(modules),
      stockData: _parseStockData(modules),
    );
  }

  /// 按 len-prefix 格式拆分最多 18 个模块
  static List<Uint8List> _splitModules(Uint8List data) {
    final modules = <Uint8List>[];
    int pos = 0;
    while (pos < data.length && modules.length < 18) {
      final len = data[pos];
      pos += 1;
      if (len == 0) {
        modules.add(Uint8List(0));
      } else {
        final end = pos + len;
        if (end > data.length) {
          modules.add(Uint8List.sublistView(data, pos));
          break;
        }
        modules.add(Uint8List.sublistView(data, pos, end));
        pos = end;
      }
    }
    return modules;
  }

  /// 将模块数据转为相对模块起点的 ByteData（修复 sublistView 偏移）
  static ByteData _moduleByteData(Uint8List m) => ByteData.sublistView(m);

  // ============================================================
  // Module 0: System — 系统数据（§3.1）
  // ============================================================

  /// 解析系统电气/温度/水路/奶路等传感器数据
  static SensorReadings? _parseSensorReadings(List<Uint8List> modules) {
    if (modules.isEmpty) return null;
    final sys = modules[0];
    if (sys.length < 46) return null;

    final buf = _moduleByteData(sys);
    return SensorReadings(
      voltage: buf.getUint16(0, Endian.big) / 10.0,
      current: buf.getUint16(2, Endian.big) / 100.0,
      power: buf.getUint16(4, Endian.big).toDouble(),
      energy: buf.getFloat32(6, Endian.big) / 100.0,
      waterUsage: buf.getFloat32(10, Endian.big) / 1000.0,
      bottomTemp: buf.getInt8(14),
      topTemp: buf.getInt8(15),
      coldTemp: buf.getInt8(16),
      coldStorageTemp: buf.getInt8(17),
      waterInTemp: buf.getInt8(18),
      waterSurfaceTemp: buf.getInt8(19),
      waterPressure: buf.getInt16(20, Endian.big) / 100.0,
      tds: buf.getUint16(22, Endian.big),
      milkWeight1: buf.getInt32(24, Endian.big),
      milkWeight2: buf.getInt32(28, Endian.big),
      isWaterShortage: buf.getUint8(32) == 1,
      lattePrintRequest1: buf.getUint8(33),
      latteOrderId1: buf.getUint32(34, Endian.big),
      lattePrintRequest2: buf.getUint8(38),
      latteOrderId2: buf.getUint32(39, Endian.big),
      milkBoxTemp: buf.getInt8(43),
      isReset: buf.getUint8(44) == 1,
      isOrderDropBusy: buf.getUint8(45) == 1,
    );
  }

  // ============================================================
  // Module 1: IO — 输入输出（§3.2）
  // ============================================================

  /// 解析继电器 1-24 通电状态（byte2-4 bitmap，bit=1 闭合）
  static Map<int, bool>? _parseRelayStates(List<Uint8List> modules) {
    if (modules.length <= 1) return null;
    final io = modules[1];
    if (io.length < 5) return null;

    final result = <int, bool>{};
    for (int byteIdx = 0; byteIdx < 3; byteIdx++) {
      final b = io[2 + byteIdx];
      for (int bit = 0; bit < 8; bit++) {
        final relayIdx = byteIdx * 8 + bit + 1;
        result[relayIdx] = ((b >> bit) & 1) == 1;
      }
    }
    return result;
  }

  /// 解析 IO 输入信号（byte0/byte1 低位）
  static IoInputSignals? _parseIoInputSignals(List<Uint8List> modules) {
    if (modules.length <= 1) return null;
    final io = modules[1];
    if (io.length < 2) return null;

    return IoInputSignals(
      inputFlowMeter: (io[0] & 0x01) != 0,
      inputWaterFlowSwitch: (io[0] & 0x02) != 0,
      wasteWaterFlowSwitch: (io[1] & 0x04) != 0,
      wasteWaterFullSwitch: (io[1] & 0x08) != 0,
    );
  }

  // ============================================================
  // Module 2: ModuleLink — 模块通讯状态（§3.3）
  // ============================================================

  /// 解析 22 字节子模块通讯状态：0=成功 → true，1=失败 → false
  static ModuleLinkStatus? _parseModuleLinkStatus(List<Uint8List> modules) {
    if (modules.length <= 2) return null;
    final m = modules[2];
    if (m.length < 22) return null;
    return ModuleLinkStatus(
      robotArm1: m[0] == 0,
      robotArm2: m[1] == 0,
      coffee: m[2] == 0,
      cupDispenser1: m[3] == 0,
      cupDispenser2: m[4] == 0,
      cupDispenser3: m[5] == 0,
      cupDispenser4: m[6] == 0,
      lidDispenser1: m[7] == 0,
      lidDispenser2: m[8] == 0,
      bubble: m[9] == 0,
      coldWater: m[10] == 0,
      waterHot: m[11] == 0,
      juiceGroup1: m[12] == 0,
      juiceGroup2: m[13] == 0,
      juiceGroup3: m[14] == 0,
      door1: m[15] == 0,
      door2: m[16] == 0,
      door3: m[17] == 0,
      door4: m[18] == 0,
      drop: m[19] == 0,
      milkScale: m[20] == 0,
      ice: m[21] == 0,
    );
  }

  // ============================================================
  // Module 3: Robot — 机械臂状态（§3.4）
  // ============================================================

  /// 解析单个机械臂状态。
  /// 每臂 7 字节：状态码/状态位/告警位/制作忙碌/取货忙碌/Z轴高度(2)。
  /// [armIndex] 0=机械臂①（偏移 0），1=机械臂②（偏移 7）
  static RobotStatus? _parseRobotStatus(List<Uint8List> modules, int armIndex) {
    if (modules.length <= 3) return null;
    final robot = modules[3];
    final baseOffset = armIndex * 7;
    if (robot.length < baseOffset + 7) return null;

    final stateCode = robot[baseOffset];
    final statusBits = robot[baseOffset + 1];
    final alarmBits = robot[baseOffset + 2];
    final makeBusy = robot[baseOffset + 3];
    final fetchBusy = robot[baseOffset + 4];
    final zHeight = _moduleByteData(robot).getUint16(baseOffset + 5, Endian.big);

    final stateLabel = switch (stateCode) {
      1 => '空闲',
      2 => '忙碌',
      4 => '故障',
      6 => '待机',
      _ => '未知($stateCode)',
    };

    return RobotStatus(
      stateCode: stateCode,
      stateLabel: stateLabel,
      isRunning: (statusBits & 0x01) != 0,
      isStopped: (statusBits & 0x02) != 0,
      isPaused: (statusBits & 0x04) != 0,
      isAtOrigin: (statusBits & 0x08) != 0,
      isSkinPaused: (statusBits & 0x10) != 0,
      isIdle: (statusBits & 0x20) != 0,
      isPowered: (statusBits & 0x40) != 0,
      isEnabled: (statusBits & 0x80) != 0,
      hasAlarm: (alarmBits & 0x01) != 0,
      hasCollision: (alarmBits & 0x02) != 0,
      isDragging: (alarmBits & 0x04) != 0,
      isMakeBusy: makeBusy == 1,
      isFetchBusy: fetchBusy == 1,
      zHeight: zHeight,
    );
  }

  // ============================================================
  // Module 4: CupLid — 落杯落盖传感器（§3.5）
  // ============================================================

  /// 解析 4 落杯 + 2 落盖的传感器/状态（10 字节）
  static CupLidStatus? _parseCupLidStatus(List<Uint8List> modules) {
    if (modules.length <= 4) return null;
    final m = modules[4];
    if (m.length < 10) return null;

    final b0 = m[0];
    final b5 = m[5];

    return CupLidStatus(
      cup1: CupDispenserStatus(
        present: (b0 & 0x01) != 0,
        shortage: (b0 & 0x02) != 0,
        success: (b0 & 0x04) != 0,
        state: m[2],
      ),
      cup2: CupDispenserStatus(
        present: (b0 & 0x08) != 0,
        shortage: (b0 & 0x10) != 0,
        success: (b0 & 0x20) != 0,
        state: m[3],
      ),
      cup3: CupDispenserStatus(
        present: (b5 & 0x01) != 0,
        shortage: (b5 & 0x02) != 0,
        success: (b5 & 0x04) != 0,
        state: m[7],
      ),
      cup4: CupDispenserStatus(
        present: (b5 & 0x08) != 0,
        shortage: (b5 & 0x10) != 0,
        success: (b5 & 0x20) != 0,
        state: m[8],
      ),
      lid1: LidDispenserStatus(
        present: (b0 & 0x40) != 0,
        shortage: (b0 & 0x80) != 0,
        success: (m[1] & 0x01) != 0,
        state: m[4],
      ),
      lid2: LidDispenserStatus(
        present: (b5 & 0x40) != 0,
        shortage: (b5 & 0x80) != 0,
        success: (m[6] & 0x01) != 0,
        state: m[9],
      ),
    );
  }

  // ============================================================
  // Module 5: Ice — 制冰机（§3.6）
  // ============================================================

  /// 解析制冰机工作/缺冰/故障位（3 字节）
  static IceStatus? _parseIceStatus(List<Uint8List> modules) {
    if (modules.length <= 5) return null;
    final ice = modules[5];
    if (ice.length < 3) return null;
    final stateCode = ice[0];
    final stateLabel = switch (stateCode) {
      0 => '无动作',
      2 => '落冰中',
      _ => '未知($stateCode)',
    };
    return IceStatus(
      stateCode: stateCode,
      stateLabel: stateLabel,
      isEmpty: ice[1] == 1,
      faultBits: ice[2],
    );
  }

  // ============================================================
  // Module 6: Bubble — 气泡机（§3.7）
  // ============================================================

  /// 解析气泡机缺气/缺水/脉冲/气压（9 字节）
  static BubbleStatus? _parseBubbleStatus(List<Uint8List> modules) {
    if (modules.length <= 6) return null;
    final m = modules[6];
    if (m.length < 9) return null;
    final buf = _moduleByteData(m);
    return BubbleStatus(
      co2Empty: m[0] == 1,
      waterState: m[1],
      bubblePulseRemain: buf.getUint16(2, Endian.big),
      coldPulseRemain: buf.getUint16(4, Endian.big),
      pressure: m[6] * 0.1,
      gasTankPressure: buf.getUint16(7, Endian.big) / 10.0,
    );
  }

  // ============================================================
  // Module 7: Juice — 果汁机（§3.8）
  // ============================================================

  /// 解析果汁机整体状态 + 12 路脉冲/堵管（37 字节）
  static JuiceStatus? _parseJuiceStatus(List<Uint8List> modules) {
    if (modules.length <= 7) return null;
    final m = modules[7];
    if (m.length < 37) return null;
    final buf = _moduleByteData(m);

    final channels = <JuiceChannel>[];
    for (int ch = 0; ch < 12; ch++) {
      final base = 1 + ch * 3;
      channels.add(
        JuiceChannel(
          pulseRemain: buf.getUint16(base, Endian.big),
          isClogged: m[base + 2] == 1,
        ),
      );
    }

    return JuiceStatus(isDispensing: m[0] == 1, channels: channels);
  }

  // ============================================================
  // Module 8: WaterHot — 热水（§3.9）
  // ============================================================

  /// 解析热水剩余脉冲、故障位图、出水温度（4 字节）
  static WaterHotStatus? _parseWaterHotStatus(List<Uint8List> modules) {
    if (modules.length <= 8) return null;
    final m = modules[8];
    if (m.length < 4) return null;
    final buf = _moduleByteData(m);
    final faultBits = m[2];
    return WaterHotStatus(
      pulseRemain: buf.getUint16(0, Endian.big),
      isClogged: (faultBits & 0x01) != 0,
      hasHeatFault: (faultBits & 0x02) != 0,
      outputTemp: m[3],
    );
  }

  // ============================================================
  // Module 9: Drop — 丢杯口（§3.10）
  // ============================================================

  /// 解析丢杯口传感器/故障/电机运行状态（4 字节）
  static DropStatus? _parseDropStatus(List<Uint8List> modules) {
    if (modules.length <= 9) return null;
    final m = modules[9];
    if (m.length < 4) return null;

    final sensors = m[0];
    final faults = m[1];
    return DropStatus(
      cupTrayUp: (sensors & 0x01) != 0,
      cupTrayDown: (sensors & 0x02) != 0,
      pushMotorFront: (sensors & 0x04) != 0,
      pushMotorBack: (sensors & 0x08) != 0,
      cupTrayFault: (faults & 0x01) != 0,
      pushMotorFault: (faults & 0x02) != 0,
      cupTrayMotorState: m[2],
      pushMotorState: m[3],
    );
  }

  // ============================================================
  // Module 10: DoorOut — 出餐门（§3.11）
  // ============================================================

  /// 解析 4 个出餐门状态（每门 5 字节，共 20）
  static Map<int, DoorStatus>? _parseDoorStates(List<Uint8List> modules) {
    if (modules.length <= 10) return null;
    final doorMod = modules[10];
    if (doorMod.length < 20) return null;

    final result = <int, DoorStatus>{};
    for (int d = 0; d < 4; d++) {
      final base = d * 5;
      final sensors1 = doorMod[base];
      final sensors2 = doorMod[base + 1];
      final motorFault = doorMod[base + 2];
      final cupMotorState = doorMod[base + 3];
      final frontMotorState = doorMod[base + 4];

      // 杯托下限位=1 视为门开，上限位=1 视为门关
      final bool isCupAtBottom = (sensors1 & 0x02) != 0;
      final bool isCupAtTop = (sensors1 & 0x01) != 0;

      result[d + 1] = DoorStatus(
        isOpen: isCupAtBottom,
        isClosed: isCupAtTop,
        frontDoorUp: (sensors1 & 0x04) != 0,
        frontDoorDown: (sensors1 & 0x08) != 0,
        hasMaterialSensor: (sensors2 & 0x01) != 0,
        hasLightCurtain: (sensors2 & 0x02) != 0,
        hasAntiPinch: (sensors2 & 0x04) != 0,
        hasTakenMaterial: (sensors2 & 0x08) != 0,
        hasCupFault: (motorFault & 0x01) != 0,
        hasFrontFault: (motorFault & 0x02) != 0,
        cupMotorRunning: cupMotorState,
        frontMotorRunning: frontMotorState,
      );
    }
    return result;
  }

  // ============================================================
  // Module 11: Coffee — 咖啡机（§3.12）
  // ============================================================

  /// 解析咖啡机可制作位图、清洗状态、三段动态故障、尾部 13 字节业务量
  static CoffeeMachineStatus? _parseCoffeeStatus(List<Uint8List> modules) {
    if (modules.length <= 11) return null;
    final m = modules[11];
    if (m.length < 2) return null;

    final canBits = m[0];
    final cleaningStatus = m[1];
    int pos = 2;

    List<int> readFaultCodes() {
      if (pos >= m.length) return const [];
      final n = m[pos];
      pos += 1;
      if (n <= 0) return const [];
      if (pos + n > m.length) {
        final codes = m.sublist(pos).toList();
        pos = m.length;
        return codes;
      }
      final codes = m.sublist(pos, pos + n).toList();
      pos += n;
      return codes;
    }

    // 段1 停止 S_00 / 段2 警告 W-00 / 段3 停机 E-00
    final stopFaultCodes = readFaultCodes();
    final warningFaultCodes = readFaultCodes();
    final emergencyFaultCodes = readFaultCodes();

    // 尾部 13 字节（起点随故障长度浮动）
    int? orderId;
    int? milkOut1;
    int? milkOut2;
    double? demandGrindBean;
    double? actualGrindBean;
    int? coffeeType;
    if (pos + 13 <= m.length) {
      final buf = _moduleByteData(m);
      orderId = buf.getUint32(pos, Endian.big);
      milkOut1 = buf.getUint16(pos + 4, Endian.big);
      milkOut2 = buf.getUint16(pos + 6, Endian.big);
      demandGrindBean = buf.getUint16(pos + 8, Endian.big) / 10.0;
      actualGrindBean = buf.getUint16(pos + 10, Endian.big) / 10.0;
      coffeeType = m[pos + 12];
    }

    return CoffeeMachineStatus(
      canMakeBean1: (canBits & 0x01) != 0,
      canMakeBean2: (canBits & 0x02) != 0,
      canMakeMilk1: (canBits & 0x04) != 0,
      canMakeMilk2: (canBits & 0x08) != 0,
      cleaningStatus: cleaningStatus,
      stopFaultCodes: stopFaultCodes,
      warningFaultCodes: warningFaultCodes,
      emergencyFaultCodes: emergencyFaultCodes,
      orderId: orderId,
      milkOut1: milkOut1,
      milkOut2: milkOut2,
      demandGrindBean: demandGrindBean,
      actualGrindBean: actualGrindBean,
      coffeeType: coffeeType,
    );
  }

  // ============================================================
  // Module 12: OrderFlow — 订单制作流程（§3.13）
  // ============================================================

  /// 解析缓存标记、下单许可、订单 1-3（39 字节）
  static OrderFlowStatus? _parseOrderFlowStatus(List<Uint8List> modules) {
    if (modules.length <= 12) return null;
    final m = modules[12];
    if (m.length < 39) return null;
    final buf = _moduleByteData(m);

    final orders = <OrderFlowOrder>[];
    for (int o = 0; o < 3; o++) {
      final base = 9 + o * 10;
      orders.add(
        OrderFlowOrder(
          isBusy: m[base] == 1,
          hasError: m[base + 1] == 1,
          execOrder: buf.getUint16(base + 2, Endian.big),
          step: m[base + 4],
          orderId: buf.getUint32(base + 5, Endian.big),
          arm: m[base + 9],
        ),
      );
    }

    return OrderFlowStatus(
      semiCache1: m[0] == 1,
      semiCache2: m[1] == 1,
      finishCache: m[2] == 1,
      semiPreOccupy1: m[3] == 1,
      semiPreOccupy2: m[4] == 1,
      finishPreOccupy: m[5] == 1,
      allowOrder: m[6] == 1,
      allowCacheOrder: m[7] == 1,
      allowCoffeeOrder: m[8] == 1,
      orders: orders,
    );
  }

  // ============================================================
  // Module 13: CachePosition — 缓存位（§3.14）
  // ============================================================

  /// 解析缓存位订单号列表（每槽 4 字节 uint32）
  static CachePositionData? _parseCachePosition(List<Uint8List> modules) {
    if (modules.length <= 13) return null;
    final m = modules[13];
    if (m.length < 4) return null;
    final buf = _moduleByteData(m);
    final slots = <int?>[];
    for (int i = 0; i < m.length ~/ 4; i++) {
      final id = buf.getUint32(i * 4, Endian.big);
      slots.add((id == 0 || id == 0xFFFFFFFF) ? null : id);
    }
    return CachePositionData(slots: slots);
  }

  // ============================================================
  // Module 14: DoorOutOrder — 出餐门订单（§3.15）
  // ============================================================

  /// 解析出餐门订单号（门未开状态，每门 4 字节）
  static DoorOutOrderData? _parseDoorOutOrderIds(List<Uint8List> modules) {
    if (modules.length <= 14) return null;
    final m = modules[14];
    if (m.length < 4) return null;
    final buf = _moduleByteData(m);
    final ids = <int, int?>{};
    final doorCount = m.length ~/ 4;
    for (int d = 0; d < doorCount; d++) {
      final id = buf.getUint32(d * 4, Endian.big);
      ids[d + 1] = (id == 0 || id == 0xFFFFFFFF) ? null : id;
    }
    return DoorOutOrderData(doorOrderIds: ids);
  }

  // ============================================================
  // Module 15: DoorOutOrderSupportTaking — 可取餐订单（§3.16）
  // ============================================================

  /// 解析出餐门可取餐订单号（门已开状态）
  static DoorOutOrderTakingData? _parseDoorOutOrderTakingIds(
    List<Uint8List> modules,
  ) {
    if (modules.length <= 15) return null;
    final m = modules[15];
    if (m.length < 4) return null;
    final buf = _moduleByteData(m);
    final ids = <int, int?>{};
    final doorCount = m.length ~/ 4;
    for (int d = 0; d < doorCount; d++) {
      final id = buf.getUint32(d * 4, Endian.big);
      ids[d + 1] = (id == 0 || id == 0xFFFFFFFF) ? null : id;
    }
    return DoorOutOrderTakingData(doorOrderIds: ids);
  }

  // ============================================================
  // Module 16: ModuleVersion — 各模块版本号（§3.17）
  // ============================================================

  /// 解析子模块版本号（每版本 2 字节 uint16，至少 12 个）
  static ModuleVersions? _parseModuleVersions(List<Uint8List> modules) {
    if (modules.length <= 16) return null;
    final m = modules[16];
    if (m.length < 24) return null;
    final buf = _moduleByteData(m);
    return ModuleVersions(
      cupDispenser1: buf.getUint16(0, Endian.big),
      cupDispenser2: buf.getUint16(2, Endian.big),
      door1: buf.getUint16(4, Endian.big),
      door2: buf.getUint16(6, Endian.big),
      door3: buf.getUint16(8, Endian.big),
      door4: buf.getUint16(10, Endian.big),
      waterHot: buf.getUint16(12, Endian.big),
      bubble: buf.getUint16(14, Endian.big),
      juice1: buf.getUint16(16, Endian.big),
      juice2: buf.getUint16(18, Endian.big),
      juice3: buf.getUint16(20, Endian.big),
      drop: buf.getUint16(22, Endian.big),
    );
  }

  // ============================================================
  // Module 17: StockData — 系统物料数据（§3.18）
  // ============================================================

  /// 解析杯/盖/果汁/水桶/缓存/门订单及动态缓存订单（固定 58 字节 + 动态）
  static StockData? _parseStockData(List<Uint8List> modules) {
    if (modules.length <= 17) return null;
    final m = modules[17];
    if (m.length < 58) return null;
    final buf = _moduleByteData(m);

    final cupCounts = List.generate(4, (i) => m[i]);
    final lidCounts = List.generate(2, (i) => m[4 + i]);
    final juiceRemains = List.generate(
      12,
      (i) => buf.getUint16(6 + i * 2, Endian.big),
    );

    final cacheOrders = <int>[];
    for (int pos = 58; pos + 4 <= m.length; pos += 4) {
      final id = buf.getUint32(pos, Endian.big);
      if (id != 0 && id != 0xFFFFFFFF) cacheOrders.add(id);
    }

    return StockData(
      cupCounts: cupCounts,
      lidCounts: lidCounts,
      juiceRemains: juiceRemains,
      waterTank1Ml: buf.getUint16(30, Endian.big),
      waterTank2Ml: buf.getUint16(32, Endian.big),
      semiCache1Occupied: m[34] == 1,
      semiCache2Occupied: m[35] == 1,
      finishCacheOccupied: m[36] == 1,
      coffeeSlotOccupied: m[37] == 1,
      waterUsage: buf.getUint32(38, Endian.big),
      door1OrderId: buf.getUint32(42, Endian.big),
      door2OrderId: buf.getUint32(46, Endian.big),
      door3OrderId: buf.getUint32(50, Endian.big),
      door4OrderId: buf.getUint32(54, Endian.big),
      cacheOrders: cacheOrders,
    );
  }
}

// ============================================================
// 结构化状态数据类（供远程控制页 / 服务层消费）
// ============================================================

/// 机械臂单臂状态（Robot 模块 §3.4）
///
/// 用途：展示臂空闲/忙碌/故障、运行位、告警与制作/取货忙碌，以及 Z 轴高度。
class RobotStatus {
  /// 主状态码：1=空闲, 2=忙碌, 4=故障, 6=待机
  final int stateCode;

  /// 主状态中文标签
  final String stateLabel;

  /// 状态位 bit0：运行中
  final bool isRunning;

  /// 状态位 bit1：停止
  final bool isStopped;

  /// 状态位 bit2：暂停
  final bool isPaused;

  /// 状态位 bit3：安全原点
  final bool isAtOrigin;

  /// 状态位 bit4：安全皮肤暂停
  final bool isSkinPaused;

  /// 状态位 bit5：空闲
  final bool isIdle;

  /// 状态位 bit6：上电
  final bool isPowered;

  /// 状态位 bit7：使能
  final bool isEnabled;

  /// 告警位 bit0：报警
  final bool hasAlarm;

  /// 告警位 bit1：碰撞
  final bool hasCollision;

  /// 告警位 bit2：拖拽模式
  final bool isDragging;

  /// 制作忙碌：0=空闲, 1=忙碌
  final bool isMakeBusy;

  /// 取货忙碌：0=空闲, 1=忙碌
  final bool isFetchBusy;

  /// 当前 Z 轴高度（原始 uint16，单位未在协议标明）
  final int zHeight;

  const RobotStatus({
    required this.stateCode,
    required this.stateLabel,
    required this.isRunning,
    required this.isStopped,
    required this.isPaused,
    required this.isAtOrigin,
    required this.isSkinPaused,
    required this.isIdle,
    required this.isPowered,
    required this.isEnabled,
    required this.hasAlarm,
    required this.hasCollision,
    required this.isDragging,
    required this.isMakeBusy,
    required this.isFetchBusy,
    required this.zHeight,
  });
}

/// 制冰机状态（Ice 模块 §3.6）
///
/// 用途：展示落冰中/缺冰及故障位（不制冰、电机、无水、过热）。
class IceStatus {
  /// 工作状态：0=无动作, 2=落冰中
  final int stateCode;

  /// 工作状态标签
  final String stateLabel;

  /// 缺冰：1=缺冰
  final bool isEmpty;

  /// 故障位图 bit0-3
  final int faultBits;

  const IceStatus({
    required this.stateCode,
    required this.stateLabel,
    required this.isEmpty,
    required this.faultBits,
  });

  /// bit0 不制冰故障
  bool get hasNoIceFault => (faultBits & 0x01) != 0;

  /// bit1 电机故障
  bool get hasMotorFault => (faultBits & 0x02) != 0;

  /// bit2 无水故障
  bool get hasNoWaterFault => (faultBits & 0x04) != 0;

  /// bit3 温度过高故障
  bool get hasOverheatFault => (faultBits & 0x08) != 0;

  /// 是否存在任一故障
  bool get hasFault => faultBits != 0;
}

/// 咖啡机状态（Coffee 模块 §3.12）
///
/// 用途：远程控制页展示可制作原料、润湿状态、停止/警告/停机故障码，
/// 以及当前订单号、出奶量、研磨豆量、机型。
class CoffeeMachineStatus {
  /// bit0 豆1 咖啡可制作
  final bool canMakeBean1;

  /// bit1 豆2 咖啡可制作
  final bool canMakeBean2;

  /// bit2 牛奶1 咖啡可制作
  final bool canMakeMilk1;

  /// bit3 牛奶2 咖啡可制作
  final bool canMakeMilk2;

  /// 清洗状态：1=可润湿, 2=润湿中
  final int cleaningStatus;

  /// 停止故障码列表（S_00 段）
  final List<int> stopFaultCodes;

  /// 警告故障码列表（W-00 段）
  final List<int> warningFaultCodes;

  /// 停机故障码列表（E-00 段）
  final List<int> emergencyFaultCodes;

  /// 当前出咖啡订单号（尾部字段，可能缺失）
  final int? orderId;

  /// 实际出奶1（g）
  final int? milkOut1;

  /// 实际出奶2（g）
  final int? milkOut2;

  /// 需求研磨豆（g，×0.1 后）
  final double? demandGrindBean;

  /// 实际研磨豆（g，×0.1 后）
  final double? actualGrindBean;

  /// 咖啡机类型：0=caye, 1=BTB
  final int? coffeeType;

  const CoffeeMachineStatus({
    required this.canMakeBean1,
    required this.canMakeBean2,
    required this.canMakeMilk1,
    required this.canMakeMilk2,
    required this.cleaningStatus,
    required this.stopFaultCodes,
    required this.warningFaultCodes,
    required this.emergencyFaultCodes,
    this.orderId,
    this.milkOut1,
    this.milkOut2,
    this.demandGrindBean,
    this.actualGrindBean,
    this.coffeeType,
  });

  /// 任一路可制作
  bool get canMake =>
      canMakeBean1 || canMakeBean2 || canMakeMilk1 || canMakeMilk2;

  /// 可润湿
  bool get canWet => cleaningStatus == 1;

  /// 润湿中
  bool get isWetting => cleaningStatus == 2;

  /// 是否有停止故障
  bool get hasStopFault => stopFaultCodes.isNotEmpty;

  /// 是否有警告故障
  bool get hasWarningFault => warningFaultCodes.isNotEmpty;

  /// 是否有停机故障
  bool get hasEmergencyFault => emergencyFaultCodes.isNotEmpty;

  /// 是否有任一故障
  bool get hasFault =>
      hasStopFault || hasWarningFault || hasEmergencyFault;

  /// 机型标签
  String get coffeeTypeLabel => switch (coffeeType) {
        0 => 'caye',
        1 => 'BTB',
        null => '--',
        _ => '未知($coffeeType)',
      };

  /// 摘要状态标签
  String get stateLabel {
    if (hasFault) return '故障';
    if (isWetting) return '润湿中';
    if (canWet) return '可润湿';
    if (canMake) return '可制作';
    return '待机';
  }
}

/// 出餐门单门状态（DoorOut 模块 §3.11）
///
/// 用途：远程控制门开关判断、物料/光栅/防夹/电机故障展示。
class DoorStatus {
  /// 杯托在下（门开侧推断）
  final bool isOpen;

  /// 杯托在上（门关侧推断）
  final bool isClosed;

  /// 前门上限位
  final bool frontDoorUp;

  /// 前门下限位
  final bool frontDoorDown;

  /// 物料传感器有物料
  final bool hasMaterialSensor;

  /// 安全光栅触发
  final bool hasLightCurtain;

  /// 防夹手触发
  final bool hasAntiPinch;

  /// 已拿过物料
  final bool hasTakenMaterial;

  /// 杯托电机故障
  final bool hasCupFault;

  /// 前门电机故障
  final bool hasFrontFault;

  /// 杯托电机运行：0=无, 1=向上, 2=向下
  final int cupMotorRunning;

  /// 前门电机运行：0=无, 1=向上, 2=向下
  final int frontMotorRunning;

  const DoorStatus({
    required this.isOpen,
    required this.isClosed,
    required this.frontDoorUp,
    required this.frontDoorDown,
    required this.hasMaterialSensor,
    required this.hasLightCurtain,
    required this.hasAntiPinch,
    required this.hasTakenMaterial,
    required this.hasCupFault,
    required this.hasFrontFault,
    required this.cupMotorRunning,
    required this.frontMotorRunning,
  });

  /// 门状态摘要
  String get label {
    if (hasCupFault || hasFrontFault) return '故障';
    if (isOpen) return '开';
    return '关';
  }
}

/// IO 模块输入信号（IO §3.2 byte0/byte1）
///
/// 用途：水路进水/废水开关实时展示。
class IoInputSignals {
  /// 进水流量计有信号
  final bool inputFlowMeter;

  /// 进水水流开关有信号
  final bool inputWaterFlowSwitch;

  /// 废水排水水流开关有信号
  final bool wasteWaterFlowSwitch;

  /// 废水满开关
  final bool wasteWaterFullSwitch;

  const IoInputSignals({
    required this.inputFlowMeter,
    required this.inputWaterFlowSwitch,
    required this.wasteWaterFlowSwitch,
    required this.wasteWaterFullSwitch,
  });
}

/// 系统传感器/电气读数（System 模块 §3.1）
///
/// 用途：远程控制传感器区展示电压电流、温度、压力 TDS、奶路称重等。
class SensorReadings {
  /// 电压 V（×0.1）
  final double voltage;

  /// 电流 A（×0.01）
  final double current;

  /// 功率 W
  final double power;

  /// 电能 kWh（×0.01）
  final double energy;

  /// 用水量 L（float32 ×0.001）
  final double waterUsage;

  /// 底仓温度 ℃
  final int bottomTemp;

  /// 上仓温度 ℃
  final int topTemp;

  /// 冷水温度 ℃
  final int coldTemp;

  /// 冷藏箱温度 ℃
  final int coldStorageTemp;

  /// 进水温度 ℃
  final int waterInTemp;

  /// 水管表面温度 ℃
  final int waterSurfaceTemp;

  /// 进水压力 bar（×0.01）
  final double waterPressure;

  /// TDS ppm
  final int tds;

  /// 奶路称重1 g（有符号）
  final int milkWeight1;

  /// 奶路称重2 g（有符号）
  final int milkWeight2;

  /// 缺水标志 1=缺水
  final bool isWaterShortage;

  /// 拉花打印请求1
  final int lattePrintRequest1;

  /// 拉花订单号1
  final int latteOrderId1;

  /// 拉花打印请求2
  final int lattePrintRequest2;

  /// 拉花订单号2
  final int latteOrderId2;

  /// 奶箱冷藏箱温度 ℃
  final int milkBoxTemp;

  /// 系统复位状态
  final bool isReset;

  /// 订单丢杯状态：true=忙碌
  final bool isOrderDropBusy;

  const SensorReadings({
    required this.voltage,
    required this.current,
    required this.power,
    required this.energy,
    required this.waterUsage,
    required this.bottomTemp,
    required this.topTemp,
    required this.coldTemp,
    required this.coldStorageTemp,
    required this.waterInTemp,
    required this.waterSurfaceTemp,
    required this.waterPressure,
    required this.tds,
    required this.milkWeight1,
    required this.milkWeight2,
    required this.isWaterShortage,
    required this.lattePrintRequest1,
    required this.latteOrderId1,
    required this.lattePrintRequest2,
    required this.latteOrderId2,
    required this.milkBoxTemp,
    required this.isReset,
    required this.isOrderDropBusy,
  });
}

/// statusRaw 完整解析结果
///
/// 用途：MQTT statusRaw 二进制一帧解析后的聚合对象，
/// 远程控制页通过 RemoteControlService 订阅并展示。
class StatusRawData {
  /// 采集时间戳毫秒（payload 前 8 字节 BE）
  final int timestampMs;

  /// 下位机地址，固定 0x01
  final int addr;

  /// ModuleData 总字节数（帧头 DataCount，BE）
  final int dataCount;

  /// 功能码 0x03/0x04
  final int funCode;

  /// 流水码
  final int seq;

  /// 拆分后的 18 个原始模块 buffer
  final List<Uint8List> modules;

  /// 完整原始 payload
  final Uint8List rawBytes;

  /// 继电器状态（IO §3.2），key=协议索引 1-24
  final Map<int, bool>? relayStates;

  /// IO 输入信号
  final IoInputSignals? ioInputSignals;

  /// 子模块通讯状态（ModuleLink §3.3）
  final ModuleLinkStatus? moduleLinkStatus;

  /// 机械臂①
  final RobotStatus? robotArm1;

  /// 机械臂②
  final RobotStatus? robotArm2;

  /// 落杯落盖
  final CupLidStatus? cupLidStatus;

  /// 出餐门 1-4
  final Map<int, DoorStatus>? doorStates;

  /// 系统传感器
  final SensorReadings? sensorReadings;

  /// 设备型号（预留）
  final String? deviceModel;

  /// 制冰机
  final IceStatus? iceStatus;

  /// 气泡机
  final BubbleStatus? bubbleStatus;

  /// 果汁机
  final JuiceStatus? juiceStatus;

  /// 热水
  final WaterHotStatus? waterHotStatus;

  /// 丢杯口
  final DropStatus? dropStatus;

  /// 咖啡机
  final CoffeeMachineStatus? coffeeStatus;

  /// 订单制作流程
  final OrderFlowStatus? orderFlowStatus;

  /// 缓存位订单
  final CachePositionData? cachePosition;

  /// 出餐门订单（门未开）
  final DoorOutOrderData? doorOutOrder;

  /// 出餐门可取餐订单（门已开）
  final DoorOutOrderTakingData? doorOutOrderTaking;

  /// 子模块版本
  final ModuleVersions? moduleVersions;

  /// 物料库存
  final StockData? stockData;

  const StatusRawData({
    required this.timestampMs,
    required this.addr,
    required this.dataCount,
    required this.funCode,
    required this.seq,
    required this.modules,
    required this.rawBytes,
    this.relayStates,
    this.ioInputSignals,
    this.moduleLinkStatus,
    this.robotArm1,
    this.robotArm2,
    this.cupLidStatus,
    this.doorStates,
    this.sensorReadings,
    this.deviceModel,
    this.iceStatus,
    this.bubbleStatus,
    this.juiceStatus,
    this.waterHotStatus,
    this.dropStatus,
    this.coffeeStatus,
    this.orderFlowStatus,
    this.cachePosition,
    this.doorOutOrder,
    this.doorOutOrderTaking,
    this.moduleVersions,
    this.stockData,
  });

  /// 取指定模块原始数据，空或不存在返回 null
  Uint8List? moduleAt(int index) {
    if (index >= modules.length) return null;
    final m = modules[index];
    return m.isEmpty ? null : m;
  }

  /// 采集时间
  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(timestampMs);

  @override
  String toString() =>
      'StatusRawData(ts=$timestampMs, relays=${relayStates?.length ?? 0}, '
      'arm1=${robotArm1?.stateLabel}, arm2=${robotArm2?.stateLabel}, '
      'doors=${doorStates?.length ?? 0})';
}

/// 子模块通讯状态（ModuleLink §3.3）
///
/// 用途：各子设备 RS485 通讯是否正常（true=成功）。
class ModuleLinkStatus {
  /// 机械臂1 通讯正常
  final bool robotArm1;

  /// 机械臂2 通讯正常
  final bool robotArm2;

  /// 咖啡机通讯正常
  final bool coffee;

  /// 落杯1 通讯正常
  final bool cupDispenser1;

  /// 落杯2 通讯正常
  final bool cupDispenser2;

  /// 落杯3 通讯正常
  final bool cupDispenser3;

  /// 落杯4 通讯正常
  final bool cupDispenser4;

  /// 落盖1 通讯正常
  final bool lidDispenser1;

  /// 落盖2 通讯正常
  final bool lidDispenser2;

  /// 气泡机通讯正常
  final bool bubble;

  /// 冷水通讯正常
  final bool coldWater;

  /// 热水通讯正常
  final bool waterHot;

  /// 饮料机 1-4 路通讯正常
  final bool juiceGroup1;

  /// 饮料机 5-8 路通讯正常
  final bool juiceGroup2;

  /// 饮料机 9-12 路通讯正常
  final bool juiceGroup3;

  /// 出餐门1 通讯正常
  final bool door1;

  /// 出餐门2 通讯正常
  final bool door2;

  /// 出餐门3 通讯正常
  final bool door3;

  /// 出餐门4 通讯正常
  final bool door4;

  /// 丢杯口通讯正常
  final bool drop;

  /// 奶路称重通讯正常
  final bool milkScale;

  /// 制冰机通讯正常
  final bool ice;

  const ModuleLinkStatus({
    required this.robotArm1,
    required this.robotArm2,
    required this.coffee,
    required this.cupDispenser1,
    required this.cupDispenser2,
    required this.cupDispenser3,
    required this.cupDispenser4,
    required this.lidDispenser1,
    required this.lidDispenser2,
    required this.bubble,
    required this.coldWater,
    required this.waterHot,
    required this.juiceGroup1,
    required this.juiceGroup2,
    required this.juiceGroup3,
    required this.door1,
    required this.door2,
    required this.door3,
    required this.door4,
    required this.drop,
    required this.milkScale,
    required this.ice,
  });

  /// 通讯正常的模块数
  int get onlineCount => [
        robotArm1,
        robotArm2,
        coffee,
        cupDispenser1,
        cupDispenser2,
        cupDispenser3,
        cupDispenser4,
        lidDispenser1,
        lidDispenser2,
        bubble,
        coldWater,
        waterHot,
        juiceGroup1,
        juiceGroup2,
        juiceGroup3,
        door1,
        door2,
        door3,
        door4,
        drop,
        milkScale,
        ice,
      ].where((e) => e).length;

  /// 协议定义的模块总数
  int get totalCount => 22;
}

/// 单个落杯器状态（CupLid §3.5）
///
/// 用途：展示到位/缺料/成功及落杯动作状态。
class CupDispenserStatus {
  /// 到位
  final bool present;

  /// 缺料
  final bool shortage;

  /// 成功
  final bool success;

  /// 状态：0=无动作, 1=落杯中, 2=卡杯
  final int state;

  const CupDispenserStatus({
    required this.present,
    required this.shortage,
    required this.success,
    required this.state,
  });

  /// 是否卡杯
  bool get isJammed => state == 2;

  /// 是否落杯中
  bool get isDispensing => state == 1;

  /// 状态标签
  String get stateLabel => switch (state) {
        0 => '无动作',
        1 => '落杯中',
        2 => '卡杯',
        _ => '未知($state)',
      };
}

/// 单个落盖器状态（CupLid §3.5）
///
/// 用途：展示到位/缺料/成功及落盖动作状态。
class LidDispenserStatus {
  /// 到位
  final bool present;

  /// 缺料
  final bool shortage;

  /// 成功
  final bool success;

  /// 状态：0=无动作, 1=落盖中, 2=卡盖
  final int state;

  const LidDispenserStatus({
    required this.present,
    required this.shortage,
    required this.success,
    required this.state,
  });

  /// 是否卡盖
  bool get isJammed => state == 2;

  /// 是否落盖中
  bool get isDispensing => state == 1;

  /// 状态标签
  String get stateLabel => switch (state) {
        0 => '无动作',
        1 => '落盖中',
        2 => '卡盖',
        _ => '未知($state)',
      };
}

/// 落杯落盖模块汇总（CupLid §3.5）
///
/// 用途：远程控制落杯/落盖可选位与缺料判断。
class CupLidStatus {
  /// 落杯1
  final CupDispenserStatus cup1;

  /// 落杯2
  final CupDispenserStatus cup2;

  /// 落杯3
  final CupDispenserStatus cup3;

  /// 落杯4
  final CupDispenserStatus cup4;

  /// 落盖1
  final LidDispenserStatus lid1;

  /// 落盖2
  final LidDispenserStatus lid2;

  const CupLidStatus({
    required this.cup1,
    required this.cup2,
    required this.cup3,
    required this.cup4,
    required this.lid1,
    required this.lid2,
  });
}

/// 气泡机状态（Bubble §3.7）
///
/// 用途：展示缺气/缺水、脉冲剩余、当前气压与气罐气压。
class BubbleStatus {
  /// 缺气：1=缺气
  final bool co2Empty;

  /// 缺水状态：0=无动作, 1=补水中, 2=缺水
  final int waterState;

  /// 气泡水剩余脉冲
  final int bubblePulseRemain;

  /// 冷水剩余脉冲
  final int coldPulseRemain;

  /// 当前气压 bar（×0.1）
  final double pressure;

  /// 气罐当前气压 bar（×0.1）
  final double gasTankPressure;

  const BubbleStatus({
    required this.co2Empty,
    required this.waterState,
    required this.bubblePulseRemain,
    required this.coldPulseRemain,
    required this.pressure,
    required this.gasTankPressure,
  });

  /// 是否缺水
  bool get isWaterEmpty => waterState == 2;

  /// 是否补水中
  bool get isFilling => waterState == 1;

  /// 缺水状态标签
  String get waterStateLabel => switch (waterState) {
        0 => '无动作',
        1 => '补水中',
        2 => '缺水',
        _ => '未知($waterState)',
      };

  /// 摘要标签
  String get stateLabel {
    if (co2Empty) return '缺气';
    if (waterState == 2) return '缺水';
    if (waterState == 1) return '补水';
    return '正常';
  }
}

/// 果汁单路状态（Juice §3.8 每路 3 字节）
///
/// 用途：展示该路剩余脉冲与是否堵管。
class JuiceChannel {
  /// 剩余脉冲
  final int pulseRemain;

  /// 异常标记 1=管路堵
  final bool isClogged;

  const JuiceChannel({required this.pulseRemain, required this.isClogged});
}

/// 果汁机状态（Juice §3.8）
///
/// 用途：整体出料中 + 12 路状态。
class JuiceStatus {
  /// 当前状态 1=出料中
  final bool isDispensing;

  /// 管路 1-12
  final List<JuiceChannel> channels;

  const JuiceStatus({required this.isDispensing, required this.channels});

  /// 堵管路数
  int get cloggedCount => channels.where((c) => c.isClogged).length;

  /// 摘要标签
  String get stateLabel {
    if (isDispensing) return '出料中';
    if (cloggedCount > 0) return '$cloggedCount路堵塞';
    return '待机';
  }
}

/// 热水状态（WaterHot §3.9）
///
/// 用途：剩余脉冲、管路堵塞/加热故障、出水温度。
class WaterHotStatus {
  /// 出热水剩余脉冲
  final int pulseRemain;

  /// 故障 bit0：管路堵塞
  final bool isClogged;

  /// 故障 bit1：加热故障
  final bool hasHeatFault;

  /// 实际出水温度 ℃
  final int outputTemp;

  const WaterHotStatus({
    required this.pulseRemain,
    required this.isClogged,
    required this.hasHeatFault,
    required this.outputTemp,
  });

  /// 是否有故障
  bool get hasFault => isClogged || hasHeatFault;

  /// 摘要标签
  String get stateLabel {
    if (hasHeatFault) return '加热故障';
    if (isClogged) return '管路堵塞';
    return '正常';
  }
}

/// 丢杯口状态（Drop §3.10）
///
/// 用途：杯托/推杯限位、故障报警与电机运行方向。
class DropStatus {
  /// 杯托上限位
  final bool cupTrayUp;

  /// 杯托下限位
  final bool cupTrayDown;

  /// 推杯电机推限位
  final bool pushMotorFront;

  /// 推杯电机回限位
  final bool pushMotorBack;

  /// 杯托故障报警
  final bool cupTrayFault;

  /// 推杯电机故障报警
  final bool pushMotorFault;

  /// 杯托电机运行：0=无运行, 1=向上, 2=向下
  final int cupTrayMotorState;

  /// 推杯电机运行：0=无运行, 1=回, 2=推
  final int pushMotorState;

  const DropStatus({
    required this.cupTrayUp,
    required this.cupTrayDown,
    required this.pushMotorFront,
    required this.pushMotorBack,
    required this.cupTrayFault,
    required this.pushMotorFault,
    required this.cupTrayMotorState,
    required this.pushMotorState,
  });

  /// 杯托电机标签
  String get cupTrayMotorLabel => switch (cupTrayMotorState) {
        0 => '无运行',
        1 => '向上',
        2 => '向下',
        _ => '未知($cupTrayMotorState)',
      };

  /// 推杯电机标签
  String get pushMotorLabel => switch (pushMotorState) {
        0 => '无运行',
        1 => '回',
        2 => '推',
        _ => '未知($pushMotorState)',
      };

  /// 摘要标签
  String get stateLabel {
    if (cupTrayFault || pushMotorFault) return '故障';
    if (cupTrayDown) return '杯托下';
    if (cupTrayUp) return '杯托上';
    return '未知';
  }
}

/// 订单制作流程中的单笔订单（OrderFlow §3.13，每单 10 字节）
///
/// 用途：展示忙碌/错误、执行顺序、加料步骤、订单号与手臂。
class OrderFlowOrder {
  /// 忙碌状态 1=忙碌
  final bool isBusy;

  /// 错误状态 1=错误
  final bool hasError;

  /// 执行顺序 0-1000
  final int execOrder;

  /// 加料顺序：1取杯 2取冰 3果汁 4取咖啡 5取盖 6压盖 7放杯
  final int step;

  /// 服务器工单号
  final int orderId;

  /// 机械手臂 1=A 2=B
  final int arm;

  const OrderFlowOrder({
    required this.isBusy,
    required this.hasError,
    required this.execOrder,
    required this.step,
    required this.orderId,
    required this.arm,
  });

  /// 步骤标签
  String get stepLabel => switch (step) {
        1 => '取杯',
        2 => '取冰',
        3 => '果汁',
        4 => '取咖啡',
        5 => '取盖',
        6 => '压盖',
        7 => '放杯',
        _ => '未知($step)',
      };
}

/// 订单制作流程模块（OrderFlow §3.13）
///
/// 用途：缓存占用/预占用、是否允许下单/缓存单/咖啡单，以及最多 3 笔在制订单。
class OrderFlowStatus {
  /// 半成品缓存位1 占用
  final bool semiCache1;

  /// 半成品缓存位2 占用
  final bool semiCache2;

  /// 成品缓存位 占用
  final bool finishCache;

  /// 半成品缓存预占用1
  final bool semiPreOccupy1;

  /// 半成品缓存预占用2
  final bool semiPreOccupy2;

  /// 成品缓存预占用
  final bool finishPreOccupy;

  /// 允许下单 1=可
  final bool allowOrder;

  /// 允许缓存订单 1=可
  final bool allowCacheOrder;

  /// 允许咖啡订单 1=可
  final bool allowCoffeeOrder;

  /// 订单 1-3
  final List<OrderFlowOrder> orders;

  const OrderFlowStatus({
    required this.semiCache1,
    required this.semiCache2,
    required this.finishCache,
    required this.semiPreOccupy1,
    required this.semiPreOccupy2,
    required this.finishPreOccupy,
    required this.allowOrder,
    required this.allowCacheOrder,
    required this.allowCoffeeOrder,
    required this.orders,
  });

  /// 是否可接受直接订单（允许下单且允许咖啡单）
  bool get canAcceptDirect => allowOrder && allowCoffeeOrder;

  /// 是否可接受缓存订单
  bool get canAcceptStore =>
      allowOrder && allowCacheOrder && allowCoffeeOrder;
}

/// 缓存位订单列表（CachePosition §3.14）
///
/// 用途：每个槽位订单号，null 表示空位或错误位。
class CachePositionData {
  /// 槽位订单号，null=空/错误
  final List<int?> slots;

  const CachePositionData({required this.slots});

  /// 已占用槽位数
  int get occupiedCount => slots.where((s) => s != null).length;
}

/// 出餐门订单（DoorOutOrder §3.15，门未开）
///
/// 用途：点餐屏“门未开”状态，key=门号 1-based。
class DoorOutOrderData {
  /// 门号 → 订单号（null=空/错误）
  final Map<int, int?> doorOrderIds;

  const DoorOutOrderData({required this.doorOrderIds});
}

/// 出餐门可取餐订单（DoorOutOrderSupportTaking §3.16，门已开）
///
/// 用途：语音播报“门已开”状态。
class DoorOutOrderTakingData {
  /// 门号 → 订单号（null=空/错误）
  final Map<int, int?> doorOrderIds;

  const DoorOutOrderTakingData({required this.doorOrderIds});
}

/// 子模块版本号（ModuleVersion §3.17）
///
/// 用途：展示落杯/出餐门/热水/气泡/饮料机/丢杯口固件版本。
class ModuleVersions {
  /// 落杯模块1 版本
  final int cupDispenser1;

  /// 落杯模块2 版本
  final int cupDispenser2;

  /// 出餐门1 版本
  final int door1;

  /// 出餐门2 版本
  final int door2;

  /// 出餐门3 版本
  final int door3;

  /// 出餐门4 版本
  final int door4;

  /// 热水模块版本
  final int waterHot;

  /// 气泡机冷水模块版本
  final int bubble;

  /// 饮料机模块1 版本
  final int juice1;

  /// 饮料机模块2 版本
  final int juice2;

  /// 饮料机模块3 版本
  final int juice3;

  /// 丢杯口版本
  final int drop;

  const ModuleVersions({
    required this.cupDispenser1,
    required this.cupDispenser2,
    required this.door1,
    required this.door2,
    required this.door3,
    required this.door4,
    required this.waterHot,
    required this.bubble,
    required this.juice1,
    required this.juice2,
    required this.juice3,
    required this.drop,
  });
}

/// 系统物料数据（StockData §3.18）
///
/// 用途：杯盖数量、果汁克重、水桶 ml、缓存占用、用水量记录、门订单与动态缓存订单。
class StockData {
  /// 落杯 1-4 剩余数量
  final List<int> cupCounts;

  /// 落盖 1-2 剩余数量
  final List<int> lidCounts;

  /// 果汁 1-12 剩余克重
  final List<int> juiceRemains;

  /// 水桶1 剩余 ml
  final int waterTank1Ml;

  /// 水桶2 剩余 ml
  final int waterTank2Ml;

  /// 半成品缓存1 占用
  final bool semiCache1Occupied;

  /// 半成品缓存2 占用
  final bool semiCache2Occupied;

  /// 成品缓存 占用
  final bool finishCacheOccupied;

  /// 咖啡机位占用
  final bool coffeeSlotOccupied;

  /// 用水量记录
  final int waterUsage;

  /// 出餐门1 订单号
  final int door1OrderId;

  /// 出餐门2 订单号
  final int door2OrderId;

  /// 出餐门3 订单号
  final int door3OrderId;

  /// 出餐门4 订单号
  final int door4OrderId;

  /// 动态缓存订单号列表（过滤空/错误）
  final List<int> cacheOrders;

  const StockData({
    required this.cupCounts,
    required this.lidCounts,
    required this.juiceRemains,
    required this.waterTank1Ml,
    required this.waterTank2Ml,
    required this.semiCache1Occupied,
    required this.semiCache2Occupied,
    required this.finishCacheOccupied,
    required this.coffeeSlotOccupied,
    required this.waterUsage,
    required this.door1OrderId,
    required this.door2OrderId,
    required this.door3OrderId,
    required this.door4OrderId,
    required this.cacheOrders,
  });

  /// 落杯总数
  int get totalCups => cupCounts.fold(0, (a, b) => a + b);

  /// 落盖总数
  int get totalLids => lidCounts.fold(0, (a, b) => a + b);
}
