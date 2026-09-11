import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/domain_cache.dart';
import 'package:operation/ext/enums.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/api_device.dart';
import 'package:operation/net/api_request.dart';
import 'package:operation/net/api_response.dart';
import 'package:operation/net/mqtt_manager.dart';
import 'package:operation/net/request_server.dart';
import 'package:operation/page/page_remote_control.dart';
import 'package:operation/page/page_device_detail.dart';
import 'package:operation/page/page_stock.dart';
import 'package:operation/widget/widget_device_drawer.dart';
import 'package:operation/ext/app_keys.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// author: AI   2026/5/2
/// 设备列表页面
/// 展示全网设备列表，支持搜索、在线状态筛选、电气数据快照、
/// 故障告警展示、库存预警标记、底部库存/状态/控制按钮。
class DeviceListPage extends StatefulWidget {
  /// 设备树数据，优先从首页传入以避免重复 API 请求
  final List<OperationOperatorVo>? operators;
  const DeviceListPage({super.key, this.operators});

  /// 跳转到设备列表页面
  /// [operators] 设备树数据，从首页传入可避免重复 API 请求
  static void actionStart({List<OperationOperatorVo>? operators}) {
    RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(builder: (_) => DeviceListPage(operators: operators)));
  }

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

/// 扁平化后的设备卡片数据（设备树信息 + 实时状态客户端合并）
class DeviceCardData {
  /// 设备ID
  final int? deviceId;
  /// 设备名称
  final String? deviceName;
  /// 设备编码
  final String? deviceCode;
  /// 店铺ID
  final int? storeId;
  /// 设备型号
  final String? model;
  /// 在线状态（来自 /operation/devices）
  final OnlineStatus? onlineStatus;
  /// 设备运行状态（来自 /operation/devices/status）
  final DeviceRunState? runState;
  /// 电气数据快照
  final OperationDeviceElectricalVo? electrical;
  /// 故障码列表
  final List<DeviceErrorKey> errors;
  /// 告警码列表
  final List<DeviceWaringKey> warnings;
  /// 库存预警明细
  final List<DeviceStockAlertVo> stockAlerts;
  /// 当前不可用的设备组件槽位
  final List<CompUnavailableSlot> compUnavailable;

  const DeviceCardData({
    this.deviceId,
    this.deviceName,
    this.deviceCode,
    this.storeId,
    this.model,
    this.onlineStatus,
    this.runState,
    this.electrical,
    this.errors = const [],
    this.warnings = const [],
    this.stockAlerts = const [],
    this.compUnavailable = const [],
  });

  /// 是否存在缺货
  bool get hasSoldOut => stockAlerts.any((a) => a.level == StockAlertLevel.SOLD_OUT);
  /// 是否存在低库存预警
  bool get hasLowStock => stockAlerts.any((a) => a.level == StockAlertLevel.LOW_STOCK);
  /// 是否存在故障
  bool get hasFault => errors.isNotEmpty;
  /// 是否存在告警
  bool get hasWarning => warnings.isNotEmpty;
  /// 是否存在不可用组件
  bool get hasUnavailable => compUnavailable.isNotEmpty;
}

/// 在线状态筛选枚举
enum _OnlineFilter { all, online, offline }

/// DeviceListPage 的状态管理类
/// 混入 _Bloc 获取 StreamData 响应式状态能力
class _DeviceListPageState extends State<DeviceListPage> with _Bloc {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  /// 下拉刷新控制器
  final RefreshController _refreshController = RefreshController();
  /// 搜索框控制器
  final TextEditingController _searchController = TextEditingController();
  /// 管理域默认值是否已根据国际化初始化
  bool _domainInitialized = false;

