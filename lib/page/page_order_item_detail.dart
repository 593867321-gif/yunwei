import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/util_clipboard.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/api_order.dart';
import 'package:operation/net/request_server.dart';
import 'package:operation/ext/app_keys.dart';

/// author: AI   2026/5/1
/// 工单详情页面
/// 展示工单完整信息，含制作时间线、物料配方快照
class OrderItemDetailPage extends StatefulWidget {
  /// 工单ID
  final int itemId;
  const OrderItemDetailPage({super.key, required this.itemId});

  /// 跳转到工单详情页
  static void actionStart({required int itemId}) {
    RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(builder: (context) => OrderItemDetailPage(itemId: itemId)));
  }

  @override
  State<OrderItemDetailPage> createState() => _OrderItemDetailPageState();
}

class _OrderItemDetailPageState extends State<OrderItemDetailPage> {
  /// 工单详情数据
  AdminOrderItemQueryVo? _detail;
  /// 是否正在加载
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  /// 加载工单详情
  Future<void> _loadDetail() async {
    jobIO(() async {
      final response = await ApiServer.instance.orderItemDetail(widget.itemId);
      final data = response?.take();
      if (mounted && data != null) {
        setState(() {
          _detail = data;
          _isLoading = false;
        });
      }
    }, onFinally: () => EasyLoading.dismiss(), toastEnable: true);
  }

  /// 根据制作状态返回操作配置（按钮文案 / 颜色 / 操作类型）
  /// 返回 null 表示无操作
  ({String label, Color color, String type})? _actionForStatus() {
    final status = _detail?.makeStatus;
    switch (status) {
      case 'WAITING':
        return (label: '取消', color: const Color(0xFF10B981), type: 'cancel');
      case 'MAKING':
      case 'FAILED':
        return (label: '强制取消', color: const Color(0xFFEF4444), type: 'forceCancel');
      case 'STORED':
      case 'READY':
        return (label: '丢杯', color: const Color(0xFFEF4444), type: 'discard');
      default:
        return null;
    }
  }

