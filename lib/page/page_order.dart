import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/domain_cache.dart';
import 'package:operation/ext/util_clipboard.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/api_order.dart';
import 'package:operation/net/api_response.dart';
import 'package:operation/net/request_server.dart';
import 'package:operation/page/page_order_detail.dart';
import 'package:operation/widget/widget_device_drawer.dart';
import 'package:operation/ext/app_keys.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// order: AI   2026/5/1
/// 订单记录页面
/// 提供按管理域筛选的订单列表，含统计概览、状态筛选、日期筛选、搜索和分页
class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  /// 跳转到订单记录页面
  static void actionStart() {
    RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(builder: (context) => const OrderPage()));
  }

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  /// 用于打开管理域选择侧边抽屉
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 下拉刷新 + 上拉加载控制器
  final RefreshController _refreshController = RefreshController();
  /// 搜索框控制器
  final TextEditingController _searchController = TextEditingController();

  /// 当前选中的管理域
  DeviceSelection? _selectedDomain;
  /// 设备树数据（运营商→店铺→设备）
  List<OperationOperatorVo> _operators = [];


  /// 统计数据
  OperationOrderStatisticsVo? _statistics;
  /// 订单列表
  List<OperationOrderQueryVo> _orders = [];
  /// 总条数
  int _total = 0;
  /// 当前页码（从0开始）
  int _offset = 0;
  /// 订单请求是否正在进行
  bool _ordersRequestActive = false;
  /// 当前订单请求序号，用于隔离过期请求结果
  int _ordersRequestId = 0;
  /// 每页条数（上限100）
  static const int _pageSize = 20;

  /// 选中的日期范围：0=今日 1=近7天 2=近30天 3=自定义
  int _dateRangeIndex = 0;
  /// 自定义日期范围
  DateTimeRange? _customRange;
  /// 选中的订单状态（null=全部）
  String? _selectedStatus;
  /// 是否正在加载
  bool _isLoading = true;
  /// 统计面板是否展开
  bool _statsExpanded = false;

  /// 订单状态筛选项
  static const List<Map<String, dynamic>> _statusFilters = [
    {"label": "全部", "value": null},
    {"label": "待支付", "value": "WAITING_PAYMENT"},
    {"label": "已支付", "value": "PAID"},
    {"label": "处理中", "value": "PROCESSING"},
    {"label": "已完成", "value": "COMPLETED"},
    {"label": "已取消", "value": "CANCELLED"},
    {"label": "已退款", "value": "REFUNDED"},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDomain = DomainCache.current;
    _loadDevices();
    _loadStatistics();
    _loadOrders();
  }

  /// 加载设备树数据
  Future<void> _loadDevices() async {
    try {
      final response = await ApiServer.instance.devices();
      final data = response?.take();
      if (mounted && data != null) {
        setState(() => _operators = data);
      }
    } catch (_) {}
  }

  /// 管理域切换回调
  void _onDomainChanged(DeviceSelection selection) {
    setState(() => _selectedDomain = selection);
    DomainCache.update(selection);
    _loadStatistics();
    _loadOrders();
  }

  /// 构建请求体（复用逻辑）
  OperationOrderQueryRequestBody _buildRequestBody({int offset = 0}) {
    return OperationOrderQueryRequestBody(
      operatorId: _selectedDomain?.operatorId,
      storeId: _selectedDomain?.storeId,
      deviceId: _selectedDomain?.deviceId,
      orderSn: _searchController.text.isNotEmpty ? _searchController.text : null,
      orderStatus: _selectedStatus,
      startTime: _getStartTime(),
      endTime: _getEndTime(),
      limit: _pageSize,
      offset: offset,
    );
  }

  /// 获取筛选的起始时间戳（毫秒）
  int? _getStartTime() {
    if (_dateRangeIndex == 3 && _customRange != null) {
      final r = _customRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now());
      return DateTime(r.start.year, r.start.month, r.start.day).millisecondsSinceEpoch;
    }
    final now = DateTime.now();
    switch (_dateRangeIndex) {
      case 1: return DateTime(now.year, now.month, now.day - 7).millisecondsSinceEpoch;
      case 2: return DateTime(now.year, now.month, now.day - 30).millisecondsSinceEpoch;
      default: return DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    }
  }

  /// 获取筛选的结束时间戳（毫秒），今日截止到当前时刻，其他截止到当日结束
  int? _getEndTime() {
    if (_dateRangeIndex == 3 && _customRange != null) {
      final r = _customRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now());
      return DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59).millisecondsSinceEpoch;
    }
    if (_dateRangeIndex == 0) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
  }

  /// 加载订单统计
  Future<void> _loadStatistics() async {
    try {
      final body = OperationOrderStatisticsRequestBody(
        operatorId: _selectedDomain?.operatorId,
        storeId: _selectedDomain?.storeId,
        deviceId: _selectedDomain?.deviceId,
        startTime: _getStartTime(),
        endTime: _getEndTime(),
      );
      final response = await ApiServer.instance.orderStatistics(body);
      final data = response?.take();
      if (mounted) {
        setState(() => _statistics = data);
      }
    } catch (_) {}
  }

  /// 加载订单列表
  Future<void> _loadOrders({bool isRefresh = false, int? offset}) async {
    if (!isRefresh && _ordersRequestActive) return;

    final requestOffset = isRefresh ? 0 : (offset ?? _offset);
    final requestId = ++_ordersRequestId;
    _ordersRequestActive = true;
    var requestSucceeded = false;

    await jobIO(() async {
      final body = _buildRequestBody(offset: requestOffset);
      final response = await ApiServer.instance.orderList(body);
      final data = response?.take();
      if (mounted && data != null) {
        setState(() {
          if (requestOffset == 0) {
            _orders = data.list ?? [];
          } else {
            _orders.addAll(data.list ?? []);
          }
          _total = data.total ?? 0;
          _offset = requestOffset;
          _isLoading = false;
        });
        requestSucceeded = true;
      }
    }, onFinally: () {
      if (requestId != _ordersRequestId) return;
      _ordersRequestActive = false;
      if (mounted) {
        if (_isLoading) {
          setState(() => _isLoading = false);
        }
        if (requestOffset == 0) {
          if (requestSucceeded) {
            _refreshController.refreshCompleted(resetFooterState: true);
          } else {
            _refreshController.refreshFailed();
          }
        } else if (requestSucceeded) {
          if (_orders.length >= _total) {
            _refreshController.loadNoData();
          } else {
            _refreshController.loadComplete();
          }
        } else {
          _refreshController.loadFailed();
        }
      }
      EasyLoading.dismiss();
    }, toastEnable: true);
  }

  /// 下拉刷新
  void _onRefresh() {
    _loadStatistics();
    _loadOrders(isRefresh: true);
  }

  /// 上拉加载更多
  void _onLoading() {
    if (_ordersRequestActive) return;
    if (_orders.length >= _total) {
      _refreshController.loadNoData();
      return;
    }
    _loadOrders(offset: _offset + 1);
  }

  /// 日期范围切换
  void _onDateRangeChanged(int index) async {
    if (index == 3) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        locale: const Locale('zh'),
      );
      if (range == null) return;
      setState(() {
        _customRange = range;
        _dateRangeIndex = 3;
      });
    } else {
      setState(() {
        _dateRangeIndex = index;
        _customRange = null;
      });
    }
    _onRefresh();
  }

  /// 状态筛选切换
  void _onStatusChanged(String? status) {
    setState(() => _selectedStatus = status);
    _onRefresh();
  }

  /// 搜索提交
  void _onSearch() {
    _onRefresh();
  }

  /// 点击订单跳转详情
  void _onOrderTap(OperationOrderQueryVo order) {
    if (order.orderSn == null) return;
    final sn = order.orderSn ?? '';
    OrderDetailPage.actionStart(orderSn: sn);
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
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
            onSelected: (sel) {
              _onDomainChanged(sel);
              Navigator.pop(context);
            },
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(l10n.homeMenuOrders),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(key: AppKeys.orderBackButton, icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(key: AppKeys.orderDomainFilter, icon: const Icon(Icons.widgets_outlined, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
        ],
      ),
      body: Column(children: [
        _buildStatisticsSection(),
        _buildFilterBar(),
        _buildSearchBar(),
        Expanded(child: _buildOrderList()),
      ]),
    );
  }

  /// 统计概览区域：折叠/展开
  Widget _buildStatisticsSection() {
    final s = _statistics;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 折叠按钮行
        GestureDetector(
          onTap: () => setState(() => _statsExpanded = !_statsExpanded),
          child: Row(children: [
            const Icon(Icons.bar_chart, size: 16, color: Color(0xFF3B82F6)),
            const SizedBox(width: 6),
            Expanded(child: Text(_selectedDomain?.label ?? '全部设备', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
            Text('共 ${s?.totalOrderCount ?? '-'} 单  ¥${(s?.totalRevenue ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            AnimatedRotation(turns: _statsExpanded ? 0.5 : 0, duration: const Duration(milliseconds: 200), child: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF94A3B8))),
          ]),
        ),
        // 展开面板
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(children: [
              Row(children: [
                Expanded(child: _MiniStatCard(label: '营业额', value: s?.totalRevenue != null ? '¥${s!.totalRevenue!.toStringAsFixed(2)}' : '-', color: const Color(0xFF3B82F6))),
                Expanded(child: _MiniStatCard(label: '已支付', value: '${s?.paidCount ?? '-'}', color: const Color(0xFF10B981))),
                Expanded(child: _MiniStatCard(label: '已完成', value: '${s?.completedCount ?? '-'}', color: const Color(0xFF8B5CF6))),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _MiniStatCard(label: '待支付', value: '${s?.unpaidCount ?? '-'}', color: const Color(0xFFF59E0B))),
                Expanded(child: _MiniStatCard(label: '已退款', value: '${s?.refundedCount ?? '-'}', color: const Color(0xFFEF4444))),
                Expanded(child: _MiniStatCard(label: '已取消', value: '${s?.cancelledCount ?? '-'}', color: const Color(0xFF94A3B8))),
              ]),
            ]),
          ),
          crossFadeState: _statsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ]),
    );
  }

  /// 筛选栏：日期范围按钮 + 状态
  Widget _buildFilterBar() {
    final dateLabels = ['今日', '近7天', '近30天', '自定义'];
    String dateText = dateLabels[_dateRangeIndex];
    if (_dateRangeIndex == 3 && _customRange != null) {
      String fmt(DateTime d) => '${d.month}/${d.day}';
      final r = _customRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now());
      dateText = '${fmt(r.start)}-${fmt(r.end)}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 日期范围 + 状态筛选 一行
        Row(children: [
          // 日期范围按钮
          PopupMenuButton<int>(
            offset: const Offset(0, 36),
            padding: EdgeInsets.zero,
            onSelected: _onDateRangeChanged,
            itemBuilder: (ctx) => dateLabels.asMap().entries.map((e) {
              const dateKeys = [
                AppKeys.orderDateToday,
                AppKeys.orderDate7days,
                AppKeys.orderDate30days,
                AppKeys.orderDateCustom,
              ];
              return PopupMenuItem<int>(key: dateKeys[e.key], value: e.key, height: 36, child: Text(e.value, style: const TextStyle(fontSize: 13)));
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.date_range, size: 13, color: Colors.white),
                const SizedBox(width: 4),
                Text(dateText, style: const TextStyle(fontSize: 12, color: Colors.white)),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          // 状态筛选 chips
          Expanded(
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _statusFilters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (ctx, i) {
                  final f = _statusFilters[i];
                  final isSelected = _selectedStatus == f['value'];
                  final statusKey = switch (f['value'] as String?) {
                    null => AppKeys.orderStatusAll,
                    'WAITING_PAYMENT' => AppKeys.orderStatusUnpaid,
                    'PAID' => AppKeys.orderStatusPaid,
                    'PROCESSING' => AppKeys.orderStatusProcessing,
                    'COMPLETED' => AppKeys.orderStatusCompleted,
                    'CANCELLED' => AppKeys.orderStatusCancelled,
                    'REFUNDED' => AppKeys.orderStatusRefunded,
                    _ => AppKeys.orderStatusAll,
                  };
                  return ChoiceChip(
                    key: statusKey,
                    label: Text(f['label'] as String, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : const Color(0xFF475569))),
                    selected: isSelected,
                    selectedColor: const Color(0xFF3B82F6),
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => _onStatusChanged(f['value'] as String?),
                  );
                },
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
      ]),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      color: Colors.white,
      child: TextField(
        key: AppKeys.orderSearchInput,
        controller: _searchController,
        onSubmitted: (_) => _onSearch(),
        decoration: InputDecoration(
          hintText: '搜索订单编号',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          suffixIcon: _searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); _onSearch(); }) : null,
          filled: true,
          fillColor: const Color(0xFFF2F4F6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  /// 订单列表
  Widget _buildOrderList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
    }
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoading: _onLoading,
      enablePullDown: true,
      enablePullUp: _orders.length < _total,
      child: _orders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 220,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.assignment_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('暂无订单数据', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                  ]),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) => _OrderCard(index: index, order: _orders[index], onTap: () => _onOrderTap(_orders[index])),
            ),
    );
  }
}