  @override
  void initState() {
    super.initState();
    // 使用首页传入的设备树数据（若有），避免重复加载
    final ops = widget.operators;
    if (ops != null && ops.isNotEmpty) {
      _operatorsValue = ops;
    }
    // 加载设备状态数据
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_domainInitialized) {
      _domainInitialized = true;
      _selectedDomainValue = DeviceSelection(label: AppLocalizations.of(context).drawerAllDevices);
    }
  }

  /// 并行加载设备树（无缓存时）和设备实时状态
  Future<void> _loadData() async {
    jobIO(
      () async {
        // 加载设备树（若需要）
        if (_operatorsValue == null || (_operatorsValue?.isEmpty ?? true)) {
          await _loadDevices();
        }
        // 加载设备实时状态（内部直接调用 _mergeWithOperators）
        await _loadDeviceStatus();
      },
      onFinally: () {
        if (mounted) {
          // 结束下拉刷新
          _refreshController.refreshCompleted(resetFooterState: true);
          // 关闭加载动画
          EasyLoading.dismiss();
          // loading 已在 _mergeWithOperators 中设为 false，此处兜底
          final currentLoading = _isLoadingValue;
          if (currentLoading) {
            _isLoadingValue = false;
          }
        }
      },
      toastEnable: true,
    );
  }

  /// 加载设备树（运营商 → 店铺 → 设备）
  Future<void> _loadDevices() async {
    try {
      // 调用设备列表接口
      final response = await ApiServer.instance.devices();
      // 安全解包响应
      final data = response?.take();
      if (data != null) {
        // 写入设备树流
        _operatorsValue = data;
      }
    } catch (_) {}
  }

  /// 加载设备实时状态
  Future<void> _loadDeviceStatus() async {
    try {
      // 构建查询请求体，搜索关键词为空时不过滤
      final keyword = _searchController.text.isNotEmpty ? _searchController.text : null;
      // 调用设备状态接口
      final response = await ApiServer.instance.devicesStatus(OperationDeviceStatusRequestBody(keyword: keyword));
      // 解包响应：take() 为扩展方法，失败时自动 toast
      final data = response?.take();
      if (data != null) {
        _mergeWithOperators(data);
      }
    } catch (_) {}
  }

  /// 合并设备树和设备状态数据，生成扁平化设备卡片列表并写入流
  /// [statusList] 设备实时状态列表
  void _mergeWithOperators(List<OperationDeviceStatusVo> statusList) {
    // 关闭 loading：StreamData 推流
    _isLoadingValue = false;

    // 从设备树中提取 onlineStatus 和 storeId，按 deviceId 建立索引
    final Map<int, OnlineStatus> onlineStatusMap = {};
    final Map<int, int> storeIdMap = {};
    final ops = _operatorsValue;
    if (ops != null) {
      for (final op in ops) {
        final stores = op.stores;
        if (stores == null) continue;
        for (final store in stores) {
          final devices = store.devices;
          if (devices == null) continue;
          for (final device in devices) {
            final id = device.id;
            if (id != null) {
              final status = device.onlineStatus;
              if (status != null) {
                onlineStatusMap[id] = status;
              }
              final sId = device.storeId ?? store.storeId;
              if (sId != null) {
                storeIdMap[id] = sId;
              }
            }
          }
        }
      }
    }

    // 以设备状态列表为基准，合并 onlineStatus
    final cards = <DeviceCardData>[];
    for (final status in statusList) {
      cards.add(DeviceCardData(
        deviceId: status.deviceId,
        deviceName: status.deviceName,
        deviceCode: status.deviceCode,
        storeId: storeIdMap[status.deviceId],
        model: status.model,
        onlineStatus: onlineStatusMap[status.deviceId],
        runState: status.runState,
        electrical: status.electrical,
        errors: status.errors,
        warnings: status.warnings,
        stockAlerts: status.stockAlerts,
        compUnavailable: status.compUnavailable,
      ));
    }

    // 写入全量列表流
    _devicesValue = cards;
    // 触发筛选，写入筛选后列表流
    _applyFilters();
  }

  /// 应用管理域筛选 + 在线状态筛选，写入筛选后列表流
  void _applyFilters() {
    final cards = _devicesValue ?? [];
    var filtered = cards;

    // 管理域筛选：若选了具体设备，仅显示该设备
    final domain = _selectedDomainValue;
    if (domain != null && domain.deviceId != null) {
      filtered = filtered.where((d) => d.deviceId == domain.deviceId).toList();
    }

    // 在线状态筛选
    final filter = _onlineFilterValue;
    switch (filter) {
      case _OnlineFilter.online:
        filtered = filtered.where((d) => d.onlineStatus == OnlineStatus.ONLINE || d.onlineStatus == OnlineStatus.RECONNECTION).toList();
        break;
      case _OnlineFilter.offline:
        filtered = filtered.where((d) => d.onlineStatus == OnlineStatus.OFFLINE).toList();
        break;
      case _OnlineFilter.all:
        break;
    }

    // 写入筛选后列表流，触发 UI StreamBuilder 重建
    _filteredDevicesValue = filtered;
  }

  /// 下拉刷新
  void _onRefresh() {
    // 清空缓存
    _operatorsValue = null;
    _devicesValue = [];
    _filteredDevicesValue = [];
    // 重新加载
    _loadData();
  }

  /// 在线状态筛选切换
  /// [filter] 新的筛选选项
  void _onFilterChanged(_OnlineFilter filter) {
    // 写入筛选状态流
    _onlineFilterValue = filter;
    // 重新应用筛选
    _applyFilters();
  }

  /// 搜索提交
  void _onSearch() {
    _isLoadingValue = true;
    _filteredDevicesValue = [];
    _loadData();
  }

  /// 管理域变更回调
  /// [selection] 用户选择的管理域
  void _onDomainChanged(DeviceSelection selection) {
    // 写入管理域流
    _selectedDomainValue = selection;
    // 重新应用筛选
    _applyFilters();
  }

  /// 库存按钮 → 跳转库存管理页并预选该设备
  /// [device] 被点击的设备卡片数据
  void _onStockTap(DeviceCardData device) {
    // 构造 DeviceSelection 预选该设备
    final selection = DeviceSelection(storeId: null, deviceId: device.deviceId, label: device.deviceName ?? '');
    // 写入全局缓存，库存页 initState 自动读取
    DomainCache.update(selection);
    // 跳转库存管理页，传入设备树避免重复请求
    StockPage.actionStart(operators: _operatorsValue);
  }

  /// 状态按钮 → 跳转设备状态详情页
  /// [device] 被点击的设备卡片数据
  void _onStatusTap(DeviceCardData device) {
    DeviceDetailPage.actionStart(device: device);
  }

  /// 控制按钮 → 跳转远程控制页
  void _onControlTap(DeviceCardData device) {
    final storeId = device.storeId;
    final deviceCode = device.deviceCode;
    if (storeId == null || deviceCode == null || deviceCode.isEmpty) {
      "设备信息不完整，无法打开远程控制".toast();
      return;
    }
    final groupId = MqttManager.instance.groupId ?? '';
    final deviceClientId = groupId.isNotEmpty ? '$groupId@@@$deviceCode' : deviceCode;
    RemoteControlPage.actionStart(device: device, deviceClientId: deviceClientId, storeId: storeId);
  }

  @override
  void dispose() {
    // 释放下拉刷新控制器
    _refreshController.dispose();
    // 释放搜索框控制器
    _searchController.dispose();
    // 释放所有 StreamData 流
    streamDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 使用 StreamBuilder 监听管理域变化，驱动 AppBar 标题刷新
    return StreamBuilder<DeviceSelection?>(
      stream: _selectedDomainStream,
      initialData: _selectedDomainValue,
      builder: (ctx, domainSnap) {
        final domain = domainSnap.data;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          drawerEnableOpenDragGesture: false,
          endDrawerEnableOpenDragGesture: false,
          endDrawer: DeviceDrawer(operators: _operatorsValue ?? [], selected: domain, onSelected: _onDomainChanged),
          appBar: AppBar(
            title: Text(l10n.deviceListTitle),
            centerTitle: true,
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(key: AppKeys.deviceBackButton, icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            actions: [IconButton(key: AppKeys.deviceDomainFilter, icon: const Icon(Icons.widgets_outlined, color: Colors.white), tooltip: l10n.drawerTitle, onPressed: () => _scaffoldKey.currentState?.openEndDrawer())],
          ),
          body: Column(children: [
            _DeviceSearchBar(controller: _searchController, searchHint: l10n.deviceListSearchHint, onSubmitted: _onSearch, onClear: _onSearch),
            _FilterChipsStreamRow(filterAllLabel: l10n.deviceListFilterAll, filterOnlineLabel: l10n.deviceListFilterOnline, filterOfflineLabel: l10n.deviceListFilterOffline, filterStream: _onlineFilterStream, initialFilter: _onlineFilterValue, onChanged: _onFilterChanged),
            _DeviceListStreamHeader(domainStream: _selectedDomainStream, initialDomain: _selectedDomainValue, filteredStream: _filteredDevicesStream, initialFiltered: _filteredDevicesValue, fallbackTitle: l10n.deviceListTitle, totalLabelFn: (int count) => l10n.deviceListTotalCount(count)),
            Expanded(child: _DeviceListStreamBody(isLoadingStream: _isLoadingStream, initialIsLoading: _isLoadingValue, filteredStream: _filteredDevicesStream, initialFiltered: _filteredDevicesValue, emptyHint: l10n.deviceListEmpty, refreshController: _refreshController, onRefresh: _onRefresh, onStockTap: _onStockTap, onStatusTap: _onStatusTap, onControlTap: _onControlTap)),
          ]),
        );
      },
    );
  }
}

