import 'package:flutter/material.dart';
import 'package:operation/ext/app_keys.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/l10n/app_localizations_en.dart';
import 'package:operation/net/api_response.dart';

/// 设备选择结果，记录选中管理域及其展示标签
class DeviceSelection {
  /// 运营商ID
  final int? operatorId;
  /// 店铺ID
  final int? storeId;
  /// 设备ID
  final int? deviceId;
  /// 展示标签
  final String label;

  const DeviceSelection({this.operatorId, this.storeId, this.deviceId, required this.label});
}

// ============================================================
// 管理域选择侧边抽屉（现有组件，保留不变）
// ============================================================

/// 管理域选择侧边抽屉
class DeviceDrawer extends StatefulWidget {
  /// 设备树数据
  final List<OperationOperatorVo> operators;
  /// 当前选中的管理域
  final DeviceSelection? selected;
  /// 选择回调
  final ValueChanged<DeviceSelection>? onSelected;

  const DeviceDrawer({super.key, required this.operators, this.selected, this.onSelected});

  @override
  State<DeviceDrawer> createState() => _DeviceDrawerState();
}

class _DeviceDrawerState extends State<DeviceDrawer> {
  void _onSelect(DeviceSelection selection) {
    widget.onSelected?.call(selection);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.82,
      child: SafeArea(
        child: Column(children: [
          _DrawerHeader(onClose: () => Navigator.pop(context)),
          Expanded(
            child: DeviceTreeView(
              operators: widget.operators,
              selected: widget.selected,
              onSelected: _onSelect,
              compact: false,
            ),
          ),
        ]),
      ),
    );
  }
}

// ============================================================
// 可复用的设备树视图（Drawer / BottomSheet / 内嵌均可使用）
// ============================================================

/// 设备树选择视图
/// 可用于 Drawer、BottomSheet 或直接嵌入页面中
/// [compact] 为 true 时使用更紧凑的间距，适合嵌入页面
class DeviceTreeView extends StatefulWidget {
  /// 设备树数据
  final List<OperationOperatorVo> operators;
  /// 当前选中的管理域
  final DeviceSelection? selected;
  /// 选择回调（不关闭父容器，由调用方决定如何关闭）
  final ValueChanged<DeviceSelection>? onSelected;
  /// 是否紧凑模式（嵌入页面时使用）
  final bool compact;

  const DeviceTreeView({super.key, required this.operators, this.selected, this.onSelected, this.compact = false});

  @override
  State<DeviceTreeView> createState() => _DeviceTreeViewState();
}

class _DeviceTreeViewState extends State<DeviceTreeView> {
  /// 搜索文本控制器
  final TextEditingController _searchController = TextEditingController();
  /// 搜索文本
  String _searchText = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 是否选中"全部设备"
  bool get _isAllSelected =>
      widget.selected?.operatorId == null && widget.selected?.storeId == null && widget.selected?.deviceId == null;

  /// 按搜索文本过滤后的设备树
  List<OperationOperatorVo> get _filteredOperators {
    if (_searchText.isEmpty) return widget.operators;
    final query = _searchText.toLowerCase();
    return widget.operators
        .map((op) => OperationOperatorVo(
              operatorId: op.operatorId,
              operatorName: op.operatorName,
              stores: op.stores?.map((s) => _filterStore(s, query)).where((s) => s != null).cast<OperationStoreVo>().toList(),
            ))
        .toList();
  }

