import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/Const.dart';
import 'package:operation/ext/domain_cache.dart';
import 'package:operation/ext/enums.dart';
import 'package:operation/ext/util_permission.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/api_alert.dart';
import 'package:operation/net/api_request.dart';
import 'package:operation/net/api_response.dart';
import 'package:operation/net/mqtt_alert_handler.dart';
import 'package:operation/net/mqtt_manager.dart';
import 'package:operation/net/request_server.dart';
import 'package:operation/page/page_alert.dart';
import 'package:operation/page/page_device.dart';
import 'package:operation/page/page_login.dart';
import 'package:operation/page/page_order.dart';
import 'package:operation/page/page_scan.dart';
import 'package:operation/page/page_stock.dart';
import 'package:operation/widget/widet_dialog.dart';
import 'package:operation/widget/widget_device_drawer.dart';
import 'package:operation/ext/app_keys.dart';
import 'package:operation/services/push_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// author: wang   2026/4/17
class HomePage extends StatefulWidget {
  /// 是否为 Android Studio Widget Preview 预览实例
  final bool previewMode;

  const HomePage(bool isFirst, {super.key, this.previewMode = false});

  @Preview(name: '首页', group: '页面', size: Size(390, 844), wrapper: HomePage.previewWrapper)
  static Widget preview() => const HomePage(false, previewMode: true);

  /// 为首页预览提供主题与国际化环境
  static Widget previewWrapper(Widget child) {
    return MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  static void actionStart() {
    RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(builder: (context) => HomePage(false)));
  }