/// 设备列表主体的业务逻辑混入
/// 使用 StreamData 响应式容器管理所有页面状态
mixin _Bloc implements IBaseStreamBloc {
  /// 设备树数据（运营商 → 店铺 → 设备）
  final _operators = <OperationOperatorVo>[].streamData;
  List<OperationOperatorVo>? get _operatorsValue => _operators.value;
  set _operatorsValue(List<OperationOperatorVo>? v) => _operators.value = v;

  /// 当前选中的管理域
  final _selectedDomain = DeviceSelection(label: "").streamData;
  DeviceSelection? get _selectedDomainValue => _selectedDomain.value;
  Stream<DeviceSelection?> get _selectedDomainStream => _selectedDomain.stream;
  set _selectedDomainValue(DeviceSelection? v) => _selectedDomain.value = v;

  /// 扁平化合并后的全量设备卡片列表
  final _devices = <DeviceCardData>[].streamData;
  List<DeviceCardData>? get _devicesValue => _devices.value;
  set _devicesValue(List<DeviceCardData>? v) => _devices.value = v;

  /// 筛选后的设备卡片列表
  final _filteredDevices = <DeviceCardData>[].streamData;
  List<DeviceCardData>? get _filteredDevicesValue => _filteredDevices.value;
  Stream<List<DeviceCardData>?> get _filteredDevicesStream => _filteredDevices.stream;
  set _filteredDevicesValue(List<DeviceCardData>? v) => _filteredDevices.value = v;

  /// 当前在线状态筛选
  final _onlineFilter = _OnlineFilter.all.streamData;
  _OnlineFilter get _onlineFilterValue => _onlineFilter.value ?? _OnlineFilter.all;
  Stream<_OnlineFilter?> get _onlineFilterStream => _onlineFilter.stream;
  set _onlineFilterValue(_OnlineFilter v) => _onlineFilter.value = v;

  /// 是否正在加载
  final _isLoading = true.streamData;
  bool get _isLoadingValue => _isLoading.value ?? true;
  Stream<bool?> get _isLoadingStream => _isLoading.stream;
  set _isLoadingValue(bool v) => _isLoading.value = v;

  /// 释放所有 StreamData 流
  @override
  void streamDispose() {
    _operators.dispose();
    _selectedDomain.dispose();
    _devices.dispose();
    _filteredDevices.dispose();
    _onlineFilter.dispose();
    _isLoading.dispose();
  }
}