// ============================================================
// StatelessWidget 组件
// ============================================================

/// 迷你统计卡片
class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.8))),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}

/// 订单卡片（StatefulWidget，异步加载工单商品名称列表）
class _OrderCard extends StatefulWidget {
  final int index;
  final OperationOrderQueryVo order;
  final VoidCallback onTap;
  const _OrderCard({required this.index, required this.order, required this.onTap});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  List<String>? _itemNames;

  @override
  void initState() {
    super.initState();
    _loadItemNames();
  }

  Future<void> _loadItemNames() async {
    final sn = widget.order.orderSn;
    if (sn == null) return;
    try {
      final body = OperationOrderDetailQueryRequestBody(orderSn: sn);
      final response = await ApiServer.instance.orderDetail(body);
      final detail = response?.take();
      if (mounted && detail?.items != null) {
        final items = detail?.items ?? [];
        final names = items.map((e) => e.name ?? '').where((n) => n.isNotEmpty).toList();
        if (names.isNotEmpty) {
          setState(() => _itemNames = names);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final status = order.orderStatus;
    final statusColor = _statusColor(status);
    final timeStr = () {
      final t = order.createTime;
      if (t == null) return '';
      final dt = DateTime.fromMillisecondsSinceEpoch(t);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }();

    // 显示文本：工单商品名称列表 > productName > userAccount
    final displayName = () {
      final names = _itemNames;
      if (names != null && names.isNotEmpty) return names.join(', ');
      if (order.productName != null && order.productName?.isNotEmpty == true) return order.productName ?? '';
      return order.userAccount ?? '-';
    }();

    return GestureDetector(
      key: AppKeys.orderCard(widget.index),
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
          border: Border(left: BorderSide(color: statusColor, width: 3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(child: Text(order.orderSn ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => ClipboardUtil.copy(order.orderSn ?? ''),
                child: const Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
              ),
            ])),
            Text('¥${(order.actualAmount ?? 0).toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: statusColor)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _StatusTag(status),
            const SizedBox(width: 8),
            Expanded(child: Text(displayName, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.store, size: 12, color: Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Expanded(child: Text(order.storeName ?? order.deviceCode ?? '-', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (timeStr.isNotEmpty) Text(timeStr, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ]),
        ]),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'WAITING_PAYMENT': return const Color(0xFFF59E0B);
      case 'PAID': return const Color(0xFF3B82F6);
      case 'PROCESSING': return const Color(0xFF8B5CF6);
      case 'COMPLETED': return const Color(0xFF10B981);
      case 'CANCELLED': return const Color(0xFF94A3B8);
      case 'REFUNDED':
      case 'PARTIALLY_REFUNDED': return const Color(0xFFEF4444);
      default: return const Color(0xFFCBD5E1);
    }
  }
}

/// 订单状态标签
class _StatusTag extends StatelessWidget {
  /// 订单状态
  final String? status;
  const _StatusTag(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusTagColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(orderStatusLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }

  Color _statusTagColor(String? status) {
    switch (status) {
      case 'WAITING_PAYMENT': return const Color(0xFFF59E0B);
      case 'PAID': return const Color(0xFF3B82F6);
      case 'PROCESSING': return const Color(0xFF8B5CF6);
      case 'COMPLETED': return const Color(0xFF10B981);
      case 'CANCELLED': return const Color(0xFF94A3B8);
      case 'REFUNDED':
      case 'PARTIALLY_REFUNDED': return const Color(0xFFEF4444);
      default: return const Color(0xFFCBD5E1);
    }
  }
}
