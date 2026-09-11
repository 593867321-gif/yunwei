import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/enums.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/api_alert.dart';
import 'package:operation/net/request_server.dart';
import 'package:operation/ext/app_keys.dart';

/// 告警列表页 — 采用 Mixin 混入 Bloc 模式
class AlertPage extends StatefulWidget {
  /// 可选的告警 ID，用于从通知跳转时定位到具体告警
  final int? alertId;

  const AlertPage({super.key, this.alertId});

  static void actionStart({int? alertId}) {
    RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(builder: (context) => AlertPage(alertId: alertId)));
  }

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage> with IBaseStreamBloc {
  final StreamData<List<AlertItemVo>> _alerts = StreamData<List<AlertItemVo>>()..value = [];
  final StreamData<bool> _loading = StreamData<bool>()..value = false;
  final StreamData<bool> _loadingMore = StreamData<bool>()..value = false;

  int _offset = 0;
  static const int _pageSize = 20;
  int _total = 0;
  bool _hasMore = true;

  AlertTypeEnum? _typeFilter;
  AlertStatusEnum? _statusFilter;

  final Set<int> _selectedIds = {};
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _fetchData(reset: true);
  }

  Future<void> _fetchData({bool reset = false}) async {
    if (_disposed) return;
    if (reset) {
      _offset = 0;
      _hasMore = true;
      _loading.value = true;
    } else {
      if (_loadingMore.value == true || !_hasMore) return;
      _loadingMore.value = true;
    }

    try {
      final body = AlertQueryRequestBody(
        alertType: _typeFilter?.apiValue,
        status: _statusFilter?.apiValue,
        limit: _pageSize,
        offset: _offset,
      );
      final response = await ApiServer.instance.alertQuery(body);
      final result = response?.take(errorShow: true);
      if (result == null) {
        if (_disposed) return;
        if (reset) _loading.value = false;
        _loadingMore.value = false;
        return;
      }
      final list = result.list ?? [];
      final total = result.total ?? 0;
      _total = total;
      _hasMore = (_offset + list.length) < total;
      if (_disposed) return;

      setState(() {
        if (reset) {
          _alerts.value = list;
        } else {
          final current = List<AlertItemVo>.from(_alerts.value ?? []);
          current.addAll(list);
          _alerts.value = current;
        }
        _offset = _alerts.value?.length ?? 0;
      });
    } catch (e) {
      "告警列表请求失败: $e".log();
      if (_disposed) return;
    } finally {
      if (!_disposed) {
        if (reset) _loading.value = false;
        _loadingMore.value = false;
      }
    }
  }

  void _onTypeFilterChanged(AlertTypeEnum? type) {
    setState(() => _typeFilter = type);
    _fetchData(reset: true);
  }

  void _onStatusFilterChanged(AlertStatusEnum? status) {
    setState(() => _statusFilter = status);
    _fetchData(reset: true);
  }

  void _toggleSelection(int alertId) {
    setState(() {
      if (_selectedIds.contains(alertId)) {
        _selectedIds.remove(alertId);
      } else {
        _selectedIds.add(alertId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _batchAcknowledge() async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.alertBtnAcknowledge),
        content: Text(l10n.alertBatchAcknowledgeConfirm(_selectedIds.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;

    EasyLoading.show();
    try {
      final body = AlertBatchRequestBody(alertIds: _selectedIds.toList());
      final response = await ApiServer.instance.alertAcknowledge(body);
      response?.take();
      l10n.alertOperationSuccess.toast();
      _clearSelection();
      _fetchData(reset: true);
    } catch (_) {
      l10n.alertOperationFailed.toast();
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _batchResolve() async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.alertBtnResolve),
        content: Text(l10n.alertBatchResolveConfirm(_selectedIds.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.commonConfirm)),
        ],
      ),
    );
    if (confirmed != true) return;

    EasyLoading.show();
    try {
      final body = AlertBatchRequestBody(alertIds: _selectedIds.toList());
      final response = await ApiServer.instance.alertResolve(body);
      response?.take();
      l10n.alertOperationSuccess.toast();
      _clearSelection();
      _fetchData(reset: true);
    } catch (_) {
      l10n.alertOperationFailed.toast();
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _alerts.dispose();
    _loading.dispose();
    _loadingMore.dispose();
    streamDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(l10n.alertPageTitle),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        _buildFilterBar(l10n),
        Expanded(child: _buildBody(l10n)),
        if (_selectedIds.isNotEmpty) _buildBatchBar(l10n),
      ]),
    );
  }

  Widget _buildFilterBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildTypeChips(l10n),
        const SizedBox(height: 8),
        _buildStatusChips(l10n),
      ]),
    );
  }

  Widget _buildTypeChips(AppLocalizations l10n) {
    final types = <AlertTypeEnum?>[null, AlertTypeEnum.DEVICE_FAULT, AlertTypeEnum.DEVICE_WARNING, AlertTypeEnum.STOCK_OUT];
    final labels = [l10n.alertFilterAll, l10n.alertFilterFault, l10n.alertFilterWarning, l10n.alertFilterStockOut];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: List.generate(types.length, (i) {
        const typeKeys = [
          AppKeys.alertTypeAll,
          AppKeys.alertTypeFault,
          AppKeys.alertTypeWarning,
          AppKeys.alertTypeStockOut,
        ];
        final isSelected = _typeFilter == types[i];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            key: typeKeys[i],
            label: Text(labels[i], style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF475569))),
            selected: isSelected,
            onSelected: (_) => _onTypeFilterChanged(types[i]),
            selectedColor: const Color(0xFF1E293B),
            backgroundColor: const Color(0xFFF1F5F9),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        );
      })),
    );
  }

  Widget _buildStatusChips(AppLocalizations l10n) {
    final statuses = <AlertStatusEnum?>[null, AlertStatusEnum.NEW, AlertStatusEnum.ACKNOWLEDGED, AlertStatusEnum.RESOLVED];
    final labels = [l10n.alertFilterAll, l10n.alertStatusNew, l10n.alertStatusAcknowledged, l10n.alertStatusResolved];
    const statusKeys = [
      AppKeys.alertStatusAll,
      AppKeys.alertStatusNew,
      AppKeys.alertStatusAcknowledged,
      AppKeys.alertStatusResolved,
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: List.generate(statuses.length, (i) {
        final isSelected = _statusFilter == statuses[i];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            key: statusKeys[i],
            label: Text(labels[i], style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : const Color(0xFF475569))),
            selected: isSelected,
            onSelected: (_) => _onStatusFilterChanged(statuses[i]),
            selectedColor: const Color(0xFF1E293B),
            backgroundColor: const Color(0xFFF1F5F9),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        );
      })),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading.value == true) {
      return const Center(child: CircularProgressIndicator());
    }

    final alerts = _alerts.value;
    if (alerts == null || alerts.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(l10n.alertEmpty, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _fetchData(reset: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification && notification.metrics.pixels >= notification.metrics.maxScrollExtent - 100) {
            _fetchData();
          }
          return false;
        },
        child: Column(children: [
          _buildListHeader(l10n),
          Expanded(child: ListView.builder(
            itemCount: alerts.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= alerts.length) {
                return _buildLoadMoreIndicator(l10n);
              }
              return _AlertCard(
                index: index,
                item: alerts[index],
                isSelected: _selectedIds.contains(alerts[index].id),
                onTap: () {
                  final id = alerts[index].id;
                  if (id != null) _toggleSelection(id);
                },
              );
            },
          )),
          if (!_hasMore && alerts.isNotEmpty)
            _buildAllLoadedIndicator(l10n),
        ]),
      ),
    );
  }

  Widget _buildListHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l10n.alertTotalCount(_total), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        if (_selectedIds.isNotEmpty)
          GestureDetector(
            onTap: _clearSelection,
            child: Text(l10n.commonCancel, style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
          ),
      ]),
    );
  }

  Widget _buildLoadMoreIndicator(AppLocalizations l10n) {
    if (_loadingMore.value == true) {
      return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(child: Text(l10n.alertLoadedAll, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
    );
  }

  Widget _buildAllLoadedIndicator(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(l10n.alertLoadedAll, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
    );
  }

  Widget _buildBatchBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(children: [
        Text(l10n.alertBatchTitle(_selectedIds.length), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const Spacer(),
        _BatchButton(key: AppKeys.alertBatchAcknowledge, label: l10n.alertBtnAcknowledge, color: const Color(0xFFF59E0B), onTap: _batchAcknowledge),
        const SizedBox(width: 10),
        _BatchButton(key: AppKeys.alertBatchResolve, label: l10n.alertBtnResolve, color: const Color(0xFF10B981), onTap: _batchResolve),
      ]),
    );
  }
}