// ============================================================
// 页面层级 StatelessWidget 组件
// ============================================================

/// 搜索栏
class _DeviceSearchBar extends StatelessWidget {
  /// 搜索框控制器
  final TextEditingController controller;
  /// 搜索框占位文本
  final String searchHint;
  /// 提交搜索回调
  final VoidCallback onSubmitted;
  /// 清空搜索回调
  final VoidCallback onClear;
  const _DeviceSearchBar({required this.controller, required this.searchHint, required this.onSubmitted, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      color: Colors.white,
      child: TextField(
        key: AppKeys.deviceSearchInput,
        controller: controller,
        onSubmitted: (_) => onSubmitted(),
        decoration: InputDecoration(
          hintText: searchHint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { controller.clear(); onClear(); })
              : null,
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

/// 在线状态筛选 Chips 行（通过 StreamBuilder 响应筛选状态变化）
class _FilterChipsStreamRow extends StatelessWidget {
  final String filterAllLabel;
  final String filterOnlineLabel;
  final String filterOfflineLabel;
  final Stream<_OnlineFilter?> filterStream;
  final _OnlineFilter initialFilter;
  final ValueChanged<_OnlineFilter> onChanged;
  const _FilterChipsStreamRow({required this.filterAllLabel, required this.filterOnlineLabel, required this.filterOfflineLabel, required this.filterStream, required this.initialFilter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<_OnlineFilter?>(
      stream: filterStream,
      initialData: initialFilter,
      builder: (ctx, snap) {
        final filter = snap.data ?? _OnlineFilter.all;
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          color: Colors.white,
          child: Row(children: [
            _FilterChipItem(chipKey: AppKeys.deviceFilterAll, label: filterAllLabel, isSelected: filter == _OnlineFilter.all, onTap: () => onChanged(_OnlineFilter.all)),
            const SizedBox(width: 8),
            _FilterChipItem(chipKey: AppKeys.deviceFilterOnline, label: filterOnlineLabel, isSelected: filter == _OnlineFilter.online, color: const Color(0xFF10B981), onTap: () => onChanged(_OnlineFilter.online)),
            const SizedBox(width: 8),
            _FilterChipItem(chipKey: AppKeys.deviceFilterOffline, label: filterOfflineLabel, isSelected: filter == _OnlineFilter.offline, color: const Color(0xFF94A3B8), onTap: () => onChanged(_OnlineFilter.offline)),
          ]),
        );
      },
    );
  }
}

/// 列表头部（通过 StreamBuilder 响应管理域 + 筛选列表变化）
class _DeviceListStreamHeader extends StatelessWidget {
  final Stream<DeviceSelection?> domainStream;
  final DeviceSelection? initialDomain;
  final Stream<List<DeviceCardData>?> filteredStream;
  final List<DeviceCardData>? initialFiltered;
  final String fallbackTitle;
  final String Function(int count) totalLabelFn;
  const _DeviceListStreamHeader({required this.domainStream, required this.initialDomain, required this.filteredStream, required this.initialFiltered, required this.fallbackTitle, required this.totalLabelFn});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DeviceCardData>?>(
      stream: filteredStream,
      initialData: initialFiltered,
      builder: (ctx, listSnap) {
        final count = (listSnap.data ?? []).length;
        return StreamBuilder<DeviceSelection?>(
          stream: domainStream,
          initialData: initialDomain,
          builder: (ctx, domainSnap) {
            final label = domainSnap.data?.label ?? fallbackTitle;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))]),
              child: Row(children: [
                const Icon(Icons.developer_board, size: 18, color: Color(0xFFF97316)),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                Text(totalLabelFn(count), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ]),
            );
          },
        );
      },
    );
  }
}