  /// 显示取消弹窗（WAITING 状态）
  void _showCancelDialog() {
    final d = _detail;
    if (d == null) return;
    final reasonController = TextEditingController();
    bool refund = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).orderCancelTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _DialogLabel('工单ID', '${d.id}'),
              const SizedBox(height: 4),
              _DialogLabel('商品', d.productName ?? '-'),
              const SizedBox(height: 4),
              _DialogLabel('订单编号', d.orderSn ?? '-'),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                const Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                const Expanded(child: Text('库存将自动回滚', style: TextStyle(fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.w500))),
              ]),
              const SizedBox(height: 12),
              TextField(
                key: AppKeys.dialogReasonInput,
                controller: reasonController,
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
                  value: refund,
                  onChanged: (v) => setDialogState(() => refund = v),
                  activeTrackColor: const Color(0xFF3B82F6),
                ),
              ]),
            ]),
          ),
          actions: [
            TextButton(
              key: AppKeys.dialogCancel,
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).commonCancel, style: const TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              key: AppKeys.dialogConfirmCancel,
              onPressed: () {
                Navigator.pop(ctx);
                _doCancel(reason: reasonController.text.isNotEmpty ? reasonController.text : null, refund: refund);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('确认取消'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示强制取消弹窗（MAKING / FAILED 状态）
  void _showForceCancelDialog() {
    final d = _detail;
    if (d == null) return;
    bool confirmed = false;
    bool refund = true;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).orderCancelForceTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _DialogLabel('工单ID', '${d.id}'),
              const SizedBox(height: 4),
              _DialogLabel('商品', d.productName ?? '-'),
              const SizedBox(height: 4),
              _DialogLabel('订单编号', d.orderSn ?? '-'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(AppLocalizations.of(context).orderCancelWarning,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.w500)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              TextField(
                key: AppKeys.dialogReasonInput,
                controller: reasonController,
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
                  value: refund,
                  onChanged: (v) => setDialogState(() => refund = v),
                  activeTrackColor: const Color(0xFF3B82F6),
                ),
              ]),
              const SizedBox(height: 12),
              CheckboxListTile(
                key: AppKeys.dialogRiskCheckbox,
                value: confirmed,
                onChanged: (v) => setDialogState(() => confirmed = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(AppLocalizations.of(context).orderCancelRiskConfirm, style: const TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                dense: true,
              ),
            ]),
          ),
          actions: [
            TextButton(
              key: AppKeys.dialogCancel,
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).commonCancel, style: const TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              key: AppKeys.dialogConfirmForceCancel,
              onPressed: confirmed
                  ? () {
                      Navigator.pop(ctx);
                      _doCancel(reason: reasonController.text.isNotEmpty ? reasonController.text : null, refund: refund);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmed ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                foregroundColor: Colors.white,
              ),
              child: const Text('确认强制取消'),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示丢杯确认弹窗（STORED / READY 状态）
  void _showDiscardDialog() {
    final d = _detail;
    if (d == null) return;
    bool confirmed = false;
    bool refund = false;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('确认丢杯', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _DialogLabel('工单ID', '${d.id}'),
              const SizedBox(height: 4),
              _DialogLabel('商品', d.productName ?? '-'),
              const SizedBox(height: 4),
              _DialogLabel('订单编号', d.orderSn ?? '-'),
              const SizedBox(height: 12),
              TextField(
                key: AppKeys.dialogReasonInput,
                controller: reasonController,
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
                  value: refund,
                  onChanged: (v) => setDialogState(() => refund = v),
                  activeTrackColor: const Color(0xFF3B82F6),
                ),
              ]),
              const SizedBox(height: 12),
              CheckboxListTile(
                key: AppKeys.dialogRiskCheckbox,
                value: confirmed,
                onChanged: (v) => setDialogState(() => confirmed = v ?? false),
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
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).commonCancel, style: const TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              key: AppKeys.dialogConfirmDiscard,
              onPressed: confirmed
                  ? () {
                      Navigator.pop(ctx);
                      _doDiscard(widget.itemId, reason: reasonController.text.isNotEmpty ? reasonController.text : null, refund: refund);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: confirmed ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                foregroundColor: Colors.white,
              ),
              child: const Text('确认丢杯'),
            ),
          ],
        ),
      ),
    );
  }

  /// 执行取消 / 强制取消请求
  Future<void> _doCancel({String? reason, bool? refund}) async {
    jobIO(() async {
      final body = OrderItemBatchCancelRequestBody(
        itemIds: [widget.itemId],
        reason: reason,
        refund: refund,
      );
      final response = await ApiServer.instance.orderItemBatchCancel(body);
      final data = response?.take();
      if (mounted && data == true) {
        EasyLoading.showSuccess(AppLocalizations.of(context).orderCancelSubmit);
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
        EasyLoading.showSuccess(AppLocalizations.of(context).orderDiscardSent);
        _loadDetail();
      }
    }, onFinally: () => EasyLoading.dismiss(), toastEnable: true);
  }

  @override
  Widget build(BuildContext context) {
    final action = _actionForStatus();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('工单详情'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(key: AppKeys.orderItemBackButton, icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: action != null
            ? [
                if (action.type == 'discard')
                  IconButton(
                    key: AppKeys.orderItemBtnDiscard,
                    icon: const Icon(Icons.delete_outline, size: 22),
                    tooltip: action.label,
                    onPressed: _showDiscardDialog,
                  )
                else
                  TextButton(
                    key: action.type == 'cancel' ? AppKeys.orderItemBtnCancel : AppKeys.orderItemBtnForceCancel,
                    onPressed: action.type == 'cancel' ? _showCancelDialog : _showForceCancelDialog,
                    child: Text(action.label, style: TextStyle(color: action.color, fontWeight: FontWeight.w600)),
                  ),
              ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : _detail == null
              ? const Center(child: Text('工单不存在', style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  _buildItemInfo(),
                  const SizedBox(height: 12),
                  _buildTimeline(),
                  const SizedBox(height: 12),
                  _buildPaymentInfo(),
                  const SizedBox(height: 12),
                  _buildMaterialSnap(),
                ]),
    );
  }

  /// 工单基本信息
  Widget _buildItemInfo() {
    final d = _detail;
    if (d == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(d.productName ?? '工单 #${d.id}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
          _MakeStatusTag(d.makeStatus),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Text('工单ID：${d.id}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(width: 4),
          GestureDetector(
            key: AppKeys.orderItemCopyId,
            onTap: () => ClipboardUtil.copy('${d.id}'),
            child: const Icon(Icons.copy, size: 13, color: Color(0xFF94A3B8)),
          ),
        ]),
        const SizedBox(height: 2),
        Row(children: [
          Text('订单编号：${d.orderSn ?? '-'}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(width: 4),
          GestureDetector(
            key: AppKeys.orderItemCopySn,
            onTap: () => ClipboardUtil.copy(d.orderSn ?? ''),
            child: const Icon(Icons.copy, size: 13, color: Color(0xFF94A3B8)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('SKU：${d.skuName ?? '-'}', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const Divider(height: 20),
        _InfoPair('商品名称', d.productName),
        _InfoPair('SKU', d.skuName),
        _InfoPair('单价', '¥${(d.unitPrice ?? 0).toStringAsFixed(2)}'),
        _InfoPair('交付模式', deliveryTypeLabel(d.deliveryType)),
        if (d.slotNo?.isNotEmpty == true) _InfoPair('存储槽位', d.slotNo),
        _InfoPair('支付方式', payTypeLabel(d.payType)),
        _InfoPair('支付状态', payStatusLabel(d.payStatus)),
        if (d.makeStatus == 'CANCEL' && d.cancelReason?.isNotEmpty == true)
          _InfoPair('取消原因', cancelReasonLabel(d.cancelReason)),
      ]),
    );
  }

  /// 制作时间线
  Widget _buildTimeline() {
    final d = _detail;
    if (d == null) return const SizedBox.shrink();
    final steps = <_TimelineStep>[];

    if (d.createTime != null) steps.add(_TimelineStep(label: '下单', time: d.createTime ?? 0));
    if (d.payTime != null) steps.add(_TimelineStep(label: '支付', time: d.payTime ?? 0));
    if (d.makeStartTime != null) steps.add(_TimelineStep(label: '开始制作', time: d.makeStartTime ?? 0));
    if (d.makeEndTime != null) steps.add(_TimelineStep(label: '制作完成', time: d.makeEndTime ?? 0));
    if (d.storageTime != null) steps.add(_TimelineStep(label: '已存储', time: d.storageTime ?? 0));
    if (d.makeReadyTime != null) steps.add(_TimelineStep(label: '待取餐', time: d.makeReadyTime ?? 0));
    if (d.makePickupTime != null) steps.add(_TimelineStep(label: '已取走', time: d.makePickupTime ?? 0));

    final allLabels = ['下单', '支付', '开始制作', '制作完成', '已存储', '待取餐', '已取走'];
    final completedLabels = steps.map((s) => s.label).toList();
    final currentIdx = completedLabels.length;
    final isFailed = d.makeStatus == 'FAILED';
    final isCancelled = d.makeStatus == 'CANCEL';

    /// 取消原因文本
    final cancelledMsg = d.cancelReason?.isNotEmpty == true ? cancelReasonLabel(d.cancelReason) : '工单已取消';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('制作时间线', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        const SizedBox(height: 14),
        for (int i = 0; i < allLabels.length; i++)
          _TimelineRow(
            label: allLabels[i],
            step: i < steps.length ? steps[i] : null,
            isDone: i < currentIdx,
            isCurrent: i == currentIdx && !isFailed && !isCancelled,
            isError: (isFailed || isCancelled) && i == currentIdx,
            isLast: i == allLabels.length - 1,
            lineColor: i < currentIdx - 1 ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
            failedMessage: isFailed ? '制作过程中发生错误' : null,
            cancelledMessage: isCancelled ? cancelledMsg : null,
          ),
      ]),
    );
  }

  /// 支付信息
  Widget _buildPaymentInfo() {
    final d = _detail;
    if (d == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('支付信息', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
        if (d.createTime != null) _InfoPair('下单时间', formatTimestampFull(d.createTime)),
        if (d.payTime != null) _InfoPair('支付时间', formatTimestampFull(d.payTime)),
        _InfoPair('支付方式', payTypeLabel(d.payType)),
        _InfoPair('支付状态', payStatusLabel(d.payStatus)),
        _InfoPair('单价', '¥${(d.unitPrice ?? 0).toStringAsFixed(2)}'),
      ]),
    );
  }

  /// 物料配方快照
  Widget _buildMaterialSnap() {
    final snap = _detail?.snap;
    if (snap == null) return const SizedBox.shrink();
    final product = snap.product;
    final materials = snap.material ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('制作配方', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        const SizedBox(height: 10),
        if (product != null) ...[
          const Text('商品信息', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
          const SizedBox(height: 4),
          if (product.productName?.isNotEmpty == true) _InfoPair('商品名称', product.productName),
          if (product.skuName?.isNotEmpty == true) _InfoPair('SKU', product.skuName),
        ],
        if (materials.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('物料明细', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
          const SizedBox(height: 4),
          ...materials.map((m) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(m.productMaterielName ?? m.displayName ?? '-', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                if (m.valueName?.isNotEmpty == true) () { final vn = m.valueName ?? ''; return Text(vn, style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6))); }(),
              ]),
              if (m.value?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text('用量：${m.value}${m.unit ?? ''}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              ],
            ]),
          )),
        ],
      ]),
    );
  }
}