  static void pushReplacement({bool? isFirst = false}) {
    RouterUtil.clear();
    RouterUtil.navigatorKey.currentState?.pushReplacement(MaterialPageRouteLifecycle(builder: (context) => HomePage(isFirst == true)));
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 用于打开管理域选择侧边抽屉
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  OperationDashboardVo? _dashboardData;
  List<OperationOperatorVo> _operators = [];
  late DeviceSelection _selectedDomain;
  bool _domainInitialized = false;
  AlertCountVo? _alertCount;

  /// 首页数据自动刷新定时器（每 1 分钟刷新一次看板与告警数据）
  Timer? _autoRefreshTimer;
  /// 自动刷新间隔：1 分钟
  static const Duration _autoRefreshInterval = Duration(minutes: 1);
  /// 是否有自动刷新正在进行中，避免慢网络下请求堆积触发后端限流
  bool _autoRefreshInFlight = false;

  @override
  void initState() {
    super.initState();
    final cached = DomainCache.current;
    _selectedDomain = cached ?? const DeviceSelection(label: "全部设备");
    if (widget.previewMode) return;
    _loadDashboard();
    _loadDevices();
    _loadAlertCount();
    _connectMqtt();
    _registerAlertHandler();
    // 启动首页数据的周期自动刷新
    _startAutoRefresh();
  }

  @override
  void dispose() {
    // 关键步骤：必须停止定时器，否则页面销毁后仍会触发回调，造成 setState 异常与请求泄漏
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    // 移除 MQTT 告警监听，与 initState 中的 addListener 配对，避免监听器泄漏
    MqttAlertHandler.instance.removeListener(_onAlertNotify);
    super.dispose();
  }

  /// 启动首页自动刷新：每 [_autoRefreshInterval] 静默刷新看板与告警数据
  /// 只刷新数据、不刷新设备树，避免频繁拉取整棵设备树；不显示 loading，不打扰用户操作。
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) async {
      // 页面已销毁则停止
      if (!mounted) {
        timer.cancel();
        return;
      }
      // 上一次刷新尚未返回则跳过本次，避免请求堆积
      if (_autoRefreshInFlight) return;
      _autoRefreshInFlight = true;
      try {
        await _loadDashboard(silent: true);
        // _loadAlertCount 本身即静默实现（内部 try/catch + errorShow:false），无需传参
        await _loadAlertCount();
      } finally {
        _autoRefreshInFlight = false;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Localizations 就绪后，用国际化文本更新默认管理域标签
    if (!_domainInitialized && _selectedDomain.label == "全部设备") {
      _domainInitialized = true;
      final l10n = AppLocalizations.of(context);
      _selectedDomain = DeviceSelection(label: l10n.homeAllDevices);
    }
  }

  Future<void> _connectMqtt() async {
    if (MqttManager.instance.isConnected) return;
    try {
      final response = await ApiServer.instance.operationMqttInfo();
      final info = response?.take();
      if (info != null) {
        await MqttManager.instance.connect(info);
        _subscribeAlertTopic(info);
      }
    } catch (_) {}
  }

  void _subscribeAlertTopic(MqttInfoVo info) {
    final groupId = info.groupId;
    if (groupId == null) return;
    LoginCache.getUserId().then((userId) {
      if (userId == null) return;
      final topic = '$groupId/alert/$userId';
      MqttManager.instance.subscribe(topic);
    });
  }

  void _registerAlertHandler() {
    MqttManager.instance.onMessage(_onMqttMessage);
    MqttAlertHandler.instance.addListener(_onAlertNotify);
  }

  void _onMqttMessage(
    String topic,
    String payload,
    Map<String, String> userProperties,
  ) {
    MqttAlertHandler.instance.handleMessage(topic, payload);
  }

  void _onAlertNotify(MqttAlertBean bean) {
    _loadAlertCount();
  }

  /// 加载首页看板数据
  /// [silent] 为 true 时静默加载：不显示 loading、不弹错误 toast，用于周期自动刷新，避免打扰用户
  Future<void> _loadDashboard({bool silent = false}) async {
    final body = DashboardRequestBody(operatorId: _selectedDomain.operatorId, storeId: _selectedDomain.storeId, deviceId: _selectedDomain.deviceId);
    if (silent) {
      // 自动刷新路径：自行捕获异常，失败时保留上一次数据，不弹任何提示
      try {
        final response = await ApiServer.instance.dashboard(body);
        final data = response?.take(errorShow: false);
        if (mounted && data != null) {
          setState(() => _dashboardData = data);
        }
      } catch (_) {}
      return;
    }
    await jobIO(() async {
      final response = await ApiServer.instance.dashboard(body);
      final data = response?.take();
      if (mounted) {
        setState(() => _dashboardData = data);
      }
    }, onFinally: () => EasyLoading.dismiss(), toastEnable: true);
  }

  Future<void> _loadDevices() async {
    try {
      final response = await ApiServer.instance.devices();
      final data = response?.take();
      if (mounted && data != null) {
        setState(() => _operators = data);
      }
    } catch (_) {}
  }

  Future<void> _loadAlertCount() async {
    try {
      final response = await ApiServer.instance.alertCount();
      final data = response?.take(errorShow: false);
      if (mounted && data != null) {
        setState(() => _alertCount = data);
      }
    } catch (_) {}
  }

  /// 下拉刷新首页数据
  Future<void> _onRefresh() async {
    await Future.wait([_loadDashboard(), _loadDevices(), _loadAlertCount()]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      drawerEnableOpenDragGesture: false,
      endDrawerEnableOpenDragGesture: false,
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.82,
        child: SafeArea(
          child: DeviceTreeView(
            operators: _operators,
            selected: _selectedDomain,
            onSelected: (selection) {
              setState(() => _selectedDomain = selection);
              DomainCache.update(selection);
              _loadDashboard();
              _loadAlertCount();
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF1E293B),
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [
            _buildHeader(l10n),
            _BusinessSection(onMenuTap: _onClick),
            _buildAlertSection(l10n),
            const SizedBox(height: 100),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 80),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)], begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(l10n.homePageTitle, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ]),
              Text(l10n.homeWelcomeBack(_dashboardData?.userName ?? l10n.homeSystemAdmin), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              GestureDetector(
                key: AppKeys.homeDomainLabel,
                onTap: _openDomainDrawer,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(l10n.homeDomainLabel(_selectedDomain.label), style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFFCBD5E1)),
                ]),
              ),
            ]),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Stack(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.notifications_none, color: Colors.white, size: 24)),
            ]),
            const SizedBox(width: 8),
            GestureDetector(
              key: AppKeys.homeLogoutButton,
              onTap: _onLogout,
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.logout, color: Colors.white, size: 24)),
            ),
          ]),
        ]),
        const SizedBox(height: 24),
        // 统计区：左卡「今日订单数（订单/工单）+ 今日营业额」，右卡「实收构成（其他支付 / 余额支付）」
        // 关键步骤：所有金额均为实收口径（后端已扣除退款），且今日营业额 = 其他支付收入 + 用户余额支付
        // 关键步骤：不能使用 CrossAxisAlignment.stretch —— 外层是 SingleChildScrollView 内的
        // Column，垂直方向约束无界，stretch 会触发 RenderBox was not laid out 断言。
        // 两张卡片结构完全相同（图标 + 两组指标），高度天然一致，无需拉伸对齐。
        Row(children: [
          _StatCard(
            icon: Icons.trending_up,
            children: [
              _MetricRow(label: l10n.homeStatTodayOrders, value: _orderItemText(), unit: l10n.homeStatOrderUnit),
              const SizedBox(height: 10),
              _MetricRow(label: l10n.homeStatTodayRevenue, value: _moneyText(_dashboardData?.todayRevenue), unit: l10n.homeStatAmountUnit),
            ],
          ),
          const SizedBox(width: 12),
          _StatCard(
            icon: Icons.account_balance_wallet_outlined,
            children: [
              _MetricRow(label: l10n.homeStatOtherPay, value: _moneyText(_dashboardData?.todayOtherPayRevenue), unit: l10n.homeStatAmountUnit),
              const SizedBox(height: 10),
              _MetricRow(label: l10n.homeStatBalancePay, value: _moneyText(_dashboardData?.todayBalanceRevenue), unit: l10n.homeStatAmountUnit),
            ],
          ),
        ]),
        const SizedBox(height: 20),
        _buildDeviceStatusCard(l10n),
      ]),
    );
  }

  /// 订单数 / 工单数 文本，如 "12/40"
  String _orderItemText() {
    final d = _dashboardData;
    if (d == null) return "-";
    return "${d.todayOrderCount ?? '-'}/${d.todayItemCount ?? '-'}";
  }

  /// 金额文本：保留一位小数（如 8888.8），无数据时显示 "-"
  String _moneyText(double? value) => value == null ? "-" : value.toStringAsFixed(1);

  Widget _buildDeviceStatusCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Row(children: [
        _StatusHalf(label: l10n.homeDeviceStatusOnline, value: "${_dashboardData?.onlineDeviceCount ?? "-"}", unit: "/ ${_dashboardData?.totalDeviceCount ?? 0}", color: const Color(0xFF10B981)),
        Container(width: 1, height: 40, color: const Color(0xFFF1F5F9)),
        _StatusHalf(label: l10n.homeDeviceStatusAlert, value: "${_dashboardData?.inventoryAlertCount ?? "-"}", unit: " 项", color: const Color(0xFFF59E0B)),
      ]),
    );
  }

  Widget _buildAlertSection(AppLocalizations l10n) {
    final counts = _alertCount;
    final hasAlerts = (counts?.faultCount ?? 0) > 0 || (counts?.warningCount ?? 0) > 0 || (counts?.stockOutCount ?? 0) > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l10n.homeAlertTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          GestureDetector(
            key: AppKeys.homeAlertViewAll,
            onTap: () => AlertPage.actionStart(),
            child: Text(l10n.homeAlertViewAll, style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6), fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 12),
        if (hasAlerts)
          Row(children: [
            _AlertCountCard(
              label: l10n.homeAlertFaultCount,
              count: counts?.faultCount ?? 0,
              icon: Icons.warning_amber_rounded,
              bgColor: AlertTypeEnum.DEVICE_FAULT.badgeColor,
              fgColor: AlertTypeEnum.DEVICE_FAULT.badgeTextColor,
            ),
            const SizedBox(width: 10),
            _AlertCountCard(
              label: l10n.homeAlertWarningCount,
              count: counts?.warningCount ?? 0,
              icon: Icons.error_outline,
              bgColor: AlertTypeEnum.DEVICE_WARNING.badgeColor,
              fgColor: AlertTypeEnum.DEVICE_WARNING.badgeTextColor,
            ),
            const SizedBox(width: 10),
            _AlertCountCard(
              label: l10n.homeAlertStockOutCount,
              count: counts?.stockOutCount ?? 0,
              icon: Icons.inventory_2,
              bgColor: AlertTypeEnum.STOCK_OUT.badgeColor,
              fgColor: AlertTypeEnum.STOCK_OUT.badgeTextColor,
            ),
          ])
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_outline, size: 16, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(l10n.homeAlertNoAlerts, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            ]),
          ),
      ]),
    );
  }

  Future<void> _onClick(int index) async {
    final l10n = AppLocalizations.of(context);
    switch (index) {
      case 0:
        StockPage.actionStart(operators: _operators);
        break;
      case 1:
        var granted = await PermissionUtils.check(context, Permission.camera, permissionName: l10n.homeCameraPermission);
        if (!granted) return;
        var code = await ScannerPage.actionStart();
        if (code.isNullOrEmpty) {
          l10n.homeScanFailed.toast();
          return;
        }
        var result = await trySingle(() async => (await ApiServer.instance.scan(code ?? ""))?.take());
        if (result.isNullOrEmpty) {
          l10n.homeScanFailed.toast();
          return;
        }
        if (!mounted) return;
        final resultCode = result ?? '';
        DialogUtil.showConfirmDialog(context, title: l10n.dialogScanSuccess, message: l10n.dialogScanCode(resultCode), confirmText: l10n.dialogClose, onConfirm: () {});
        break;
      case 3:
        OrderPage.actionStart();
        break;
      case 2:
        DeviceListPage.actionStart(operators: _operators);
        break;
      default:
        break;
    }
  }

  /// 打开管理域选择侧边抽屉
  void _openDomainDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  /// 用户主动登出
  Future<void> _onLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.commonLogout),
        content: Text(l10n.commonLogoutConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;

    // 先注销推送，再清除缓存
    await PushService.instance.unregister();
    MqttManager.instance.dispose();
    await LoginCache.removeAll();
    LoginPage.pushAndRemoveTo();
  }
}

