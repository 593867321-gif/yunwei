import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/util_clipboard.dart';
import 'package:operation/net/api_order.dart';
import 'package:operation/net/request_server.dart';
import 'package:operation/page/page_order_item_detail.dart';
import 'package:operation/page/page_stock_record.dart';
import 'package:operation/ext/app_keys.dart';

/// author: AI   2026/5/1
/// 订单详情页面
/// 展示订单概要信息、门店信息、工单子项列表
class OrderDetailPage extends StatefulWidget {
  /// 订单编号
  final String orderSn;
  const OrderDetailPage({super.key, required this.orderSn});

  /// 跳转到订单详情页
  static void actionStart({required String orderSn}) {
    RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(builder: (context) => OrderDetailPage(orderSn: orderSn)));
  }

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  /// 订单详情数据
  AdminOrderDetailVo? _detail;
  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  /// 加载订单详情
  Future<void> _loadDetail() async {
    jobIO(() async {
      final body = OperationOrderDetailQueryRequestBody(orderSn: widget.orderSn);
      final response = await ApiServer.instance.orderDetail(body);
      final data = response?.take();
      if (mounted && data != null) {
        setState(() {
          _detail = data;
          _isLoading = false;
        });
      }
    }, onFinally: () => EasyLoading.dismiss(), toastEnable: true);
  }

  /// 点击工单子项跳转到工单详情
  void _onItemTap(AdminOrderDetailItemVo item) {
    final id = item.itemId;
    if (id == null) return;
    OrderItemDetailPage.actionStart(itemId: id);
  }

  /// 是否存在可取消的工单
  bool _hasCancellableItems() {
    final items = _detail?.items ?? [];
    return items.any((item) {
      final status = item.makeStatus;
      return status == 'WAITING' || status == 'MAKING';
    });
  }

  /// 执行取消请求
  Future<void> _doCancel(List<int> itemIds, {String? reason, bool? refund}) async {
    jobIO(() async {
      final body = OrderItemBatchCancelRequestBody(itemIds: itemIds, reason: reason, refund: refund);
      final response = await ApiServer.instance.orderItemBatchCancel(body);
      final data = response?.take();
      if (mounted && data == true) {
        EasyLoading.showSuccess('工单已取消');
        _loadDetail();
      }
    }, onFinally: () => EasyLoading.dismiss(), toastEnable: true);
  }

  /// 执行丢杯请求
  Future<void> _doDiscard(int itemId, {String? reason, bool? refund}) async {
    jobIO(() async {
      final body = AdminOrderItemDiscardRequestBody(orderItemId: itemId, reason: reason, refund: refund);
      final response = await ApiServer.instance.orderItemDiscard(body);
      final data = response?.take();
      if (mounted && data == true) {
        EasyLoading.showSuccess('丢杯指令已发送');
        _loadDetail();
      }
    }, onFinally: () => EasyLoading.dismiss(), toastEnable: true);
  }

  /// 显示批量取消弹窗
  void _showBatchCancelDialog() {
    final items = _detail?.items ?? [];
    final cancellableItems = items.where((item) {
      final status = item.makeStatus;
      return status == 'WAITING' || status == 'MAKING';
    }).toList();
    if (cancellableItems.isEmpty) return;
    _BatchCancelDialog.show(
      context: context,
      items: cancellableItems,
      onConfirm: (itemIds, reason, refund) {
        _doCancel(itemIds, reason: reason, refund: refund);
      },
    );
  }

  /// 显示单个取消弹窗
  void _showCancelDialog(AdminOrderDetailItemVo item) {
    _CancelDialog.show(
      context: context,
      item: item,
      onConfirm: (itemIds, reason, refund) {
        _doCancel(itemIds, reason: reason, refund: refund);
      },
    );
  }

  /// 显示丢杯弹窗
  void _showDiscardDialog(AdminOrderDetailItemVo item) {
    final itemId = item.itemId;
    if (itemId == null) return;
    _DiscardDialog.show(
      context: context,
      item: item,
      onConfirm: (reason, refund) {
        _doDiscard(itemId, reason: reason, refund: refund);
      },
    );
  }

  /// 显示更多菜单
  void _showMoreMenu() {
    final d = _detail;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(1000, 80, 0, 0),
      items: [
        PopupMenuItem(
          key: AppKeys.orderDetailMenuStockRecord,
          value: 'stock_record',
          child: const Row(children: [
            Icon(Icons.receipt_long, size: 18, color: Color(0xFF475569)),
            SizedBox(width: 8),
            Text('查看库存流水', style: TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
          ]),
        ),
        PopupMenuItem(
          key: AppKeys.orderDetailMenuRefresh,
          value: 'refresh',
          child: const Row(children: [
            Icon(Icons.refresh, size: 18, color: Color(0xFF475569)),
            SizedBox(width: 8),
            Text('刷新', style: TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
          ]),
        ),
      ],
    ).then((value) {
      if (value == 'stock_record') {
        if (d?.deviceId != null) {
          StockRecordPage.actionStart(deviceId: d!.deviceId!, deviceName: d.store?.name);
        } else {
          EasyLoading.showInfo('暂无可关联设备');
        }
      } else if (value == 'refresh') {
        setState(() => _isLoading = true);
        _loadDetail();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('订单详情'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(key: AppKeys.orderDetailBackButton, icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            key: AppKeys.orderDetailMore,
            icon: const Icon(Icons.more_horiz),
            tooltip: '更多',
            onPressed: _showMoreMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _detail == null
              ? const Center(child: Text('订单不存在', style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  _buildOrderInfo(),
                  const SizedBox(height: 12),
                  _buildStoreInfo(),
                  const SizedBox(height: 16),
                  _buildItemsSection(),
                ]),
    );
  }

  /// 订单概要信息
  Widget _buildOrderInfo() {
    final d = _detail;
    if (d == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(child: Text(d.orderSn ?? '-', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
            const SizedBox(width: 6),
            GestureDetector(
              key: AppKeys.orderDetailCopySn,
              onTap: () => ClipboardUtil.copy(d.orderSn ?? ''),
              child: const Icon(Icons.copy, size: 14, color: Color(0xFF94A3B8)),
            ),
          ])),
          _StatusBadge(d.orderStatus),
        ]),
        const Divider(height: 20),
        _InfoRow(label: '订单金额', value: '¥${(d.totalAmount ?? 0).toStringAsFixed(2)}', valueStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        _InfoRow(label: '实付金额', value: '¥${(d.actualAmount ?? 0).toStringAsFixed(2)}', valueStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6))),
        _InfoRow(label: '优惠金额', value: '¥${(d.discountAmount ?? 0).toStringAsFixed(2)}'),
        _InfoRow(label: '支付方式', value: payTypeLabel(d.payType)),
        _InfoRow(label: '订单来源', value: sourceLabel(d.source)),
        _InfoRow(label: '交付模式', value: deliveryTypeLabel(d.deliveryType)),
        _InfoRow(label: '支付状态', value: payStatusLabel(d.payStatus)),
        if (d.payTime != null) _InfoRow(label: '支付时间', value: formatTimestampFull(d.payTime)),
        if (d.createTime != null) _InfoRow(label: '创建时间', value: formatTimestampFull(d.createTime)),
        if (d.finishedTime != null) _InfoRow(label: '完成时间', value: formatTimestampFull(d.finishedTime)),
      ]),
    );
  }

  /// 门店信息
  Widget _buildStoreInfo() {
    final store = _detail?.store;
    if (store == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('门店信息', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.store, size: 16, color: Color(0xFF3B82F6)),
          const SizedBox(width: 6),
          Expanded(child: Text(store.name ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
        ]),
        if (store.fullAddress?.isNotEmpty == true) Padding(
          padding: const EdgeInsets.only(left: 22, top: 4),
          child: Text(store.fullAddress ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ),
        if (store.contact?.isNotEmpty == true) Padding(
          padding: const EdgeInsets.only(left: 22, top: 2),
          child: Text('联系方式：${store.contact}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ),
      ]),
    );
  }

  /// 工单子项列表
  Widget _buildItemsSection() {
    final items = _detail?.items ?? [];
    final showBatch = _hasCancellableItems();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('工单子项（${items.length}）', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        if (showBatch)
          GestureDetector(
            key: AppKeys.orderDetailBatchCancel,
            onTap: _showBatchCancelDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('批量取消', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
            ),
          ),
      ]),
      const SizedBox(height: 10),
      ...items.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(item.name ?? '工单 #${item.itemId}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
            _MakeStatusBadge(item.makeStatus),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            Text('工单ID：${item.itemId}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => ClipboardUtil.copy('${item.itemId}'),
              child: const Icon(Icons.copy, size: 12, color: Color(0xFF94A3B8)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _ItemInfoChip('数量', '${item.quantity ?? 1}'),
            const SizedBox(width: 12),
            _ItemInfoChip('单价', '¥${(item.unitPrice ?? 0).toStringAsFixed(2)}'),
            const SizedBox(width: 12),
            _ItemInfoChip('小计', '¥${((item.unitPrice ?? 0) * (item.quantity ?? 1)).toStringAsFixed(2)}'),
          ]),
          if (item.slotNo?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text('存储格：${item.slotNo}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
          if (item.makeStatus == 'CANCEL' && item.cancelReason?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text('取消原因：${cancelReasonLabel(item.cancelReason)}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _buildItemAction(item),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _onItemTap(item),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Text('查看工单详情', style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF3B82F6)),
              ]),
            ),
          ]),
        ]),
      ).onClickRelease(() => _onItemTap(item))),
    ]);
  }

  /// 根据工单状态构建操作按钮
  Widget _buildItemAction(AdminOrderDetailItemVo item) {
    final status = item.makeStatus;
    switch (status) {
      case 'WAITING':
        return GestureDetector(
          key: AppKeys.orderDetailBtnCancel(item.itemId ?? 0),
          onTap: () => _showCancelDialog(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('取消工单', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
          ),
        );
      case 'MAKING':
        return GestureDetector(
          key: AppKeys.orderDetailBtnForceCancel(item.itemId ?? 0),
          onTap: () => _showCancelDialog(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('强制取消', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
          ),
        );
      case 'STORED':
      case 'READY':
        return GestureDetector(
          key: AppKeys.orderDetailBtnDiscard(item.itemId ?? 0),
          onTap: () => _showDiscardDialog(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('丢杯', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFEF4444))),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 订单状态徽标
class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(orderStatusLabel(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'WAITING_PAYMENT': return const Color(0xFFF59E0B);
      case 'PAID': return const Color(0xFF3B82F6);
      case 'PROCESSING': return const Color(0xFF8B5CF6);
      case 'COMPLETED': return const Color(0xFF10B981);
      case 'CANCELLED': return const Color(0xFF94A3B8);
      default: return const Color(0xFFEF4444);
    }
  }
}

/// 工单制作状态徽标
class _MakeStatusBadge extends StatelessWidget {
  final String? status;
  const _MakeStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(makeStatusLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'WITHHOLD': return const Color(0xFF94A3B8);
      case 'WAITING': return const Color(0xFFF59E0B);
      case 'MAKING': return const Color(0xFF8B5CF6);
      case 'STORED': return const Color(0xFF3B82F6);
      case 'READY': return const Color(0xFF06B6D4);
      case 'TAKEN': return const Color(0xFF10B981);
      case 'FAILED': return const Color(0xFFEF4444);
      case 'CANCEL': return const Color(0xFF94A3B8);
      default: return const Color(0xFFCBD5E1);
    }
  }
}

/// 信息行
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _InfoRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
        Expanded(child: Text(value, style: valueStyle ?? const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
      ]),
    );
  }
}