/// 告警卡片组件
class _AlertCard extends StatelessWidget {
  final int index;
  final AlertItemVo item;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlertCard({required this.index, required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = item.alertType;
    final status = item.status;
    final isFault = type == AlertTypeEnum.DEVICE_FAULT;

    return Container(
      key: AppKeys.alertCard(index),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9), width: isSelected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (type != null) _buildBadge(type.label, type.badgeColor, type.badgeTextColor),
              const SizedBox(width: 6),
              if (status != null) _buildBadge(status.label, status.badgeColor, status.badgeTextColor),
              const Spacer(),
              if (isSelected) Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 14)),
            ]),
            const SizedBox(height: 8),
            Text(item.deviceName ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
            if (item.deviceCode != null) ...[
              const SizedBox(height: 2),
              Text(item.deviceCode ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
            const SizedBox(height: 6),
            Text(item.errorDescription ?? '-', style: TextStyle(fontSize: 12, color: isFault ? const Color(0xFFDC2626) : const Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              Text(_formatTime(item.firstOccurTime), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              const Spacer(),
              Builder(builder: (context) {
                final count = item.occurrenceCount;
                if (count != null && count > 1) {
                  return Text('×$count', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)));
                }
                return const SizedBox.shrink();
              }),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w500)),
    );
  }

  String _formatTime(int? millis) {
    if (millis == null) return '-';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
    } catch (_) {
      return '-';
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}

class _BatchButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BatchButton({super.key, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(fontSize: 13)),
    );
  }
}