/// 顶部统计卡片：图标 + 若干 [_MetricRow] 指标行，两卡并排等高
class _StatCard extends StatelessWidget {
  /// 卡片左上角图标
  final IconData icon;
  /// 指标行列表（可含 SizedBox 间隔）
  final List<Widget> children;
  const _StatCard({required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          ...children,
        ]),
      ),
    );
  }
}

/// 卡片内单项指标：标签在上，数值 + 单位在下
/// 关键步骤：采用纵向排布而非横向，让数值独占整张卡片宽度。
/// 横向排布时若用 Flexible(flex: 0) 包裹数值，数值会优先占满整行、把标签挤压成省略号；
/// 纵向排布下二者不再争抢同一行宽度，配合 [FittedBox] 等比缩放，
/// 极长金额（如 88888888.8元）也只会缩小字号，不会溢出或重叠。
class _MetricRow extends StatelessWidget {
  /// 指标标签
  final String label;
  /// 指标数值（已格式化的字符串）
  final String value;
  /// 数值单位
  final String unit;
  const _MetricRow({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      // 标签独占一行，过长省略
      Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis, softWrap: false),
      const SizedBox(height: 2),
      // 数值独占整行宽度，宽度不足时整体等比缩小而非溢出
      SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            maxLines: 1,
            text: TextSpan(children: [
              TextSpan(text: value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, height: 1.2)),
              TextSpan(text: unit, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, height: 1.2)),
            ]),
          ),
        ),
      ),
    ]);
  }
}