/// 设备列表主体（列表 StreamBuilder 始终存在以确保首帧订阅；loading 为覆盖层）
class _DeviceListStreamBody extends StatelessWidget {
  /// 加载状态流
  final Stream<bool?> isLoadingStream;
  /// 加载状态初始值
  final bool initialIsLoading;
  /// 筛选列表流
  final Stream<List<DeviceCardData>?> filteredStream;
  /// 筛选列表初始值
  final List<DeviceCardData>? initialFiltered;
  /// 空状态提示
  final String emptyHint;
  /// 下拉刷新控制器
  final RefreshController refreshController;
  /// 刷新回调
  final VoidCallback onRefresh;
  /// 库存按钮回调
  final ValueChanged<DeviceCardData> onStockTap;
  /// 状态按钮回调
  final ValueChanged<DeviceCardData> onStatusTap;
  /// 控制按钮回调
  final ValueChanged<DeviceCardData> onControlTap;

  const _DeviceListStreamBody({required this.isLoadingStream, required this.initialIsLoading, required this.filteredStream, required this.initialFiltered, required this.emptyHint, required this.refreshController, required this.onRefresh, required this.onStockTap, required this.onStatusTap, required this.onControlTap});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // 列表 StreamBuilder — 始终存在，从首帧就订阅流
      StreamBuilder<List<DeviceCardData>?>(
        stream: filteredStream,
        initialData: initialFiltered,
        builder: (ctx, listSnap) {
          final devices = listSnap.data ?? [];
          // 非加载态且列表为空 → 空状态
          if (devices.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.developer_board_off, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(emptyHint, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
              ]),
            );
          }
          // 设备列表
          return SmartRefresher(
            controller: refreshController,
            onRefresh: onRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: devices.length,
              itemBuilder: (context, index) => _DeviceCard(
                index: index,
                device: devices[index],
                onStockTap: () => onStockTap(devices[index]),
                onStatusTap: () => onStatusTap(devices[index]),
                onControlTap: () => onControlTap(devices[index]),
              ),
            ),
          );
        },
      ),
      // loading 覆盖层（不影响内层 StreamBuilder 的订阅生命周期）
      StreamBuilder<bool?>(
        stream: isLoadingStream,
        initialData: initialIsLoading,
        builder: (ctx, snap) {
          if (snap.data != true) return const SizedBox.shrink();
          return const Center(child: CircularProgressIndicator(color: Color(0xFFF97316)));
        },
      ),
    ]);
  }
}