  /// 按查询过滤单个店铺的设备
  OperationStoreVo? _filterStore(OperationStoreVo store, String query) {
    final filteredDevices = store.devices?.where((d) =>
        (d.name?.toLowerCase().contains(query) ?? false) ||
        (d.deviceCode?.toLowerCase().contains(query) ?? false) ||
        (d.model?.toLowerCase().contains(query) ?? false)).toList();
    if ((store.storeName?.toLowerCase().contains(query) ?? false) || (filteredDevices?.isNotEmpty ?? false)) {
      return OperationStoreVo(storeId: store.storeId, storeName: store.storeName, devices: filteredDevices ?? store.devices);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final filtered = _filteredOperators;
    return Column(children: [
      if (!widget.compact)
        _DrawerHeader(onClose: () {}),
      _buildSearchBar(l10n),
      Expanded(
        child: ListView(padding: EdgeInsets.zero, children: [
          _AllDevicesItem(isSelected: _isAllSelected, compact: widget.compact, onTap: () => widget.onSelected?.call(DeviceSelection(label: l10n.drawerAllDevices))),
          ...filtered.map((op) => _OperatorTile(operator: op, selected: widget.selected, compact: widget.compact, onSelect: (sel) => widget.onSelected?.call(sel))),
        ]),
      ),
    ]);
  }

  /// 搜索栏
  Widget _buildSearchBar(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 12 : 16, vertical: widget.compact ? 6 : 8),
      child: TextField(
        key: AppKeys.drawerSearchInput,
        controller: _searchController,
        onChanged: (v) => setState(() => _searchText = v),
        decoration: InputDecoration(
          hintText: l10n.drawerSearchHint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          filled: true,
          fillColor: const Color(0xFFF2F4F6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

// ============================================================
// StatelessWidget 组件
// ============================================================

/// 抽屉/弹窗顶部标题栏
class _DrawerHeader extends StatelessWidget {
  /// 关闭按钮回调
  final VoidCallback onClose;
  const _DrawerHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(l10n.drawerTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        IconButton(key: AppKeys.drawerCloseButton, icon: const Icon(Icons.close, color: Color(0xFF94A3B8)), onPressed: onClose),
      ]),
    );
  }
}

/// "全部设备" 选项
class _AllDevicesItem extends StatelessWidget {
  /// 是否选中
  final bool isSelected;
  /// 是否紧凑模式
  final bool compact;
  /// 点击回调
  final VoidCallback onTap;
  const _AllDevicesItem({required this.isSelected, this.compact = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    return GestureDetector(
      key: AppKeys.drawerAllDevicesItem,
      onTap: onTap,
      child: Container(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 10 : 14),
        child: Row(children: [
          Icon(Icons.devices, size: 20, color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.drawerAllDevices, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
          if (isSelected) const Icon(Icons.check, size: 20, color: Color(0xFF3B82F6)),
        ]),
      ),
    );
  }
}

/// 运营商分组
class _OperatorTile extends StatelessWidget {
  /// 运营商数据
  final OperationOperatorVo operator;
  /// 当前选中
  final DeviceSelection? selected;
  /// 是否紧凑模式
  final bool compact;
  /// 选择回调
  final ValueChanged<DeviceSelection> onSelect;
  const _OperatorTile({required this.operator, required this.selected, this.compact = false, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final isOpSelected = selected?.operatorId == operator.operatorId && selected?.storeId == null;
    final hPadding = compact ? 12.0 : 16.0;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: hPadding),
        initiallyExpanded: selected?.operatorId == operator.operatorId,
        leading: Icon(Icons.business, size: 20, color: isOpSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
        title: GestureDetector(
          onTap: () => onSelect(DeviceSelection(operatorId: operator.operatorId, label: operator.operatorName ?? l10n.drawerDefaultOperator)),
          child: Container(
            color: isOpSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: Text(operator.operatorName ?? "-", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isOpSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B)))),
              if (isOpSelected) const Icon(Icons.check, size: 18, color: Color(0xFF3B82F6)),
            ]),
          ),
        ),
        children: operator.stores?.map((store) => _StoreTile(store: store, operatorId: operator.operatorId, selected: selected, compact: compact, onSelect: onSelect)).toList() ?? [],
      ),
    );
  }
}

/// 店铺分组
class _StoreTile extends StatelessWidget {
  /// 店铺数据
  final OperationStoreVo store;
  /// 运营商ID
  final int? operatorId;
  /// 当前选中
  final DeviceSelection? selected;
  /// 是否紧凑模式
  final bool compact;
  /// 选择回调
  final ValueChanged<DeviceSelection> onSelect;
  const _StoreTile({required this.store, required this.operatorId, required this.selected, this.compact = false, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final isStoreSelected = selected?.storeId == store.storeId && selected?.deviceId == null;
    final leftPadding = compact ? 36.0 : 48.0;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(left: leftPadding, right: 16),
        initiallyExpanded: selected?.storeId == store.storeId,
        leading: Icon(Icons.store, size: 18, color: isStoreSelected ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8)),
        title: GestureDetector(
          onTap: () => onSelect(DeviceSelection(operatorId: operatorId, storeId: store.storeId, label: store.storeName ?? l10n.drawerDefaultStore)),
          child: Container(
            color: isStoreSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: Text(store.storeName ?? "-", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isStoreSelected ? const Color(0xFF3B82F6) : const Color(0xFF475569)))),
              if (isStoreSelected) const Icon(Icons.check, size: 16, color: Color(0xFF3B82F6)),
            ]),
          ),
        ),
        children: store.devices?.map((device) => _DeviceItem(device: device, operatorId: operatorId, selected: selected, compact: compact, onSelect: onSelect)).toList() ?? [],
      ),
    );
  }
}

/// 设备选项
class _DeviceItem extends StatelessWidget {
  /// 设备数据
  final OperationDeviceItemVo device;
  /// 运营商ID
  final int? operatorId;
  /// 当前选中
  final DeviceSelection? selected;
  /// 是否紧凑模式
  final bool compact;
  /// 选择回调
  final ValueChanged<DeviceSelection> onSelect;
  const _DeviceItem({required this.device, required this.operatorId, required this.selected, this.compact = false, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = (AppLocalizations.of(context) ?? AppLocalizationsEn());
    final isSelected = selected?.deviceId == device.id;
    final leftPadding = compact ? 66.0 : 78.0;
    return GestureDetector(
      onTap: () => onSelect(DeviceSelection(operatorId: operatorId, storeId: device.storeId, deviceId: device.id, label: device.name ?? l10n.drawerDefaultDevice)),
      child: Container(
        color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
        padding: EdgeInsets.only(left: leftPadding, right: 16, top: 12, bottom: 12),
        child: Row(children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: device.onlineStatus?.dotColor ?? const Color(0xFF94A3B8), shape: BoxShape.circle)),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(device.name ?? "-", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
              const SizedBox(height: 2),
              Text("${device.deviceCode ?? "-"}  |  ${device.model ?? "-"}", style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ]),
          ),
          if (isSelected) const Icon(Icons.check, size: 18, color: Color(0xFF3B82F6)),
        ]),
      ),
    );
  }
}