/// 设备状态半区指标
class _StatusHalf extends StatelessWidget {
  /// 指标标签
  final String label;
  /// 指标数值
  final String value;
  /// 指标单位
  final String unit;
  /// 指标颜色
  final Color color;
  const _StatusHalf({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.circle, size: 8, color: color), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500))]),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(children: [
            TextSpan(text: value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
            TextSpan(text: unit, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

/// 预警卡片项
class _AlertItem extends StatelessWidget {
  /// 预警标题
  final String title;
  /// 预警时间
  final String time;
  /// 预警消息
  final String msg;
  /// 是否为错误级别
  final bool isError;
  const _AlertItem({required this.title, required this.time, required this.msg, required this.isError});

  @override
  Widget build(BuildContext context) {
    final mainColor = isError ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final bgColor = isError ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB);
    final borderColor = isError ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: mainColor, borderRadius: BorderRadius.circular(6)), child: Icon(isError ? Icons.warning_amber_rounded : Icons.inventory_2, color: Colors.white, size: 14)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isError ? const Color(0xFFB91C1C) : const Color(0xFF92400E))),
              Text(time, style: TextStyle(fontSize: 9, color: isError ? const Color(0xFFF87171) : const Color(0xFFFBBF24))),
            ]),
            const SizedBox(height: 4),
            Text(msg, style: TextStyle(fontSize: 11, color: isError ? const Color(0xFFDC2626) : const Color(0xFFD97706))),
          ]),
        ),
      ]),
    );
  }
}