// ============================================================
// 卡片层级 StatelessWidget 组件
// ============================================================

/// 筛选 Chip 按钮
class _FilterChipItem extends StatelessWidget {
  final Key? chipKey;
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChipItem({this.chipKey, required this.label, required this.isSelected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFF97316);
    return GestureDetector(
      key: chipKey,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? c.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? c : Colors.transparent, width: 1),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? c : const Color(0xFF64748B))),
      ),
    );
  }
}

/// 设备卡片（放大字号 + 底部按钮行）
class _DeviceCard extends StatelessWidget {
  /// 列表索引
  final int index;
  /// 设备数据
  final DeviceCardData device;
  /// 库存按钮回调
  final VoidCallback onStockTap;
  /// 状态按钮回调
  final VoidCallback onStatusTap;
  /// 控制按钮回调
  final VoidCallback onControlTap;

  const _DeviceCard({required this.index, required this.device, required this.onStockTap, required this.onStatusTap, required this.onControlTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 在线状态指示灯颜色
    final onlineColor = device.onlineStatus?.dotColor ?? const Color(0xFF94A3B8);
    // 设备运行状态
    final runState = device.runState;
    // 电气数据（安全解引用）
    final electrical = device.electrical;
    // 是否有故障/告警
    final hasAlert = device.hasFault || device.hasWarning;
    // 是否有库存预警
    final hasStockAlert = device.hasSoldOut || device.hasLowStock;

    return Container(
      key: AppKeys.deviceCard(index),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: device.hasFault ? const Border(left: BorderSide(color: Color(0xFFEF4444), width: 4)) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // 第一行：状态圆点 + 运行状态标签 + 设备名称
        Row(children: [
          // 在线状态圆点
          Container(width: 10, height: 10, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: onlineColor, shape: BoxShape.circle)),
          // 运行状态标签
          if (runState != null) ...[
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: runState.badgeColor, borderRadius: BorderRadius.circular(6)), child: Text(runState.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: runState.badgeTextColor))),
            const SizedBox(width: 10),
          ],
          // 设备名称
          Expanded(child: Text(device.deviceName ?? '-', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
        ]),
        const SizedBox(height: 6),
        // 第二行：编号 / 型号
        Text("${device.deviceCode ?? '-'}  |  ${device.model ?? '-'}", style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
        // 第三行：电气数据摘要
        if (electrical != null) ...[const SizedBox(height: 8), _ElectricalRow(electrical: electrical, coldWaterLabel: l10n.deviceListColdWater)],
        const SizedBox(height: 10),
        // 第四行：故障/告警 或 占位文本
        if (hasAlert)
          _AlertTagsRow(errors: device.errors, warnings: device.warnings, alertMoreLabel: (int count) => l10n.deviceListAlertMore(count))
        else
          Text(l10n.deviceListNoAlert, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        const SizedBox(height: 6),
        // 第五行：库存预警 或 占位文本
        if (hasStockAlert)
          _StockAlertRow(hasSoldOut: device.hasSoldOut, hasLowStock: device.hasLowStock, soldOutLabel: l10n.deviceListSoldOut, lowStockLabel: l10n.deviceListLowStock)
        else
          Text(l10n.deviceListNoStockAlert, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        const SizedBox(height: 6),
        // 第六行：不可用组件 或 无
        if (device.hasUnavailable)
          _UnavailableComponentRow(compUnavailable: device.compUnavailable)
        else
          Text(l10n.deviceListNoUnavailable, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        const SizedBox(height: 14),
        // 第六行：底部按钮行
        _CardButtonRow(
          index: index,
          stockLabel: l10n.deviceListBtnStock,
          statusLabel: l10n.deviceListBtnStatus,
          controlLabel: l10n.deviceListBtnControl,
          onStockTap: onStockTap,
          onStatusTap: onStatusTap,
          onControlTap: onControlTap,
        ),
      ]),
    );
  }
}

/// 卡片底部三列按钮行
class _CardButtonRow extends StatelessWidget {
  /// 列表索引
  final int index;
  /// 库存按钮文本
  final String stockLabel;
  /// 状态按钮文本
  final String statusLabel;
  /// 控制按钮文本
  final String controlLabel;
  /// 库存按钮回调
  final VoidCallback onStockTap;
  /// 状态按钮回调
  final VoidCallback onStatusTap;
  /// 控制按钮回调
  final VoidCallback onControlTap;