/// 子项信息标签
class _ItemInfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _ItemInfoChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
    ]);
  }
}

/// 单独取消工单弹窗
class _CancelDialog extends StatefulWidget {
  final AdminOrderDetailItemVo item;
  final void Function(List<int> itemIds, String? reason, bool? refund) onConfirm;

  const _CancelDialog({required this.item, required this.onConfirm});

  /// 显示取消弹窗
  static void show({
    required BuildContext context,
    required AdminOrderDetailItemVo item,
    required void Function(List<int> itemIds, String? reason, bool? refund) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => _CancelDialog(item: item, onConfirm: onConfirm),
    );
  }

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reasonController = TextEditingController();
  bool _refund = true;
  bool _confirmed = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMaking = widget.item.makeStatus == 'MAKING';
    final title = isMaking ? '强制取消工单' : '取消工单';
    final confirmColor = isMaking ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final confirmText = isMaking ? '确认强制取消' : '确认取消';

    return AlertDialog(
      title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DialogLabel('工单ID', '${widget.item.itemId}'),
          const SizedBox(height: 4),
          _DialogLabel('商品', widget.item.name ?? '-'),
          const SizedBox(height: 4),
          _DialogLabel('状态', makeStatusLabel(widget.item.makeStatus)),
          const SizedBox(height: 12),
            TextField(
            key: AppKeys.dialogReasonInput,
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: '取消原因（选填）',
              hintText: '请输入取消原因',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('是否退款', style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
            Switch(
              key: AppKeys.dialogRefundSwitch,
              value: _refund,
              onChanged: (v) => setState(() => _refund = v),
              activeTrackColor: const Color(0xFF3B82F6),
            ),
          ]),
          if (isMaking) ...[
            const SizedBox(height: 12),
            const Text('⚠️ 制作中的工单取消后不会退回原料库存。', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
            const SizedBox(height: 4),
            CheckboxListTile(
              key: AppKeys.dialogRiskCheckbox,
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('我已了解风险，确认强制取消', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
              dense: true,
            ),
          ],
        ]),
      ),
      actions: [
        TextButton(
          key: AppKeys.dialogCancel,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          key: isMaking ? AppKeys.dialogConfirmForceCancel : AppKeys.dialogConfirmCancel,
          onPressed: isMaking && !_confirmed
              ? null
              : () {
                  Navigator.pop(context);
                  final itemId = widget.item.itemId;
                  if (itemId == null) return;
                  widget.onConfirm(
                    [itemId],
                    _reasonController.text.isNotEmpty ? _reasonController.text : null,
                    _refund,
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: (isMaking && !_confirmed) ? const Color(0xFFCBD5E1) : confirmColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// 批量取消工单弹窗
class _BatchCancelDialog extends StatefulWidget {
  final List<AdminOrderDetailItemVo> items;
  final void Function(List<int> itemIds, String? reason, bool? refund) onConfirm;

  const _BatchCancelDialog({required this.items, required this.onConfirm});

  /// 显示批量取消弹窗
  static void show({
    required BuildContext context,
    required List<AdminOrderDetailItemVo> items,
    required void Function(List<int> itemIds, String? reason, bool? refund) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => _BatchCancelDialog(items: items, onConfirm: onConfirm),
    );
  }

  @override
  State<_BatchCancelDialog> createState() => _BatchCancelDialogState();
}

class _BatchCancelDialogState extends State<_BatchCancelDialog> {
  final _reasonController = TextEditingController();
  bool _refund = true;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    for (final item in widget.items) {
      final id = item.itemId;
      if (id != null) {
        _selectedIds.add(id);
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasMaking = widget.items.any((item) => item.makeStatus == 'MAKING');
    return AlertDialog(
      title: const Text('批量取消工单', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('请选择要取消的工单：', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
          const SizedBox(height: 8),
          ...widget.items.map((item) {
            final id = item.itemId ?? 0;
            final isMaking = item.makeStatus == 'MAKING';
            return CheckboxListTile(
              value: _selectedIds.contains(id),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    _selectedIds.add(id);
                  } else {
                    _selectedIds.remove(id);
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: Row(children: [
                if (isMaking) ...[
                  const Text('⚠️ ', style: TextStyle(fontSize: 14)),
                ],
                Text(item.name ?? '工单 #$id', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                const SizedBox(width: 6),
                Text(makeStatusLabel(item.makeStatus), style: TextStyle(fontSize: 11, color: isMaking ? const Color(0xFFEF4444) : const Color(0xFFF59E0B))),
              ]),
            );
          }),
          if (hasMaking) ...[
            const SizedBox(height: 4),
            const Text('⚠️ 制作中的工单取消后不会退回原料库存。', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
          ],
          const SizedBox(height: 12),
          TextField(
            key: AppKeys.dialogReasonInput,
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: '取消原因（选填）',
              hintText: '请输入取消原因',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('是否退款', style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
            Switch(
              key: AppKeys.dialogRefundSwitch,
              value: _refund,
              onChanged: (v) => setState(() => _refund = v),
              activeTrackColor: const Color(0xFF3B82F6),
            ),
          ]),
        ]),
      ),
      actions: [
        TextButton(
          key: AppKeys.dialogCancel,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          key: AppKeys.dialogConfirmBatchCancel,
          onPressed: _selectedIds.isEmpty
              ? null
              : () {
                  Navigator.pop(context);
                  widget.onConfirm(
                    _selectedIds.toList(),
                    _reasonController.text.isNotEmpty ? _reasonController.text : null,
                    _refund,
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedIds.isEmpty ? const Color(0xFFCBD5E1) : const Color(0xFFEF4444),
            foregroundColor: Colors.white,
          ),
          child: Text('确认取消（${_selectedIds.length}）'),
        ),
      ],
    );
  }
}

/// 丢杯确认弹窗
class _DiscardDialog extends StatefulWidget {
  final AdminOrderDetailItemVo item;
  final void Function(String? reason, bool? refund) onConfirm;

  const _DiscardDialog({required this.item, required this.onConfirm});

  /// 显示丢杯弹窗
  static void show({
    required BuildContext context,
    required AdminOrderDetailItemVo item,
    required void Function(String? reason, bool? refund) onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => _DiscardDialog(item: item, onConfirm: onConfirm),
    );
  }

  @override
  State<_DiscardDialog> createState() => _DiscardDialogState();
}

class _DiscardDialogState extends State<_DiscardDialog> {
  final _reasonController = TextEditingController();
  bool _refund = false;
  bool _confirmed = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('确认丢杯', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DialogLabel('工单ID', '${widget.item.itemId}'),
          const SizedBox(height: 4),
          _DialogLabel('商品', widget.item.name ?? '-'),
          const SizedBox(height: 12),
          TextField(
            key: AppKeys.dialogReasonInput,
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: '丢弃原因（选填）',
              hintText: '请输入丢弃原因',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('是否退款', style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
            Switch(
              key: AppKeys.dialogRefundSwitch,
              value: _refund,
              onChanged: (v) => setState(() => _refund = v),
              activeTrackColor: const Color(0xFF3B82F6),
            ),
          ]),
          const SizedBox(height: 12),
          CheckboxListTile(
            key: AppKeys.dialogRiskCheckbox,
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('丢杯后用户将不能再取餐，确认操作', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
            dense: true,
          ),
        ]),
      ),
      actions: [
        TextButton(
          key: AppKeys.dialogCancel,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(color: Color(0xFF64748B))),
        ),
        ElevatedButton(
          key: AppKeys.dialogConfirmDiscard,
          onPressed: _confirmed
              ? () {
                  Navigator.pop(context);
                  widget.onConfirm(
                    _reasonController.text.isNotEmpty ? _reasonController.text : null,
                    _refund,
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _confirmed ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
            foregroundColor: Colors.white,
          ),
          child: const Text('确认丢杯'),
        ),
      ],
    );
  }
}

/// 弹窗中的标签-值行
class _DialogLabel extends StatelessWidget {
  final String label;
  final String value;

  const _DialogLabel(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text('$label：', style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
    ]);
  }
}
