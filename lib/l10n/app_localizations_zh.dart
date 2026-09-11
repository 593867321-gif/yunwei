// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '优达客运营';

  @override
  String get loginAccountLabel => '账号';

  @override
  String get loginAccountHint => '请输入账号';

  @override
  String get loginPasswordLabel => '密码';

  @override
  String get loginPasswordHint => '请输入密码';

  @override
  String get loginButton => '登录';

  @override
  String get loginWelcomeBack => '欢迎回来';

  @override
  String get loginPleaseSignIn => '请登录以继续';

  @override
  String get loginErrorEmpty => '请输入账号和密码';

  @override
  String get loginErrorFailed => '登录失败';

  @override
  String get homePageTitle => '运维工作台';

  @override
  String homeWelcomeBack(String userName) {
    return '欢迎回来，$userName';
  }

  @override
  String homeDomainLabel(String domain) {
    return '管理域：$domain';
  }

  @override
  String get homeStatTodayOrders => '今日订单数';

  @override
  String get homeStatTodayRevenue => '今日营业额';

  @override
  String get homeStatOtherPay => '其他支付收入';

  @override
  String get homeStatBalancePay => '用户余额支付';

  @override
  String get homeStatAmountUnit => '元';

  @override
  String get homeStatOrderUnit => '单';

  @override
  String get homeDeviceStatusOnline => '在线设备';

  @override
  String get homeDeviceStatusAlert => '库存预警';

  @override
  String get homeMenuInventory => '库存管理';

  @override
  String get homeMenuScan => '扫一扫';

  @override
  String get homeMenuDevices => '设备列表';

  @override
  String get homeMenuOrders => '订单记录';

  @override
  String get homeMenuRepair => '故障维修';

  @override
  String get homeMenuReport => '报表数据';

  @override
  String get homeBusinessTitle => '业务功能';

  @override
  String get homeAlertTitle => '即时预警';

  @override
  String get homeScanFailed => '扫码失败';

  @override
  String get homeCameraPermission => '相机权限';

  @override
  String get homeSystemAdmin => '系统管理员';

  @override
  String get homeAllDevices => '全部设备';

  @override
  String get stockPageTitle => '库存管理';

  @override
  String get stockSelectDeviceFirst => '请先选择一台设备';

  @override
  String get stockSelectDeviceHint => '库存管理需要选择具体设备';

  @override
  String get stockSelectDeviceButton => '选择设备';

  @override
  String stockTotalCount(int count) {
    return '共 $count 项';
  }

  @override
  String get stockEmptyHint => '暂无库存数据';

  @override
  String get stockModeCloudCalc => '云端计算';

  @override
  String get stockModeHwCollect => '硬件采集';

  @override
  String get stockModeHwCalc => '设备计算';

  @override
  String get stockModeUnknown => '未知';

  @override
  String get stockModeInfinite => '无限';

  @override
  String get stockMaterialCup => '杯子';

  @override
  String get stockMaterialCap => '盖子';

  @override
  String get stockMaterialMilk => '牛奶';

  @override
  String get stockMaterialCoffeeBean => '咖啡豆';

  @override
  String get stockMaterialWater => '水';

  @override
  String get stockMaterialSyrup => '糖浆';

  @override
  String get stockMaterialCO2 => '二氧化碳';

  @override
  String get stockChanged => '已修改';

  @override
  String get stockNoMaterial => '未绑定物料';

  @override
  String get stockChangeMaterial => '更换物料';

  @override
  String get stockEdit => '修改库存';

  @override
  String get stockReplenish => '补货';

  @override
  String stockCurrentStock(int value, String unit) {
    return '当前库存：$value $unit';
  }

  @override
  String stockMaxStock(int value, String unit) {
    return '最大容量：$value $unit';
  }

  @override
  String get stockEditHint => '输入新的库存数量';

  @override
  String get stockReplenishHint => '输入本次补货量';

  @override
  String get stockInputHint => '请输入数量';

  @override
  String get stockOptionalHint => '选填，留空则仅记录操作';

  @override
  String get stockInvalidNumber => '请输入有效数量';

  @override
  String get stockLoadingMaterials => '加载物料列表...';

  @override
  String stockPickMaterialTitle(String type) {
    return '选择「$type」物料';
  }

  @override
  String stockCurrentMaterial(String name) {
    return '当前：$name';
  }

  @override
  String get stockCurrentMaterialNone => '无';

  @override
  String get stockNoAvailableMaterial => '无可用物料';

  @override
  String get stockUnknownMaterial => '未知物料';

  @override
  String get stockLoadMaterialsFailed => '物料加载失败，请重试';

  @override
  String get stockConfirmSubmit => '确认提交';

  @override
  String stockConfirmMessage(int count) {
    return '即将提交 $count 项库存变更，设备可能需要一定时间响应。';
  }

  @override
  String get stockSyncing => '正在同步设备库存...';

  @override
  String get stockUpdateSuccess => '库存更新成功';

  @override
  String get stockUpdateFailed => '库存更新失败';

  @override
  String stockSubmitButton(int count) {
    return '提交补货（$count项变更）';
  }

  @override
  String get stockNoChanges => '无变更项';

  @override
  String get stockUndo => '撤销';

  @override
  String get stockUnnamedComponent => '未命名组件';

  @override
  String get stockSaveMode => '保存方式';

  @override
  String get stockLevelNormal => '库存充足';

  @override
  String get stockLevelLowStock => '需补货';

  @override
  String get stockLevelSoldOut => '售罄';

  @override
  String get stockStatusRefillRecordOnly => '补货（仅记录）';

  @override
  String get stockRecordStatusModeHint => '状态值模式，仅记录流水';

  @override
  String get drawerTitle => '选择管理域';

  @override
  String get drawerSearchHint => '搜索设备名称或编号';

  @override
  String get drawerAllDevices => '全部设备';

  @override
  String get drawerDefaultOperator => '运营商';

  @override
  String get drawerDefaultStore => '店铺';

  @override
  String get drawerDefaultDevice => '设备';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确定';

  @override
  String get commonLogout => '退出登录';

  @override
  String get commonLogoutConfirm => '确认退出登录吗？';

  @override
  String get dialogScanSuccess => '扫码成功';

  @override
  String dialogScanCode(String code) {
    return '二维码秘钥：$code';
  }

  @override
  String get dialogClose => '关闭';

  @override
  String get stockRecordTitle => '库存流水记录';

  @override
  String get stockRecordAll => '全部';

  @override
  String get stockRecordRetry => '加载失败，点击重试';

  @override
  String get stockRecordEmpty => '暂无库存变动记录';

  @override
  String get deviceListTitle => '设备列表';

  @override
  String get deviceListSearchHint => '搜索设备名称/编号/型号';

  @override
  String get deviceListFilterAll => '全部';

  @override
  String get deviceListFilterOnline => '在线';

  @override
  String get deviceListFilterOffline => '离线';

  @override
  String get deviceListEmpty => '暂无设备数据';

  @override
  String deviceListAlertMore(int count) {
    return '+$count';
  }

  @override
  String deviceListTotalCount(int count) {
    return '共 $count 台设备';
  }

  @override
  String get deviceListSoldOut => '缺货';

  @override
  String get deviceListLowStock => '低库存';

  @override
  String get deviceListColdWater => '冷水';

  @override
  String get deviceListNoAlert => '无故障报警';

  @override
  String get deviceListNoStockAlert => '无预警';

  @override
  String get deviceListBtnStock => '库存';

  @override
  String get deviceListBtnStatus => '状态';

  @override
  String get deviceListBtnControl => '控制';

  @override
  String get deviceListNoUnavailable => '无不可用组件';

  @override
  String get deviceDetailTitle => '设备详情';

  @override
  String get deviceDetailSectionStatus => '运行状态';

  @override
  String get deviceDetailSectionPower => '电力参数';

  @override
  String get deviceDetailSectionTemp => '温度参数';

  @override
  String get deviceDetailSectionWater => '水路参数';

  @override
  String get deviceDetailSectionMilk => '奶路称重';

  @override
  String get deviceDetailSectionAlert => '故障告警';

  @override
  String get deviceDetailSectionStockAlert => '库存预警';

  @override
  String get deviceDetailNoData => '暂无数据';

  @override
  String get deviceDetailNormal => '正常';

  @override
  String get deviceDetailWaterShortage => '缺水';

  @override
  String get deviceDetailLabelDeviceCode => '设备编号';

  @override
  String get deviceDetailLabelModel => '设备型号';

  @override
  String get deviceOnlineEvents => '在线事件';

  @override
  String get deviceFaultHistory => '故障历史';

  @override
  String get deviceOnline => '在线';

  @override
  String get deviceOffline => '离线';

  @override
  String get alertPageTitle => '告警列表';

  @override
  String get alertFilterAll => '全部';

  @override
  String get alertFilterFault => '故障';

  @override
  String get alertFilterWarning => '告警';

  @override
  String get alertFilterStockOut => '缺货';

  @override
  String get alertStatusNew => '新告警';

  @override
  String get alertStatusAcknowledged => '已确认';

  @override
  String get alertStatusResolved => '已消除';

  @override
  String get alertTimeLabel => '时间';

  @override
  String alertOccurrenceCount(int count) {
    return '发生 $count 次';
  }

  @override
  String alertTotalCount(int count) {
    return '共 $count 条告警';
  }

  @override
  String get alertEmpty => '暂无告警记录';

  @override
  String get alertBtnAcknowledge => '确认';

  @override
  String get alertBtnResolve => '消除';

  @override
  String alertBatchTitle(int count) {
    return '已选 $count 项';
  }

  @override
  String alertBatchAcknowledgeConfirm(int count) {
    return '确认将 $count 条告警标记为已确认？';
  }

  @override
  String alertBatchResolveConfirm(int count) {
    return '确认将 $count 条告警标记为已消除？';
  }

  @override
  String get alertOperationSuccess => '操作成功';

  @override
  String get alertOperationFailed => '操作失败';

  @override
  String get alertLoadedAll => '已加载全部告警';

  @override
  String get homeAlertFaultCount => '故障';

  @override
  String get homeAlertWarningCount => '告警';

  @override
  String get homeAlertStockOutCount => '缺货';

  @override
  String get homeAlertViewAll => '查看全部';

  @override
  String get homeAlertNoAlerts => '暂无告警';

  @override
  String get orderCancelTitle => '取消工单';

  @override
  String get orderCancelForceTitle => '强制取消工单';

  @override
  String get orderCancelWarning => '制作中的工单无法确认原料是否已消耗，取消后不会退回原料库存';

  @override
  String get orderCancelRiskConfirm => '我已了解风险，确认操作';

  @override
  String get orderCancelSubmit => '取消工单已提交';

  @override
  String get orderBatchCancelTitle => '批量取消工单';

  @override
  String get orderBatchCancelSubmit => '批量取消请求已提交';

  @override
  String get orderDiscardSent => '丢杯指令已发送';

  @override
  String get orderViewStockRecords => '查看库存流水';

  @override
  String orderCancelReason(String reason) {
    return '取消原因：$reason';
  }

  @override
  String get remoteControlTitle => '远程控制';

  @override
  String get remoteControlIdle => '未控制';

  @override
  String get remoteControlControlling => '控制中';

  @override
  String get remoteControlOccupied => '已被控制';

  @override
  String get remoteControlAcquire => '申请控制权';

  @override
  String get remoteControlRelease => '释放';

  @override
  String get remoteControlStatusOverview => '设备状态总览';

  @override
  String get remoteControlOnline => '● 在线';

  @override
  String get remoteControlRunning => '运行中';

  @override
  String get remoteControlRelay => '继电器';

  @override
  String get remoteControlRobot => '机械臂';

  @override
  String get remoteControlDoorSection => '出餐门';

  @override
  String get remoteControlCupSection => '落杯';

  @override
  String get remoteControlLidSection => '落盖';

  @override
  String get remoteControlCoffeeSection => '咖啡机';

  @override
  String get remoteControlIceSection => '制冰';

  @override
  String get remoteControlJuiceSection => '果汁';

  @override
  String get remoteControlNeedControlHint => '请先申请控制权';

  @override
  String get remoteControlOpTargetArm => '目标臂';

  @override
  String get remoteControlOpActions => '动作';

  @override
  String get remoteControlOpLinkDoor => '联动';

  @override
  String get remoteControlOpCupMotor => '杯托';

  @override
  String get remoteControlOpFrontDoor => '前门';

  @override
  String get remoteControlOpMachine => '机号';

  @override
  String get remoteControlOpIceMode => '模式';

  @override
  String get remoteControlOpJuicePipe => '管路';

  @override
  String get remoteControlSensorData => '传感器数据';

  @override
  String get remoteControlSystemSection => '系统指令';

  @override
  String get remoteControlVersionSection => '固件版本';

  @override
  String get remoteControlQueryVersion => '查询版本';

  @override
  String get remoteControlExecuteClean => '执行清理';

  @override
  String get remoteControlReset => '复位';

  @override
  String get remoteControlRestart => '重启';

  @override
  String get remoteControlCleanAll => '全清';

  @override
  String get remoteControlCleanSpec => '指定';

  @override
  String get remoteControlArm1 => '① 号臂';

  @override
  String get remoteControlArm2 => '② 号臂';

  @override
  String get remoteControlNoData => '暂无数据';

  @override
  String get remoteControlTooltip => '远程控制';

  @override
  String get remoteControlRelayFan => '风扇';

  @override
  String get remoteControlRelayHeater => '加热';

  @override
  String get remoteControlRelayCooler => '制冷';

  @override
  String get remoteControlRelayLight => '照明';

  @override
  String get remoteControlRelayPump => '水泵';

  @override
  String get remoteControlRelayCompressor => '压缩机';

  @override
  String get remoteControlArmReset => '复位';

  @override
  String get remoteControlArmEnable => '上使能';

  @override
  String get remoteControlArmDisable => '下使能';

  @override
  String get remoteControlArmRun => '运行程序';

  @override
  String get remoteControlArmStop => '停止';

  @override
  String get remoteControlArmDragEnter => '进入拖拽';

  @override
  String get remoteControlArmDragExit => '退出拖拽';

  @override
  String get remoteControlArmContinue => '压盖位继续';

  @override
  String get remoteControlArmDropOrigin => '原点丢杯';

  @override
  String get remoteControlArmDropCache => '缓存丢杯';

  @override
  String get remoteControlArmDropOutlet => '出杯口丢杯';

  @override
  String get remoteControlArmSelectAction => '选择动作';

  @override
  String get remoteControlArmSelectActionHint => '请先选择机械臂动作';

  @override
  String get remoteControlArmStart => '启动';

  @override
  String get remoteControlParamNone => '不涉及';

  @override
  String get remoteControlConfirmTitle => '确认操作';

  @override
  String remoteControlConfirmMessage(String action) {
    return '确认执行「$action」？';
  }

  @override
  String get remoteControlConfirmOk => '确定';

  @override
  String get remoteControlConfirmCancel => '取消';

  @override
  String get remoteControlCoffeeBrew => '出咖啡';

  @override
  String get remoteControlCoffeeRinse => '润湿';

  @override
  String get remoteControlCupDispense => '落杯';

  @override
  String get remoteControlLidDispense => '落盖';

  @override
  String get remoteControlDoorOpen => '开门';

  @override
  String get remoteControlDoorClose => '关门';

  @override
  String get remoteControlIceStart => '启动';

  @override
  String get remoteControlIceWeightMode => '克重';

  @override
  String get remoteControlIceContinuousMode => '连续';

  @override
  String get remoteControlResetAction => '复位';

  @override
  String get remoteControlJuiceDispense => '果汁出料';

  @override
  String remoteControlJuicePipe(int pipe) {
    return '管$pipe';
  }

  @override
  String get remoteControlJuiceGramsHint => '克重';

  @override
  String get remoteControlJuiceStart => '出料';

  @override
  String get remoteControlJuiceInvalidParams => '管路或克重参数无效';

  @override
  String remoteControlCmdSuccess(String cmd) {
    return '$cmd 成功';
  }

  @override
  String remoteControlCmdFailed(String cmd, String reason) {
    return '$cmd 失败: $reason';
  }

  @override
  String get remoteControlDropParams => '丢杯定位参数';

  @override
  String get remoteControlDropTarget => '丢杯目标';

  @override
  String get remoteControlDropTargetCoffee => '咖啡位';

  @override
  String get remoteControlDropTargetCache1 => '缓存1';

  @override
  String get remoteControlDropTargetCache2 => '缓存2';

  @override
  String get remoteControlDropTargetCache3 => '缓存3';

  @override
  String get remoteControlDropCupOut => '出餐门';

  @override
  String get remoteControlDropCacheDiscard => '缓存位';

  @override
  String get remoteControlCache1 => '缓存1';

  @override
  String get remoteControlCache2 => '缓存2';

  @override
  String get remoteControlCache3 => '缓存3';

  @override
  String get remoteControlCache4 => '缓存4';

  @override
  String remoteControlCacheN(int n) {
    return '缓存$n';
  }

  @override
  String get remoteControlCleanDoor => '清理门号';

  @override
  String get remoteControlCleanCache => '清理缓存位';

  @override
  String get remoteControlCleanCacheNone => '不限缓存';

  @override
  String get remoteControlReasonNotController => '非当前控制者';

  @override
  String get remoteControlReasonOccupied => '控制权已被占用';

  @override
  String get remoteControlReasonInvalidParams => '参数无效';

  @override
  String get remoteControlReasonSlaveNoResponse => '下位机无响应';

  @override
  String get remoteControlReasonUnknownCmd => '未知指令';

  @override
  String get remoteControlReasonAckTimeout => '指令超时无响应';

  @override
  String get remoteControlForceRelease => '强制释放';

  @override
  String get remoteControlQueryControl => '查询控制权';

  @override
  String remoteControlControllerLabel(String cId) {
    return '控制者: $cId';
  }

  @override
  String remoteControlViewersLabel(String cIds) {
    return '查看者: $cIds';
  }

  @override
  String get remoteControlCupMotorOpen => '杯托开';

  @override
  String get remoteControlCupMotorClose => '杯托关';

  @override
  String get remoteControlFrontDoorOpen => '前门开';

  @override
  String get remoteControlFrontDoorClose => '前门关';

  @override
  String remoteControlCoffeeMachine(int n) {
    return '机$n';
  }

  @override
  String get remoteControlMqttOn => '本机MQTT已连';

  @override
  String get remoteControlMqttOff => '本机MQTT未连';

  @override
  String get remoteControlRelayAllOn => '全开';

  @override
  String get remoteControlRelayAllOff => '全关';

  @override
  String get remoteControlRelayTableFan => '底仓通风';

  @override
  String get remoteControlRelayCoffeePower => '咖啡机电源';

  @override
  String get remoteControlRelayIcePower => '制冰机电源';

  @override
  String get remoteControlRelayRobotPower => '机械臂电源';

  @override
  String get remoteControlRelayAirPower => '空调电源';

  @override
  String get remoteControlRelayLightPower => '照明';

  @override
  String get remoteControlRelayAdPower => '信息屏';

  @override
  String get remoteControlRelayBubblePower => '气泡机电源';

  @override
  String get remoteControlRelayWaterPumpIn => '供水泵';

  @override
  String get remoteControlRelayWaterPumpOut => '排水泵';

  @override
  String get remoteControlRelayValve1 => '进水阀1';

  @override
  String get remoteControlRelayValve2 => '进水阀2';

  @override
  String get remoteControlRelayValve3 => '进水阀3';

  @override
  String get remoteControlRelayJuiceFan => '果汁散热风扇';

  @override
  String get remoteControlRelayWaterWaste => '排废水阀';

  @override
  String get remoteControlRelayDxkw => '电伴热';

  @override
  String get remoteControlRelayLightColor => '七彩灯';

  @override
  String get remoteControlSensorVoltage => '电压';

  @override
  String get remoteControlSensorCurrent => '电流';

  @override
  String get remoteControlSensorPower => '功率';

  @override
  String get remoteControlSensorBottomTemp => '底仓温度';

  @override
  String get remoteControlSensorTopTemp => '上仓温度';

  @override
  String get remoteControlSensorColdTemp => '冷水温度';

  @override
  String get remoteControlSensorIceTemp => '冰藏温度';

  @override
  String get remoteControlSensorWaterUsage => '用水量';

  @override
  String get remoteControlSensorWaterPressure => '水压';

  @override
  String get remoteControlSensorTDS => 'TDS';

  @override
  String get remoteControlSensorWaterShortage => '缺水';

  @override
  String get remoteControlDoor1 => '门1';

  @override
  String get remoteControlDoor2 => '门2';

  @override
  String get remoteControlDoor3 => '门3';

  @override
  String get remoteControlDoor4 => '门4';

  @override
  String get remoteControlCupPos1 => '落杯位1';

  @override
  String get remoteControlCupPos2 => '落杯位2';

  @override
  String get remoteControlLidPos1 => '落盖位1';

  @override
  String get remoteControlLidPos2 => '落盖位2';

  @override
  String get remoteControlCupLidCup => '杯位';

  @override
  String get remoteControlCupLidLid => '盖位';

  @override
  String get remoteControlCupLidPresent => '在位';

  @override
  String get remoteControlCupLidEmpty => '缺料';

  @override
  String get remoteControlCupLidFault => '故障';

  @override
  String get remoteControlStockCups => '杯子余量';

  @override
  String get remoteControlStockLids => '杯盖余量';

  @override
  String get remoteControlStockJuice => '果汁余量';

  @override
  String get remoteControlStockWater => '水桶余量';

  @override
  String remoteControlStockJuiceChannel(Object ch) {
    return '管路$ch';
  }

  @override
  String get remoteControlBubble => '气泡机';

  @override
  String get remoteControlJuice => '果汁机';

  @override
  String get remoteControlWaterHot => '热水';

  @override
  String get remoteControlDrop => '丢杯口';

  @override
  String get remoteControlOrderFlow => '订单流程';

  @override
  String get remoteControlCache => '缓存位';

  @override
  String get remoteControlDoorOrder => '出餐门订单';

  @override
  String get remoteControlModuleLink => '模块通讯';

  @override
  String remoteControlModuleOnline(Object n, Object total) {
    return '$n/$total 在线';
  }

  @override
  String get pushFaultAlertTitle => '[故障]';

  @override
  String get pushWarningAlertTitle => '[告警]';

  @override
  String get pushStockOutAlertTitle => '[缺货]';

  @override
  String get pushAlertResolvedTitle => '[已恢复]';

  @override
  String get pushNotificationPermissionDenied => '通知权限已被永久拒绝';

  @override
  String get pushNotificationPermissionGuide => '请前往系统设置开启通知权限';

  @override
  String get pushNotificationPermissionOpenSettings => '去设置';

  @override
  String get networkTimeout => '网络连接超时，请检查网络设置';

  @override
  String get networkBadCertificate => '网络证书校验失败';

  @override
  String get networkError400 => '错误的请求 (400)';

  @override
  String get networkError401 => '登录已过期，请重新登录';

  @override
  String get networkError403 => '拒绝访问 (403)';

  @override
  String get networkError404 => '请求资源不存在 (404)';

  @override
  String get networkError500 => '服务器内部错误 (500)';

  @override
  String get networkError502 => '服务器正在维护或网关错误 (502)';

  @override
  String get networkError503 => '服务暂时不可用 (503)';

  @override
  String networkErrorDefault(int code) {
    return '服务器响应异常 ($code)';
  }

  @override
  String get networkRequestCancelled => '请求已取消';

  @override
  String get networkConnectionError => '无法连接到服务器，请检查网络';

  @override
  String get networkSocketError => '网络不可用，请检查连接';

  @override
  String get networkUnknownError => '未知网络错误';

  @override
  String get networkRequestFailed => '网络请求失败，请稍后重试';

  @override
  String get authExpired => '登录已过期，请重新登录';
}
