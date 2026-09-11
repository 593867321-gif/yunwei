import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/enums.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/api_stock_record.dart';
import 'package:operation/net/request_server.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:operation/ext/app_keys.dart';

/// 库存流水记录页面
/// 按设备查询库存变动记录，支持按事务类型筛选和分页加载
class StockRecordPage extends StatefulWidget {
  /// 查询的目标设备 ID
  final int deviceId;
  /// 设备名称（用于页面副标题）
  final String? deviceName;

  const StockRecordPage({super.key, required this.deviceId, this.deviceName});

  /// 跳转到库存流水记录页面
  /// [deviceId] 设备 ID（必传）
  /// [deviceName] 设备名称（用于展示）
  static void actionStart({required int deviceId, String? deviceName}) {
    RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(
      builder: (context) => StockRecordPage(deviceId: deviceId, deviceName: deviceName),
    ));
  }

  @override
  State<StockRecordPage> createState() => _StockRecordPageState();
}

class _StockRecordPageState extends State<StockRecordPage> {
  /// 记录列表
  final List<StockRecordVo> _records = [];
  /// 总记录数
  int _total = 0;
  /// 当前页码（从0开始，非数据库 offset）
  int _page = 0;
  /// 是否正在加载
  bool _loading = false;
  /// 是否加载失败
  bool _loadFailed = false;
  /// 选中的事务类型筛选（null 表示全部）
  TransactionType? _filterType;
  /// 每页条数
  static const int _pageSize = 20;
  /// 刷新控制器
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecords());
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  /// 加载/刷新记录数据
  Future<void> _loadRecords({bool reset = true}) async {
    if (_loading) return;
    final l10n = AppLocalizations.of(context);
    if (reset) {
      _page = 0;
      _records.clear();
    }
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final body = StockRecordQueryRequestBody(
        deviceId: widget.deviceId,
        transactionType: _filterType,
        limit: _pageSize,
        offset: _page,
      );
      final response = await ApiServer.instance.stockRecordQuery(body);
      final result = response?.take();
      if (result != null && mounted) {
        setState(() {
          _records.addAll(result.list);
          _total = result.total ?? 0;
          _page += 1;
          _loading = false;
        });
        _refreshController.refreshCompleted(resetFooterState: true);
        if (_records.length >= _total) {
          _refreshController.loadNoData();
        } else {
          _refreshController.loadComplete();
        }
      } else {
        _handleError(l10n);
      }
    } catch (e) {
      "加载库存记录失败: $e".log();
      _handleError(l10n);
    }
  }

  void _handleError(AppLocalizations l10n) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loadFailed = _records.isEmpty;
    });
    _refreshController.refreshFailed();
    l10n.stockRecordRetry.toast();
  }

  /// 下拉刷新
  void _onRefresh() => _loadRecords(reset: true);

  /// 上拉加载更多
  void _onLoadMore() {
    if (_records.length >= _total) {
      _refreshController.loadNoData();
      return;
    }
    _loadRecords(reset: false);
  }

  /// 构建时间文本
  String _formatTime(int? millis) {
    if (millis == null) return "";
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return dt.format("yyyy-MM-dd HH:mm:ss");
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allTypes = <TransactionType?>[null, TransactionType.PRE_DEDUCT, TransactionType.ADJUSTMENT, TransactionType.ROLLBACK, TransactionType.REFILL, TransactionType.WASTE];

    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.stockRecordTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          if (widget.deviceName != null)
            Text(widget.deviceName ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400)),
        ]),
        centerTitle: false,
        titleSpacing: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
      ),
      body: Column(children: [
        // 事务类型筛选 Tab
        _buildFilterBar(allTypes, l10n),
        // 记录列表
        Expanded(
          child: _loadFailed
              ? _buildErrorView(l10n)
              : _records.isEmpty && !_loading
                  ? _buildEmptyView(l10n)
                  : SmartRefresher(
                      controller: _refreshController,
                      enablePullDown: true,
                      enablePullUp: _records.length < _total,
                      onRefresh: _onRefresh,
                      onLoading: _onLoadMore,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _records.length,
                        separatorBuilder: (_, b) => const Divider(height: 1, indent: 16, endIndent: 16),
                        itemBuilder: (context, index) => _buildRecordItem(_records[index]),
                      ),
                    ),
        ),
      ]),
    );
  }

  /// 构建筛选 Tab 栏
  Widget _buildFilterBar(List<TransactionType?> types, AppLocalizations l10n) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: types.asMap().entries.map((entry) {
          final type = entry.value;
          final tabIndex = entry.key;
          const tabKeys = [
            AppKeys.stockRecordTabAll,
            AppKeys.stockRecordTabPreDeduct,
            AppKeys.stockRecordTabAdjustment,
            AppKeys.stockRecordTabRollback,
            AppKeys.stockRecordTabRefill,
            AppKeys.stockRecordTabWaste,
          ];
          final isSelected = _filterType == type;
          final label = type == null ? l10n.stockRecordAll : type.label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              key: tabKeys[tabIndex],
              onTap: () {
                if (_filterType == type) return;
                setState(() => _filterType = type);
                EasyLoading.show();
                _loadRecords(reset: true).then((_) => EasyLoading.dismiss());
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? (type?.badgeColor ?? const Color(0xFF1E293B)) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? (type?.badgeTextColor ?? Colors.white) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList()),
      ),
    );
  }

  /// 构建单条记录
  Widget _buildRecordItem(StockRecordVo record) {
    final type = record.transactionType;
    final amount = record.changeAmount ?? 0;
    final isPositive = amount >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 事务类型 Badge
        if (type != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: type.badgeColor, borderRadius: BorderRadius.circular(4)),
            child: Text(type.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: type.badgeTextColor)),
          ),
        const SizedBox(width: 10),
        // 中间信息区
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 第一行：物料名称 + 状态
            Row(children: [
              Expanded(child: Text(record.materialName ?? "-", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
              if (record.status != null)
                Text(record.status?.label ?? '', style: TextStyle(fontSize: 11, color: record.status == TransactionStatus.COMPLETED ? const Color(0xFF10B981) : const Color(0xFF94A3B8))),
            ]),
            const SizedBox(height: 4),
            // 第二行：变动量 + 库存变化
            Row(children: [
              Text(isPositive ? "+$amount" : "$amount", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
              if (record.stockBefore != null || record.stockAfter != null) ...[
                const SizedBox(width: 8),
                Text("${record.stockBefore ?? "?"} → ${record.stockAfter ?? "?"}", style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ]),
            // HW_COLLECT/UNKNOWN 模式预扣流水标注：stockBefore=0 且 stockAfter=0 说明是状态值模式
            if (record.transactionType == TransactionType.PRE_DEDUCT && (record.stockBefore ?? 0) == 0 && (record.stockAfter ?? 0) == 0) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.info_outline, size: 12, color: Color(0xFFF59E0B)),
                const SizedBox(width: 4),
                Text(AppLocalizations.of(context).stockRecordStatusModeHint, style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B))),
              ]),
            ],
            // 第三行：备注
            if ((record.memo ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(record.memo ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        // 右侧：时间和操作人
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_formatTime(record.createTime), style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(record.operatorAccount ?? "", style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
        ]),
      ]),
    );
  }

  /// 构建加载失败视图
  Widget _buildErrorView(AppLocalizations l10n) {
    return Center(
      child: GestureDetector(
        key: AppKeys.stockRecordRetry,
        onTap: () => _loadRecords(reset: true),
        child: Text(l10n.stockRecordRetry, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 14)),
      ),
    );
  }

  /// 构建空数据视图
  Widget _buildEmptyView(AppLocalizations l10n) {
    return Center(child: Text(l10n.stockRecordEmpty, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))));
  }
}