  const _CardButtonRow({required this.index, required this.stockLabel, required this.statusLabel, required this.controlLabel, required this.onStockTap, required this.onStatusTap, required this.onControlTap});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _CardButton(btnKey: AppKeys.deviceBtnStock(index), label: stockLabel, icon: Icons.inventory_2, color: const Color(0xFF3B82F6), onTap: onStockTap),
      _CardButton(btnKey: AppKeys.deviceBtnStatus(index), label: statusLabel, icon: Icons.assessment, color: const Color(0xFF8B5CF6), onTap: onStatusTap),
      _CardButton(btnKey: AppKeys.deviceBtnControl(index), label: controlLabel, icon: Icons.tune, color: const Color(0xFFF97316), onTap: onControlTap),
    ]);
  }
}

/// 单个卡片按钮
class _CardButton extends StatelessWidget {
  /// 按钮 Key
  final Key? btnKey;
  /// 按钮文本
  final String label;
  /// 按钮图标
  final IconData icon;
  /// 主题色
  final Color color;
  /// 点击回调
  final VoidCallback onTap;

  const _CardButton({this.btnKey, required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        key: btnKey,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }
}

/// 电气数据摘要行
class _ElectricalRow extends StatelessWidget {
  /// 电气数据
  final OperationDeviceElectricalVo electrical;
  /// 冷水温度前缀
  final String coldWaterLabel;

  const _ElectricalRow({required this.electrical, required this.coldWaterLabel});

  @override
  Widget build(BuildContext context) {
    // 收集有值的电气指标
    final chips = <Widget>[];
    final v = electrical.currentVoltage;
    final cur = electrical.currentCurrent;
    final pwr = electrical.activeActivePower;
    final bt = electrical.bottomTemp;
    final ct = electrical.coldTemp;
    final wu = electrical.waterUsage;

    if (v != null && v > 0) chips.add(_ElecChip(label: "${v}V"));
    if (cur != null && cur > 0) chips.add(_ElecChip(label: "${cur}A"));
    if (pwr != null && pwr > 0) chips.add(_ElecChip(label: "${pwr}W"));
    if (bt != null && bt > 0) chips.add(_ElecChip(label: "$bt℃"));
    if (ct != null && ct > 0) chips.add(_ElecChip(label: "$coldWaterLabel$ct℃"));
    if (wu != null && wu > 0) chips.add(_ElecChip(label: "${wu}L"));

    if (chips.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: c)).toList()));
  }
}

