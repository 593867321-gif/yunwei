// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Youdake Operation';

  @override
  String get loginAccountLabel => 'Account';

  @override
  String get loginAccountHint => 'Please enter account';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginPasswordHint => 'Please enter password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginWelcomeBack => 'Welcome Back';

  @override
  String get loginPleaseSignIn => 'Please sign in to continue';

  @override
  String get loginErrorEmpty => 'Please enter account and password';

  @override
  String get loginErrorFailed => 'Login failed';

  @override
  String get homePageTitle => 'Operations';

  @override
  String homeWelcomeBack(String userName) {
    return 'Welcome back, $userName';
  }

  @override
  String homeDomainLabel(String domain) {
    return 'Domain: $domain';
  }

  @override
  String get homeStatTodayOrders => 'Today Orders';

  @override
  String get homeStatTodayRevenue => 'Today Revenue';

  @override
  String get homeStatOtherPay => 'Other Payment';

  @override
  String get homeStatBalancePay => 'Balance Payment';

  @override
  String get homeStatAmountUnit => ' CNY';

  @override
  String get homeStatOrderUnit => 'orders';

  @override
  String get homeDeviceStatusOnline => 'Online Devices';

  @override
  String get homeDeviceStatusAlert => 'Stock Alert';

  @override
  String get homeMenuInventory => 'Inventory';

  @override
  String get homeMenuScan => 'Scan';

  @override
  String get homeMenuDevices => 'Devices';

  @override
  String get homeMenuOrders => 'Orders';

  @override
  String get homeMenuRepair => 'Repair';

  @override
  String get homeMenuReport => 'Reports';

  @override
  String get homeBusinessTitle => 'Business';

  @override
  String get homeAlertTitle => 'Alerts';

  @override
  String get homeScanFailed => 'Scan failed';

  @override
  String get homeCameraPermission => 'Camera';

  @override
  String get homeSystemAdmin => 'Administrator';

  @override
  String get homeAllDevices => 'All Devices';

  @override
  String get stockPageTitle => 'Inventory';

  @override
  String get stockSelectDeviceFirst => 'Please select a device';

  @override
  String get stockSelectDeviceHint =>
      'Inventory management requires selecting a device';

  @override
  String get stockSelectDeviceButton => 'Select Device';

  @override
  String stockTotalCount(int count) {
    return '$count items';
  }

  @override
  String get stockEmptyHint => 'No inventory data';

  @override
  String get stockModeCloudCalc => 'Cloud Calc';

  @override
  String get stockModeHwCollect => 'HW Collect';

  @override
  String get stockModeHwCalc => 'HW Calc';

  @override
  String get stockModeUnknown => 'Unknown';

  @override
  String get stockModeInfinite => 'Infinite';

  @override
  String get stockMaterialCup => 'Cup';

  @override
  String get stockMaterialCap => 'Cap';

  @override
  String get stockMaterialMilk => 'Milk';

  @override
  String get stockMaterialCoffeeBean => 'Coffee Bean';

  @override
  String get stockMaterialWater => 'Water';

  @override
  String get stockMaterialSyrup => 'Syrup';

  @override
  String get stockMaterialCO2 => 'CO2';

  @override
  String get stockChanged => 'Modified';

  @override
  String get stockNoMaterial => 'No Material';

  @override
  String get stockChangeMaterial => 'Change';

  @override
  String get stockEdit => 'Edit Stock';

  @override
  String get stockReplenish => 'Replenish';

  @override
  String stockCurrentStock(int value, String unit) {
    return 'Current: $value $unit';
  }

  @override
  String stockMaxStock(int value, String unit) {
    return 'Max: $value $unit';
  }

  @override
  String get stockEditHint => 'Enter new stock quantity';

  @override
  String get stockReplenishHint => 'Enter replenish quantity';

  @override
  String get stockInputHint => 'Enter quantity';

  @override
  String get stockOptionalHint => 'Optional, leave blank to record only';

  @override
  String get stockInvalidNumber => 'Please enter valid quantity';

  @override
  String get stockLoadingMaterials => 'Loading materials...';

  @override
  String stockPickMaterialTitle(String type) {
    return 'Select $type';
  }

  @override
  String stockCurrentMaterial(String name) {
    return 'Current: $name';
  }

  @override
  String get stockCurrentMaterialNone => 'None';

  @override
  String get stockNoAvailableMaterial => 'No available materials';

  @override
  String get stockUnknownMaterial => 'Unknown Material';

  @override
  String get stockLoadMaterialsFailed =>
      'Failed to load materials, please retry';

  @override
  String get stockConfirmSubmit => 'Confirm';

  @override
  String stockConfirmMessage(int count) {
    return 'About to submit $count stock changes. The device may take some time to respond.';
  }

  @override
  String get stockSyncing => 'Syncing device stock...';

  @override
  String get stockUpdateSuccess => 'Stock updated';

  @override
  String get stockUpdateFailed => 'Stock update failed';

  @override
  String stockSubmitButton(int count) {
    return 'Submit ($count changes)';
  }

  @override
  String get stockNoChanges => 'No Changes';

  @override
  String get stockUndo => 'Undo';

  @override
  String get stockUnnamedComponent => 'Unnamed';

  @override
  String get stockSaveMode => 'Save Mode';

  @override
  String get stockLevelNormal => 'Normal';

  @override
  String get stockLevelLowStock => 'Low Stock';

  @override
  String get stockLevelSoldOut => 'Sold Out';

  @override
  String get stockStatusRefillRecordOnly => 'Record Only';

  @override
  String get stockRecordStatusModeHint => 'Status mode, record only';

  @override
  String get drawerTitle => 'Select Domain';

  @override
  String get drawerSearchHint => 'Search device name or code';

  @override
  String get drawerAllDevices => 'All Devices';

  @override
  String get drawerDefaultOperator => 'Operator';

  @override
  String get drawerDefaultStore => 'Store';

  @override
  String get drawerDefaultDevice => 'Device';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonLogout => 'Logout';

  @override
  String get commonLogoutConfirm => 'Are you sure you want to logout?';

  @override
  String get dialogScanSuccess => 'Scan Success';

  @override
  String dialogScanCode(String code) {
    return 'QR Code: $code';
  }

  @override
  String get dialogClose => 'Close';

  @override
  String get stockRecordTitle => 'Stock Records';

  @override
  String get stockRecordAll => 'All';

  @override
  String get stockRecordRetry => 'Load failed, tap to retry';

  @override
  String get stockRecordEmpty => 'No stock records';

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
  String get remoteControlTitle => 'Remote Control';

  @override
  String get remoteControlIdle => 'Not Controlled';

  @override
  String get remoteControlControlling => 'Controlling';

  @override
  String get remoteControlOccupied => 'Occupied';

  @override
  String get remoteControlAcquire => 'Acquire Control';

  @override
  String get remoteControlRelease => 'Release';

  @override
  String get remoteControlStatusOverview => 'Device Status';

  @override
  String get remoteControlOnline => '● Online';

  @override
  String get remoteControlRunning => 'Running';

  @override
  String get remoteControlRelay => 'Relays';

  @override
  String get remoteControlRobot => 'Robot Arm';

  @override
  String get remoteControlDoorSection => 'Serving door';

  @override
  String get remoteControlCupSection => 'Cup dispense';

  @override
  String get remoteControlLidSection => 'Lid dispense';

  @override
  String get remoteControlCoffeeSection => 'Coffee';

  @override
  String get remoteControlIceSection => 'Ice';

  @override
  String get remoteControlJuiceSection => 'Juice';

  @override
  String get remoteControlNeedControlHint => 'Acquire control first';

  @override
  String get remoteControlOpTargetArm => 'Target arm';

  @override
  String get remoteControlOpActions => 'Actions';

  @override
  String get remoteControlOpLinkDoor => 'Linked door';

  @override
  String get remoteControlOpCupMotor => 'Cup motor';

  @override
  String get remoteControlOpFrontDoor => 'Front door';

  @override
  String get remoteControlOpMachine => 'Machine';

  @override
  String get remoteControlOpIceMode => 'Mode';

  @override
  String get remoteControlOpJuicePipe => 'Pipe';

  @override
  String get remoteControlSensorData => 'Sensor Data';

  @override
  String get remoteControlSystemSection => 'System';

  @override
  String get remoteControlVersionSection => 'Firmware Version';

  @override
  String get remoteControlQueryVersion => 'Query Version';

  @override
  String get remoteControlExecuteClean => 'Execute Clean';

  @override
  String get remoteControlReset => 'Reset';

  @override
  String get remoteControlRestart => 'Restart';

  @override
  String get remoteControlCleanAll => 'All';

  @override
  String get remoteControlCleanSpec => 'Specific';

  @override
  String get remoteControlArm1 => 'Arm ①';

  @override
  String get remoteControlArm2 => 'Arm ②';

  @override
  String get remoteControlNoData => 'No data';

  @override
  String get remoteControlTooltip => 'Remote Control';

  @override
  String get remoteControlRelayFan => 'Fan';

  @override
  String get remoteControlRelayHeater => 'Heater';

  @override
  String get remoteControlRelayCooler => 'Cooler';

  @override
  String get remoteControlRelayLight => 'Light';

  @override
  String get remoteControlRelayPump => 'Water Pump';

  @override
  String get remoteControlRelayCompressor => 'Compressor';

  @override
  String get remoteControlArmReset => 'Reset';

  @override
  String get remoteControlArmEnable => 'Enable';

  @override
  String get remoteControlArmDisable => 'Disable';

  @override
  String get remoteControlArmRun => 'Run Program';

  @override
  String get remoteControlArmStop => 'Stop';

  @override
  String get remoteControlArmDragEnter => 'Enter Drag';

  @override
  String get remoteControlArmDragExit => 'Exit Drag';

  @override
  String get remoteControlArmContinue => 'Continue Press';

  @override
  String get remoteControlArmDropOrigin => 'Drop at Origin';

  @override
  String get remoteControlArmDropCache => 'Drop at Cache';

  @override
  String get remoteControlArmDropOutlet => 'Drop at Outlet';

  @override
  String get remoteControlArmSelectAction => 'Select action';

  @override
  String get remoteControlArmSelectActionHint => 'Select a robot action first';

  @override
  String get remoteControlArmStart => 'Start';

  @override
  String get remoteControlParamNone => 'None';

  @override
  String get remoteControlConfirmTitle => 'Confirm';

  @override
  String remoteControlConfirmMessage(String action) {
    return 'Execute “$action”?';
  }

  @override
  String get remoteControlConfirmOk => 'OK';

  @override
  String get remoteControlConfirmCancel => 'Cancel';

  @override
  String get remoteControlCoffeeBrew => 'Brew Coffee';

  @override
  String get remoteControlCoffeeRinse => 'Rinse';

  @override
  String get remoteControlCupDispense => 'Dispense Cup';

  @override
  String get remoteControlLidDispense => 'Dispense Lid';

  @override
  String get remoteControlDoorOpen => 'Open Door';

  @override
  String get remoteControlDoorClose => 'Close Door';

  @override
  String get remoteControlIceStart => 'Start';

  @override
  String get remoteControlIceWeightMode => 'By Weight';

  @override
  String get remoteControlIceContinuousMode => 'Continuous';

  @override
  String get remoteControlResetAction => 'Reset';

  @override
  String get remoteControlJuiceDispense => 'Juice Dispense';

  @override
  String remoteControlJuicePipe(int pipe) {
    return 'Pipe $pipe';
  }

  @override
  String get remoteControlJuiceGramsHint => 'grams';

  @override
  String get remoteControlJuiceStart => 'Dispense';

  @override
  String get remoteControlJuiceInvalidParams => 'Invalid pipe or grams';

  @override
  String remoteControlCmdSuccess(String cmd) {
    return '$cmd succeeded';
  }

  @override
  String remoteControlCmdFailed(String cmd, String reason) {
    return '$cmd failed: $reason';
  }

  @override
  String get remoteControlDropParams => 'Drop positioning';

  @override
  String get remoteControlDropTarget => 'Drop target';

  @override
  String get remoteControlDropTargetCoffee => 'Coffee';

  @override
  String get remoteControlDropTargetCache1 => 'Cache1';

  @override
  String get remoteControlDropTargetCache2 => 'Cache2';

  @override
  String get remoteControlDropTargetCache3 => 'Cache3';

  @override
  String get remoteControlDropCupOut => 'Door out';

  @override
  String get remoteControlDropCacheDiscard => 'Cache slot';

  @override
  String get remoteControlCache1 => 'Cache1';

  @override
  String get remoteControlCache2 => 'Cache2';

  @override
  String get remoteControlCache3 => 'Cache3';

  @override
  String get remoteControlCache4 => 'Cache4';

  @override
  String remoteControlCacheN(int n) {
    return 'Cache$n';
  }

  @override
  String get remoteControlCleanDoor => 'Clean door';

  @override
  String get remoteControlCleanCache => 'Clean cache';

  @override
  String get remoteControlCleanCacheNone => 'Any cache';

  @override
  String get remoteControlReasonNotController => 'Not controller';

  @override
  String get remoteControlReasonOccupied => 'Control occupied';

  @override
  String get remoteControlReasonInvalidParams => 'Invalid params';

  @override
  String get remoteControlReasonSlaveNoResponse => 'Slave no response';

  @override
  String get remoteControlReasonUnknownCmd => 'Unknown command';

  @override
  String get remoteControlReasonAckTimeout => 'Command timeout';

  @override
  String get remoteControlForceRelease => 'Force release';

  @override
  String get remoteControlQueryControl => 'Query control';

  @override
  String remoteControlControllerLabel(String cId) {
    return 'Controller: $cId';
  }

  @override
  String remoteControlViewersLabel(String cIds) {
    return 'Viewers: $cIds';
  }

  @override
  String get remoteControlCupMotorOpen => 'Cup open';

  @override
  String get remoteControlCupMotorClose => 'Cup close';

  @override
  String get remoteControlFrontDoorOpen => 'Front open';

  @override
  String get remoteControlFrontDoorClose => 'Front close';

  @override
  String remoteControlCoffeeMachine(int n) {
    return 'M$n';
  }

  @override
  String get remoteControlMqttOn => 'App MQTT on';

  @override
  String get remoteControlMqttOff => 'App MQTT off';

  @override
  String get remoteControlRelayAllOn => 'All on';

  @override
  String get remoteControlRelayAllOff => 'All off';

  @override
  String get remoteControlRelayTableFan => 'Table fan';

  @override
  String get remoteControlRelayCoffeePower => 'Coffee power';

  @override
  String get remoteControlRelayIcePower => 'Ice power';

  @override
  String get remoteControlRelayRobotPower => 'Robot power';

  @override
  String get remoteControlRelayAirPower => 'Air power';

  @override
  String get remoteControlRelayLightPower => 'Light';

  @override
  String get remoteControlRelayAdPower => 'Ad screen';

  @override
  String get remoteControlRelayBubblePower => 'Bubble power';

  @override
  String get remoteControlRelayWaterPumpIn => 'Inlet pump';

  @override
  String get remoteControlRelayWaterPumpOut => 'Drain pump';

  @override
  String get remoteControlRelayValve1 => 'Inlet valve1';

  @override
  String get remoteControlRelayValve2 => 'Inlet valve2';

  @override
  String get remoteControlRelayValve3 => 'Inlet valve3';

  @override
  String get remoteControlRelayJuiceFan => 'Juice fan';

  @override
  String get remoteControlRelayWaterWaste => 'Waste valve';

  @override
  String get remoteControlRelayDxkw => 'Heat cable';

  @override
  String get remoteControlRelayLightColor => 'RGB light';

  @override
  String get remoteControlSensorVoltage => 'Voltage';

  @override
  String get remoteControlSensorCurrent => 'Current';

  @override
  String get remoteControlSensorPower => 'Power';

  @override
  String get remoteControlSensorBottomTemp => 'Bottom Temp';

  @override
  String get remoteControlSensorTopTemp => 'Top Temp';

  @override
  String get remoteControlSensorColdTemp => 'Cold Water Temp';

  @override
  String get remoteControlSensorIceTemp => 'Ice Box Temp';

  @override
  String get remoteControlSensorWaterUsage => 'Water Usage';

  @override
  String get remoteControlSensorWaterPressure => 'Water Pressure';

  @override
  String get remoteControlSensorTDS => 'TDS';

  @override
  String get remoteControlSensorWaterShortage => 'Water Shortage';

  @override
  String get remoteControlDoor1 => 'Door 1';

  @override
  String get remoteControlDoor2 => 'Door 2';

  @override
  String get remoteControlDoor3 => 'Door 3';

  @override
  String get remoteControlDoor4 => 'Door 4';

  @override
  String get remoteControlCupPos1 => 'Cup Pos 1';

  @override
  String get remoteControlCupPos2 => 'Cup Pos 2';

  @override
  String get remoteControlLidPos1 => 'Lid Pos 1';

  @override
  String get remoteControlLidPos2 => 'Lid Pos 2';

  @override
  String get remoteControlCupLidCup => 'Cup';

  @override
  String get remoteControlCupLidLid => 'Lid';

  @override
  String get remoteControlCupLidPresent => 'Present';

  @override
  String get remoteControlCupLidEmpty => 'Empty';

  @override
  String get remoteControlCupLidFault => 'Fault';

  @override
  String get remoteControlStockCups => 'Cups';

  @override
  String get remoteControlStockLids => 'Lids';

  @override
  String get remoteControlStockJuice => 'Juice';

  @override
  String get remoteControlStockWater => 'Water Tanks';

  @override
  String remoteControlStockJuiceChannel(Object ch) {
    return 'Channel $ch';
  }

  @override
  String get remoteControlBubble => 'Bubble';

  @override
  String get remoteControlJuice => 'Juice';

  @override
  String get remoteControlWaterHot => 'Hot Water';

  @override
  String get remoteControlDrop => 'Drop';

  @override
  String get remoteControlOrderFlow => 'Order Flow';

  @override
  String get remoteControlCache => 'Cache';

  @override
  String get remoteControlDoorOrder => 'Door Orders';

  @override
  String get remoteControlModuleLink => 'Module Link';

  @override
  String remoteControlModuleOnline(Object n, Object total) {
    return '$n/$total Online';
  }

  @override
  String get pushFaultAlertTitle => '[Fault]';

  @override
  String get pushWarningAlertTitle => '[Warning]';

  @override
  String get pushStockOutAlertTitle => '[Stock Out]';

  @override
  String get pushAlertResolvedTitle => '[Resolved]';

  @override
  String get pushNotificationPermissionDenied =>
      'Notification permission permanently denied';

  @override
  String get pushNotificationPermissionGuide =>
      'Please open system settings to enable notification permission';

  @override
  String get pushNotificationPermissionOpenSettings => 'Open Settings';

  @override
  String get networkTimeout =>
      'Network connection timeout, please check your network';

  @override
  String get networkBadCertificate => 'Certificate verification failed';

  @override
  String get networkError400 => 'Bad Request (400)';

  @override
  String get networkError401 => 'Login expired, please sign in again';

  @override
  String get networkError403 => 'Access Denied (403)';

  @override
  String get networkError404 => 'Resource Not Found (404)';

  @override
  String get networkError500 => 'Internal Server Error (500)';

  @override
  String get networkError502 => 'Server Maintenance or Gateway Error (502)';

  @override
  String get networkError503 => 'Service Temporarily Unavailable (503)';

  @override
  String networkErrorDefault(int code) {
    return 'Server Response Error ($code)';
  }

  @override
  String get networkRequestCancelled => 'Request Cancelled';

  @override
  String get networkConnectionError =>
      'Cannot connect to server, please check network';

  @override
  String get networkSocketError =>
      'Network unavailable, please check connection';

  @override
  String get networkUnknownError => 'Unknown network error';

  @override
  String get networkRequestFailed =>
      'Network request failed, please retry later';

  @override
  String get authExpired => 'Login expired, please sign in again';
}