/// 时间线单行组件
class _TimelineRow extends StatelessWidget {
  final String label;
  final _TimelineStep? step;
  final bool isDone;
  final bool isCurrent;
  final bool isError;
  final bool isLast;
  final Color lineColor;
  final String? failedMessage;
  final String? cancelledMessage;

  const _TimelineRow({
    required this.label,
    this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isError,
    required this.isLast,
    required this.lineColor,
    this.failedMessage,
    this.cancelledMessage,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isDone
        ? const Color(0xFF10B981)
        : isError
            ? const Color(0xFFEF4444)
            : isCurrent
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE2E8F0);
    final timeText = isDone && step != null
        ? formatTimestampShort(step?.time ?? 0)
        : isError
            ? (failedMessage ?? '失败')
            : isCurrent
                ? '进行中'
                : '';
    final labelColor = isDone || isCurrent ? const Color(0xFF1E293B) : const Color(0xFF94A3B8);
    final labelWeight = isDone || isCurrent ? FontWeight.w600 : FontWeight.normal;
    final timeColor = isDone ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1);

    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        SizedBox(
          width: 52,
          child: Text(timeText, style: TextStyle(fontSize: 10, color: timeColor)),
        ),
        SizedBox(
          width: 24,
          child: Column(children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: isCurrent ? const Color(0xFF3B82F6) : Colors.transparent, width: 2),
              ),
            ),
            Expanded(child: Container(width: 2, color: isLast ? Colors.transparent : lineColor)),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: TextStyle(fontSize: 14, fontWeight: labelWeight, color: labelColor)),
                if (isError)
                  Text(
                    cancelledMessage ?? failedMessage ?? '',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                  ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

/// 信息对（label: value）
class _InfoPair extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoPair(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
        Expanded(child: Text(value ?? '-', style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
      ]),
    );
  }
}

/// 制作状态标签
class _MakeStatusTag extends StatelessWidget {
  final String? status;
  const _MakeStatusTag(this.status);

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(makeStatusLabel(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
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

/// 时间线步骤
class _TimelineStep {
  final String label;
  final int time;
  const _TimelineStep({required this.label, required this.time});
}

/// 弹窗内信息行
class _DialogLabel extends StatelessWidget {
  final String label;
  final String value;
  const _DialogLabel(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: [
        TextSpan(text: '$label：', style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
        TextSpan(text: value, style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