/// 故障/告警标签行
class _AlertTagsRow extends StatelessWidget {
  /// 故障码列表
  final List<DeviceErrorKey> errors;
  /// 告警码列表
  final List<DeviceWaringKey> warnings;
  /// 超出截断时生成 +N 标签的回调
  final String Function(int count) alertMoreLabel;

  const _AlertTagsRow({required this.errors, required this.warnings, required this.alertMoreLabel});

  @override
  Widget build(BuildContext context) {
    // 故障在前，告警在后，最多展示 3 个标签
    final tags = <Widget>[];
    const maxDisplay = 3;

    for (final err in errors) {
      if (tags.length >= maxDisplay) break;
      tags.add(_AlertTag(label: err.label, color: err.badgeTextColor, bgColor: err.badgeColor));
    }
    for (final waring in warnings) {
      if (tags.length >= maxDisplay) break;
      tags.add(_AlertTag(label: waring.label, color: waring.badgeTextColor, bgColor: waring.badgeColor));
    }

    // 超出截断显示 +N
    final totalCount = errors.length + warnings.length;
    if (totalCount > maxDisplay) {
      tags.add(_AlertTag(label: alertMoreLabel(totalCount - maxDisplay), color: const Color(0xFF64748B), bgColor: const Color(0xFFF1F5F9)));
    }

    return Wrap(spacing: 6, runSpacing: 4, children: tags);
  }
}

/// 库存预警标记行
class _StockAlertRow extends StatelessWidget {
  /// 是否有缺货
  final bool hasSoldOut;
  /// 是否有低库存
  final bool hasLowStock;
  /// 缺货标签
  final String soldOutLabel;
  /// 低库存标签
  final String lowStockLabel;

  const _StockAlertRow({required this.hasSoldOut, required this.hasLowStock, required this.soldOutLabel, required this.lowStockLabel});

  @override
  Widget build(BuildContext context) {
    final tags = <Widget>[];
    if (hasSoldOut) {
      tags.add(_AlertTag(label: soldOutLabel, color: const Color(0xFFEF4444), bgColor: const Color(0xFFFEF2F2)));
    }
    if (hasLowStock) {
      tags.add(_AlertTag(label: lowStockLabel, color: const Color(0xFFF59E0B), bgColor: const Color(0xFFFFFBEB)));
    }
    if (tags.isEmpty) return const SizedBox.shrink();

    return Row(children: tags.map((t) => Padding(padding: const EdgeInsets.only(right: 6), child: t)).toList());
  }
}

/// 电气数据 Chip
class _ElecChip extends StatelessWidget {
  /// 显示文本
  final String label;
  const _ElecChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0369A1))),
    );
  }
}

/// 告警/故障标签
class _AlertTag extends StatelessWidget {
  /// 标签文本
  final String label;
  /// 文字颜色
  final Color color;
  /// 背景颜色
  final Color bgColor;
  const _AlertTag({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

/// 不可用组件行
class _UnavailableComponentRow extends StatelessWidget {
  /// 不可用组件槽位列表
  final List<CompUnavailableSlot> compUnavailable;

  const _UnavailableComponentRow({required this.compUnavailable});

  @override
  Widget build(BuildContext context) {
    if (compUnavailable.isEmpty) return const SizedBox.shrink();

    final tags = compUnavailable.map((slot) {
      final label = slot.compCode != null ? "${slot.compCode}[${slot.index ?? 0}]" : "[${slot.index ?? 0}]";
      return _AlertTag(label: label, color: const Color(0xFFEF4444), bgColor: const Color(0xFFFEF2F2));
    }).toList();

    // 多标签时允许换行，避免窄屏 RenderFlex 横向溢出
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags,
    );
  }
}