/// 业务功能网格
class _BusinessSection extends StatelessWidget {
  /// 菜单点击回调 [index] 菜单序号
  final void Function(int) onMenuTap;
  const _BusinessSection({required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final List<Map<String, dynamic>> menus = [
      {"name": l10n.homeMenuInventory, "icon": Icons.inventory_2, "color": const Color(0xFF3B82F6), "bg": const Color(0xFFEFF6FF)},
      {"name": l10n.homeMenuScan, "icon": Icons.qr_code_2, "color": const Color(0xFF8B5CF6), "bg": const Color(0xFFF5F3FF)},
      {"name": l10n.homeMenuDevices, "icon": Icons.developer_board, "color": const Color(0xFFF97316), "bg": const Color(0xFFFFF7ED)},
      {"name": l10n.homeMenuOrders, "icon": Icons.assignment, "color": const Color(0xFF10B981), "bg": const Color(0xFFECFDF5)},
      {"name": l10n.homeMenuRepair, "icon": Icons.report_problem, "color": const Color(0xFFEF4444), "bg": const Color(0xFFFEF2F2)},
      {"name": l10n.homeMenuReport, "icon": Icons.bar_chart, "color": const Color(0xFF06B6D4), "bg": const Color(0xFFF0F9FF)},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l10n.homeBusinessTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ]),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.9),
          itemCount: menus.length,
          itemBuilder: (context, index) {
            const menuKeys = [
              AppKeys.homeMenuInventory,
              AppKeys.homeMenuScan,
              AppKeys.homeMenuDevices,
              AppKeys.homeMenuOrders,
              AppKeys.homeMenuRepair,
              AppKeys.homeMenuReport,
            ];
            return Container(
              key: menuKeys[index],
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: menus[index]['bg'], borderRadius: BorderRadius.circular(10)), child: Icon(menus[index]['icon'], color: menus[index]['color'], size: 24)),
                const SizedBox(height: 8),
                Text(menus[index]['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
              ]),
            ).onClickRelease(() => onMenuTap(index));
          },
        ),
      ]),
    );
  }
}

/// 首页告警计数卡片
class _AlertCountCard extends StatelessWidget {
  /// 标签
  final String label;
  /// 数量
  final int count;
  /// 图标
  final IconData icon;
  /// 背景色
  final Color bgColor;
  /// 前景色
  final Color fgColor;

  const _AlertCountCard({required this.label, required this.count, required this.icon, required this.bgColor, required this.fgColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Icon(icon, size: 20, color: fgColor),
          const SizedBox(height: 6),
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: fgColor)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: fgColor.withValues(alpha: 0.8))),
        ]),
      ),
    );
  }
}
