import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/domain_cache.dart';
import 'package:operation/ext/enums.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/api_response.dart';
import 'package:operation/net/api_stock.dart';
import 'package:operation/net/request_server.dart';
import 'package:operation/widget/widget_device_drawer.dart';
import 'package:operation/page/page_stock_record.dart';
import 'package:operation/ext/app_keys.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

/// author: AI   2026/4/30
/// 库存管理页面
/// 提供设备库存查询、数量修改（CLOUD_CALC 模式）、补货（HW 模式）、
/// 物料更换、批量提交等功能，使用自研 Bloc 模式管理状态
class StockPage extends StatefulWidget {
  /// 设备树数据，优先从首页传入以避免重复加载
  final List<OperationOperatorVo>? operators;
  const StockPage({super.key, this.operators});

  /// 跳转到库存管理页面
  /// [operators] 设备树数据，从首页传入可避免重复 API 请求
  static void actionStart({List<OperationOperatorVo>? operators}) {
    RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(builder: (context) => StockPage(operators: operators)));
  }

  @override
  State<StockPage> createState() => _StockPageState();
}

/// 单条库存修改暂存记录
/// key 为字段名（"newStock" / "newMaterielId" / "newSaveMode"），value 为对应的新值
typedef StockModification = Map<String, dynamic>;

/// StockPage 的状态管理类
/// 混入 _Bloc 获取 StreamData 响应式状态能力
class _StockPageState extends State<StockPage> with _Bloc {
  /// 用于打开管理域选择侧边抽屉
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// 下拉刷新控制器
  final RefreshController _refreshController = RefreshController();

  /// 库存提交后的轮询刷新定时器
  /// HW_COLLECT / UNKNOWN / HW_CALC 模式的库存需设备上报或下发后回传，落库存在延迟，
  /// 提交成功后需在一段时间内持续轮询，直到设备侧数据同步完成。
  Timer? _stockPollingTimer;
  /// 轮询已执行次数
  int _stockPollingCount = 0;
  /// 是否有轮询请求正在进行中：慢网络下跳过本次 tick，避免请求堆积触发后端限流
  bool _stockPollingInFlight = false;
  /// 轮询总次数：20 秒内每 2 秒一次，共 10 次
  static const int _stockPollingMaxTimes = 10;
  /// 轮询间隔：2 秒
  static const Duration _stockPollingInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    // 从全局缓存读取上次选择的管理域
    _selectedDomainValue = DomainCache.current;
    // 初始化设备树数据
    _initOperators();
    // 校验管理域级别并加载数据
    _checkDomainAndLoad();
  }

  /// 初始化设备树数据：优先使用页面传入的，否则从 API 加载
  void _initOperators() {
    if (widget.operators != null && widget.operators?.isNotEmpty == true) {
      // 使用上一页传入的数据，避免重复 API 请求
      _operatorsValue = widget.operators;
    } else {
      // 无传入数据，从 API 拉取
      _loadDevices();
    }
  }

  /// 从 API 加载设备树数据（运营商 → 店铺 → 设备）
  Future<void> _loadDevices() async {
    try {
      // 调用设备列表接口
      final response = await ApiServer.instance.devices();
      // 安全解包响应
      final data = response?.take();
      if (mounted && data != null) {
        // 写入设备树流，触发抽屉 StreamBuilder 重建
        _operatorsValue = data;
      }
    } catch (_) {}
  }

  /// 校验管理域级别：库存页必须选中设备级别才可加载数据
  void _checkDomainAndLoad() {
    if (!DomainCache.hasDevice) {
      return;
    }
    // 设备已选中，加载库存数据
    _loadStockData();
    // 物料数据未加载则并行加载
    if (!_materialsLoadedValue) {
      _loadAllMaterials();
    }
  }

  /// 管理域切换回调
  void _onDomainChanged(DeviceSelection selection) {
    // 切换设备时先停止针对旧设备的轮询刷新
    _stopStockPolling();
    _selectedDomainValue = selection;
    DomainCache.update(selection);
    _checkDomainAndLoad();
  }

  /// 构建未选设备时的设备选择页面
  Widget _buildDevicePicker(AppLocalizations l10n) {
    final operators = _operatorsValue ?? [];
    return SafeArea(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
          child: Text(l10n.stockSelectDeviceFirst, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ),
        Expanded(
          child: operators.isEmpty
              ? Center(child: Text(l10n.stockSelectDeviceHint, style: const TextStyle(color: Color(0xFF94A3B8))))
              : DeviceTreeView(
                  operators: operators,
                  selected: _selectedDomainValue,
                  compact: true,
                  onSelected: (sel) {
                    _onDomainChanged(sel);
                    setState(() {});
                  },
                ),
        ),
      ]),
    );
  }

  /// 加载当前设备的库存列表
  /// 通过 [jobIO] 包装异步操作，自动处理 loading 和错误提示
  Future<void> _loadStockData() async {
    // 从选中管理域中获取 deviceId
    final deviceId = _selectedDomain.value?.deviceId;
    if (deviceId == null) return;

    jobIO(() async {
      // 构建查询请求体
      final body = OperationStockQueryRequestBody(deviceId: deviceId);
      // 调用库存查询接口
      final response = await ApiServer.instance.stockQuery(body);
      // 安全解包响应
      final data = response?.take();
      if (mounted && data != null) {
        // 写入库存列表流，触发列表 StreamBuilder 重建
        _stockListValue = data;
        // 加载新数据时清空上次的修改记录
        _modificationsValue = {};
      }
    }, onFinally: () {
      // 结束下拉刷新
      if (mounted) _refreshController.refreshCompleted(resetFooterState: true);
      // 关闭加载动画
      EasyLoading.dismiss();
    }, toastEnable: true);
  }

  /// 静默刷新库存列表（轮询专用）
  /// 与 [_loadStockData] 的区别：不显示 loading、不弹错误 toast、不清空用户暂存的修改记录。
  /// 轮询期间用户可能已开始新一轮编辑，清空修改会丢失其操作。
  Future<void> _reloadStockDataSilently(int pollingDeviceId) async {
    // 页面已销毁则不再请求
    if (!mounted) return;
    // 上一次刷新尚未返回（慢网络），跳过本次 tick，避免请求堆积触发后端限流
    if (_stockPollingInFlight) return;
    // 用户已切换设备，针对旧设备的轮询失去意义，立即停止
    if (_selectedDomain.value?.deviceId != pollingDeviceId) {
      _stopStockPolling();
      return;
    }
    _stockPollingInFlight = true;
    try {
      final body = OperationStockQueryRequestBody(deviceId: pollingDeviceId);
      final data = (await ApiServer.instance.stockQuery(body))?.take(errorShow: false);
      // take 之后可能已跨帧，需再次确认页面存活
      if (mounted && data != null) {
        _stockListValue = data;
      }
    } catch (e) {
      // 轮询失败不打扰用户，仅记录日志，等待下一次轮询重试
      "库存轮询刷新失败: $e".log();
    } finally {
      // 无论成功或异常都复位，否则后续 tick 会被永久跳过
      _stockPollingInFlight = false;
    }
  }

  /// 启动库存提交后的轮询刷新
  /// HW_COLLECT / UNKNOWN / HW_CALC 模式的库存变更依赖设备上报或指令下发后回传，
  /// 服务端落库存在延迟，提交成功后需在 20 秒内每 2 秒静默刷新一次，共 10 次。
  /// 轮询为后台静默行为，不阻塞、不打扰用户继续操作。
  void _startStockPolling() {
    final deviceId = _selectedDomain.value?.deviceId;
    if (deviceId == null) return;
    // 重复提交时先停掉上一轮轮询，避免多个定时器并发刷新
    _stopStockPolling();
    _stockPollingCount = 0;
    "库存提交成功，开始轮询刷新：deviceId=$deviceId，最多 $_stockPollingMaxTimes 次，间隔 ${_stockPollingInterval.inSeconds}s".log();
    _stockPollingTimer = Timer.periodic(_stockPollingInterval, (timer) async {
      // 页面销毁或达到次数上限即停止
      if (!mounted) {
        timer.cancel();
        return;
      }
      _stockPollingCount++;
      await _reloadStockDataSilently(deviceId);
      if (_stockPollingCount >= _stockPollingMaxTimes) {
        "库存轮询刷新完成，共执行 $_stockPollingCount 次".log();
        _stopStockPolling();
      }
    });
  }

  /// 停止库存轮询刷新并复位计数
  void _stopStockPolling() {
    _stockPollingTimer?.cancel();
    _stockPollingTimer = null;
    _stockPollingCount = 0;
    // 复位进行中标记，否则下一轮轮询会被残留状态永久跳过
    _stockPollingInFlight = false;
  }

  /// 加载全部物料数据并按物料类型分组
  /// 结果写入 [_allMaterialsValue]，通过枚举 [GoodsMaterialType] 分组
  Future<void> _loadAllMaterials() async {
    // 调用物料全量查询接口
    final response = await ApiServer.instance.materielQueryAll();
    // 返回值为 Map<String, List<dynamic>>
    final rawMap = response?.take();
    "物料接口返回: ${rawMap?.keys}, 条目数: ${rawMap?.length ?? 0}".log();
    if (rawMap == null) {
      "物料接口返回为空".log();
      return;
    }
    if (!mounted) return;
    // 解析并按物料类型分组
    final parsed = <GoodsMaterialType, List<ProductMaterielVo>>{};
    rawMap.forEach((typeStr, list) {
      // 将 API 字符串转换为枚举，无法识别的类型跳过
      final type = GoodsMaterialType.fromApiValue(typeStr);
      "物料类型解析: $typeStr → $type".log();
      if (type != null && list is List) {
        // 将 JSON 列表解析为 ProductMaterielVo 对象
        parsed[type] = list.map((e) => ProductMaterielVo.fromJson(e as Map<String, dynamic>)).toList();
      }
    });
    "物料解析完成: ${parsed.keys}, 总类别数: ${parsed.length}, 各类条目: ${parsed.map((k, v) => MapEntry(k.label, v.length))}".log();
    // 写入物料数据流
    _allMaterialsValue = parsed;
    // 标记物料已加载
    _materialsLoadedValue = true;
  }

  /// 下拉刷新回调：清空修改记录后重新加载库存
  void _onRefresh() {
    _modificationsValue = {};
    _loadStockData();
  }

  @override
  void dispose() {
    // 取消库存轮询定时器，防止页面销毁后继续触发回调
    _stopStockPolling();
    // 释放下拉刷新控制器
    _refreshController.dispose();
    // 释放所有 StreamData 流
    streamDispose();
    super.dispose();
  }

  /// 撤销指定库存项的修改
  /// [stockId] 库存记录 ID
  void _undoModification(int? stockId) {
    final updated = Map<int?, StockModification>.from(_modificationsValue);
    updated.remove(stockId);
    _modificationsValue = updated;
  }

  /// 应用库存数量编辑变更
  /// [item] 被编辑的库存条目
  /// [value] 输入的数量值（SET 模式为目标值，ADD 模式为增减量）
  /// [saveMode] 保存方式（SET / ADD）
  void _applyStockEdit(DeviceStockVo item, int? value, StockSaveMode saveMode) {
    // 获取该库存项的现有修改记录
    final existing = _modificationsValue[item.id];
    // 构建新的修改项，保留已有的物料变更
    final newMod = <String, dynamic>{'newStock': value, 'newSaveMode': saveMode};
    if (existing != null && existing['newMaterielId'] != null) {
      newMod['newMaterielId'] = existing['newMaterielId'];
    }
    // 复制并更新修改记录，触发 StreamBuilder 重建
    final updated = Map<int?, StockModification>.from(_modificationsValue);
    updated[item.id] = newMod;
    _modificationsValue = updated;
  }

  /// 应用物料更换变更
  /// [item] 被编辑的库存条目
  /// [materielId] 新物料 ID
  void _applyMaterialChange(DeviceStockVo item, int materielId) {
    // 获取该库存项的现有修改记录
    final existing = _modificationsValue[item.id];
    // 构建新的修改项，保留已有的数量变更和保存方式
    final newMod = <String, dynamic>{'newMaterielId': materielId};
    if (existing != null && existing['newStock'] != null) {
      newMod['newStock'] = existing['newStock'];
    }
    if (existing != null && existing['newSaveMode'] != null) {
      newMod['newSaveMode'] = existing['newSaveMode'];
    }
    // 复制并更新修改记录
    final updated = Map<int?, StockModification>.from(_modificationsValue);
    updated[item.id] = newMod;
    _modificationsValue = updated;
  }

  @override
  Widget build(BuildContext context) {
    // 获取国际化字符串
    final l10n = AppLocalizations.of(context);
    // 使用 StreamBuilder 监听管理域变化，驱动标题和内容刷新
    return StreamBuilder<DeviceSelection?>(
      stream: _selectedDomainStream,
      initialData: _selectedDomainValue,
      builder: (context, domainSnap) {
        final domain = domainSnap.data;
        // 判断是否已选择设备级别
        final hasDevice = domain?.deviceId != null;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          drawerEnableOpenDragGesture: false,
          endDrawerEnableOpenDragGesture: false,
          endDrawer: Drawer(
            width: MediaQuery.of(context).size.width * 0.82,
            child: SafeArea(
              child: DeviceTreeView(
                operators: _operatorsValue ?? [],
                selected: _selectedDomainValue,
                onSelected: (sel) {
                  _onDomainChanged(sel);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          appBar: AppBar(
            title: Text(domain?.label ?? l10n.stockPageTitle),
            centerTitle: true,
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(key: AppKeys.stockBackButton, icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
            actions: [
              IconButton(key: AppKeys.stockDomainFilter, icon: const Icon(Icons.widgets_outlined, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openEndDrawer()),
            ],
          ),
          body: !hasDevice ? _buildDevicePicker(l10n) : _buildStockContent(l10n),
        );
      },
    );
  }

  /// 构建库存列表内容区域
  /// [l10n] 国际化对象，避免 StreamBuilder builder 中重复获取
  Widget _buildStockContent(AppLocalizations l10n) {
    // 使用 StreamBuilder 监听库存列表变化
    return StreamBuilder<List<DeviceStockVo>?>(
      stream: _stockListStream,
      initialData: _stockListValue,
      builder: (context, stockSnap) {
        final list = stockSnap.data ?? [];
        return Column(
          children: [
            // 列表头部：设备名 + 项数
            _StockHeader(deviceName: _selectedDomain.value?.label ?? "", count: list.length, deviceId: _selectedDomainValue?.deviceId, deviceLabel: _selectedDomainValue?.label),
            // 下拉刷新 + 库存列表
            Expanded(
              child: SmartRefresher(
                controller: _refreshController,
                onRefresh: _onRefresh,
                child: list.isEmpty
                    ? const _EmptyListHint()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, index) => _StockItemCard(
                          index: index,
                          item: list[index],
                          modificationsStream: _modificationsStream,
                          initialMods: _modificationsValue,
                          allMaterials: _allMaterialsValue,
                          onEditStock: _showStockEditDialog,
                          onPickMaterial: _showMaterialPicker,
                          onUndo: _undoModification,
                          getMaterialName: _getMaterialName,
                        ),
                      ),
              ),
            ),
            // 底部提交按钮
            _StockSubmitBar(modificationsStream: _modificationsStream, initialMods: _modificationsValue, onSubmit: _submitModifications),
          ],
        );
      },
    );
  }

  /// 显示库存修改弹窗
  /// 包含保存方式选择（SET / ADD）、数量输入、结果预览
  /// [item] 被编辑的库存条目
  void _showStockEditDialog(DeviceStockVo item) {
    final l10n = AppLocalizations.of(context);
    // 获取库存模式，CLOUD_CALC 默认 SET，HW 模式默认 ADD（保持现有交互习惯）
    final stockMode = item.stockMode;
    final canSet = stockMode != null && stockMode.isEditable;
    // HW_COLLECT / UNKNOWN 模式数量可选
    final isStockOptional = stockMode == StockMode.HW_COLLECT || stockMode == StockMode.UNKNOWN;
    // 默认保存方式：可选模式只支持 ADD
    final defaultMode = canSet ? StockSaveMode.SET : StockSaveMode.ADD;
    // 库存单位
    final unit = item.unit ?? "";
    final currentStock = item.currentStock ?? 0;
    // 初始值：SET 模式预填当前库存，ADD 模式预填 0；可选模式初始为空（仅记录）
    final initialText = isStockOptional ? "" : (defaultMode == StockSaveMode.SET ? currentStock.toString() : "0");

    showDialog(
      context: context,
      builder: (dialogCtx) {
        // 在 outer builder 作用域声明 selectedMode，StatefulBuilder 通过 setState 修改它
        StockSaveMode selectedMode = defaultMode;
        final controller = TextEditingController(text: initialText);

        return StatefulBuilder(
          builder: (innerCtx, setState) {
            // 计算输入值（用于结果预览）
            final inputValue = int.tryParse(controller.text);
            // 计算结果值
            final resultValue = selectedMode == StockSaveMode.ADD ? currentStock + (inputValue ?? 0) : inputValue;

            return AlertDialog(
              title: Text(selectedMode.actionLabel, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                // 当前库存信息
                Text(l10n.stockCurrentStock(currentStock, unit), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                // 最大容量（若有）
                if ((item.maxStock ?? 0) > 0) () {
                  final max = item.maxStock ?? 0;
                  return Text(l10n.stockMaxStock(max, unit), style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)));
                }(),
                const SizedBox(height: 12),
                // 保存方式选择器
                Text(l10n.stockSaveMode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF475569))),
                const SizedBox(height: 8),
                Row(children: [
                  // SET 方式按钮
                  Expanded(child: GestureDetector(
                    key: AppKeys.stockModeSet,
                    onTap: () => setState(() => selectedMode = StockSaveMode.SET),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedMode == StockSaveMode.SET ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selectedMode == StockSaveMode.SET ? const Color(0xFF3B82F6) : Colors.transparent, width: 1.5),
                      ),
                      child: Column(children: [
                        Text("设置为", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selectedMode == StockSaveMode.SET ? const Color(0xFF3B82F6) : const Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text("直接设定目标值", style: TextStyle(fontSize: 11, color: selectedMode == StockSaveMode.SET ? const Color(0xFF60A5FA) : const Color(0xFF94A3B8))),
                      ]),
                    ),
                  )),
                  const SizedBox(width: 10),
                  // ADD 方式按钮
                  Expanded(child: GestureDetector(
                    key: AppKeys.stockModeAdd,
                    onTap: () => setState(() => selectedMode = StockSaveMode.ADD),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedMode == StockSaveMode.ADD ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selectedMode == StockSaveMode.ADD ? const Color(0xFF10B981) : Colors.transparent, width: 1.5),
                      ),
                      child: Column(children: [
                        Text("增加", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selectedMode == StockSaveMode.ADD ? const Color(0xFF10B981) : const Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text("增减指定数量", style: TextStyle(fontSize: 11, color: selectedMode == StockSaveMode.ADD ? const Color(0xFF34D399) : const Color(0xFF94A3B8))),
                      ]),
                    ),
                  )),
                ]),
                const SizedBox(height: 12),
                // 操作提示
                Text(isStockOptional ? l10n.stockOptionalHint : selectedMode.hintLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                const SizedBox(height: 10),
                // 数量输入框
                TextField(
                  key: AppKeys.stockDialogInput,
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(signed: true),
                  autofocus: !isStockOptional,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(hintText: isStockOptional ? l10n.stockOptionalHint : l10n.stockInputHint, suffixText: unit.isNotEmpty ? unit : null, filled: true, fillColor: const Color(0xFFF2F4F6), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                // 结果预览
                if (isStockOptional && inputValue == null)
                  Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)), child: const Text("仅记录操作，不修改数量", style: TextStyle(fontSize: 12, color: Color(0xFFB45309))))
                else if (inputValue != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: selectedMode == StockSaveMode.ADD ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(selectedMode.resultLabel(currentStock, inputValue), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selectedMode == StockSaveMode.ADD ? const Color(0xFF059669) : const Color(0xFF2563EB)))),
                      // 超限警告
                      if (resultValue != null && (item.maxStock ?? 0) > 0 && resultValue > (item.maxStock ?? 0)) const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF59E0B)),
                    ]),
                  ),
                ],
              ]),
              actions: [
                // 取消按钮
                TextButton(key: AppKeys.dialogStockCancel, onPressed: () => Navigator.pop(dialogCtx), child: Text(l10n.commonCancel, style: const TextStyle(color: Color(0xFF64748B)))),
                // 确定按钮
                TextButton(key: AppKeys.dialogStockConfirm, onPressed: () {
                  final value = int.tryParse(controller.text);
                  // 数量必填模式校验
                  if (!isStockOptional && value == null) {
                    l10n.stockInvalidNumber.toast();
                    return;
                  }
                  // 关闭弹窗
                  Navigator.pop(dialogCtx);
                  // 应用修改（可选模式 value 可为 null，表示仅记录）
                  _applyStockEdit(item, value, selectedMode);
                }, child: Text(l10n.commonConfirm, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600))),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示更换物料的底部弹窗
  /// [item] 被编辑的库存条目，需携带 [productMaterielType] 用于筛选同类型物料
  /// 若 [productMaterielType] 为 null，从物料表中反查类型或展示全部物料
  void _showMaterialPicker(DeviceStockVo item) {
    final l10n = AppLocalizations.of(context);
    // 物料是否已加载
    final materialsLoaded = _materialsLoadedValue;
    "打开物料选择弹窗, materialsLoaded=$materialsLoaded, productMaterielType=${item.productMaterielType}, productMaterielId=${item.productMaterielId}".log();
    if (!materialsLoaded) {
      // 物料未加载，先加载再弹窗
      "物料未加载，开始加载...".log();
      EasyLoading.show(status: l10n.stockLoadingMaterials);
      _loadAllMaterials().then((_) {
        EasyLoading.dismiss();
        "物料加载完成, materialsLoaded=$_materialsLoadedValue".log();
        if (_materialsLoadedValue) {
          _showMaterialPicker(item);
        }
      }).catchError((e) {
        EasyLoading.dismiss();
        "物料加载失败: $e".log();
        l10n.stockLoadMaterialsFailed.toast();
      });
      return;
    }

    // 确定有效的物料类型：优先使用 item 自带类型，否则从物料 ID 反查
    GoodsMaterialType? currentType = item.productMaterielType;
    if (currentType == null && item.productMaterielId != null) {
      // 遍历所有类型查找该物料 ID 所属类型
      for (final entry in _allMaterialsValue.entries) {
        if (entry.value.any((m) => m.id == item.productMaterielId)) {
          currentType = entry.key;
          break;
        }
      }
    }

    // 筛选物料列表：有类型按类型筛选，无类型展示全部
    final List<ProductMaterielVo> sameTypeMaterials;
    final String typeName;
    if (currentType != null) {
      sameTypeMaterials = _allMaterialsValue[currentType] ?? [];
      typeName = currentType.label;
    } else {
      // 类型未知时展示全部物料，按类型分组展平
      sameTypeMaterials = _allMaterialsValue.values.expand((list) => list).toList();
      typeName = l10n.stockUnknownMaterial;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55, maxChildSize: 0.8, minChildSize: 0.3, expand: false,
        builder: (ctx, scrollController) => Column(children: [
          // 拖拽指示条
          Container(margin: const EdgeInsets.only(top: 10), width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          // 弹窗标题
          Text(l10n.stockPickMaterialTitle(typeName), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
          const SizedBox(height: 4),
          // 当前物料
          Text(l10n.stockCurrentMaterial(item.productMaterielName ?? l10n.stockCurrentMaterialNone), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 12),
          // 物料列表
          Expanded(
            child: sameTypeMaterials.isEmpty
                ? Center(child: Text(l10n.stockNoAvailableMaterial, style: const TextStyle(color: Color(0xFF94A3B8))))
                : ListView.separated(
                    controller: scrollController,
                    itemCount: sameTypeMaterials.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final mat = sameTypeMaterials[index];
                      // 判断物料是否已被选中（原始绑定 或 修改记录中）
                      final currentMod = _modificationsValue[item.id];
                      final isSelected = mat.id == item.productMaterielId || mat.id == currentMod?['newMaterielId'];
                      return ListTile(
                        title: Text(mat.name ?? l10n.stockUnknownMaterial, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                        subtitle: () { final d = mat.description; return d?.isNotEmpty == true ? Text(d ?? '', style: const TextStyle(fontSize: 12)) : null; }(),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 22) : null,
                        onTap: () {
                          // 关闭弹窗
                          Navigator.pop(ctx);
                          // 应用物料变更
                          if (mat.id != null && mat.id != item.productMaterielId) _applyMaterialChange(item, mat.id!);
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  /// 提交所有库存修改到后端
  /// 收集 [_modificationsValue] 中有变更的项，弹窗确认后批量保存
  Future<void> _submitModifications() async {
    final l10n = AppLocalizations.of(context);
    // 获取当前设备 ID
    final deviceId = _selectedDomain.value?.deviceId;
    if (deviceId == null) return;

    // 收集所有有变更的项
    final mods = _modificationsValue;
    final changedItems = mods.entries.where((e) => e.value.isNotEmpty).toList();
    if (changedItems.isEmpty) return;

    // 构建后端提交清单
    final saveList = <DeviceStockSaveItem>[];
    final stockList = _stockListValue ?? [];
    for (final entry in changedItems) {
      final stockId = entry.key;
      final mod = entry.value;
      // 从原始库存列表查找对应项，获取 productMaterielId 和默认 saveMode
      final originalItem = stockList.firstWhere((s) => s.id == stockId, orElse: () => DeviceStockVo());
      // 使用修改后的值，未指定时回退到原始值
      final saveMode = mod['newSaveMode'] as StockSaveMode?;
      final effectiveSaveMode = saveMode ?? (originalItem.stockMode == StockMode.CLOUD_CALC ? StockSaveMode.SET : StockSaveMode.ADD);
      // newStock 可为 null（HW_COLLECT/UNKNOWN 模式仅记录不填数量）
      final newStock = mod['newStock'] as int?;
      saveList.add(DeviceStockSaveItem(
        id: stockId ?? 0,
        productMaterielId: mod['newMaterielId'] ?? originalItem.productMaterielId ?? 0,
        stock: mod.containsKey('newStock') ? newStock : originalItem.currentStock,
        saveMode: effectiveSaveMode,
      ));
    }

    // 确认弹窗
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.stockConfirmSubmit, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: Text(l10n.stockConfirmMessage(saveList.length), style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.commonCancel, style: const TextStyle(color: Color(0xFF64748B)))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.stockConfirmSubmit, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // 显示同步中提示
    EasyLoading.show(status: l10n.stockSyncing);
    // 调用保存接口（trySingle 轻量错误处理）
    final success = await trySingle(() async {
      final body = OperationStockSaveRequestBody(deviceId: deviceId, list: saveList);
      final response = await ApiServer.instance.stockSave(body);
      return response?.take();
    });
    EasyLoading.dismiss();

    // 结果处理
    if (success == true) {
      l10n.stockUpdateSuccess.toast();
      // 清空修改记录并立即重新加载一次
      _modificationsValue = {};
      _loadStockData();
      // 关键步骤：HW_COLLECT / UNKNOWN 模式仅记录操作、状态值由设备上报，
      // HW_CALC 模式需 MQTT 下发后由设备回传，服务端落库均有延迟，
      // 单次刷新拿到的仍是旧值。提交成功后启动静默轮询（20 秒内每 2 秒一次，共 10 次），
      // 期间不弹 loading、不阻塞用户继续操作。
      _startStockPolling();
    } else {
      l10n.stockUpdateFailed.toast();
    }
  }

  /// 根据物料类型和 ID 查找物料名称
  /// [type] 物料类型枚举
  /// [materielId] 物料 ID
  /// @return 物料名称，未找到时返回 null
  String? _getMaterialName(GoodsMaterialType? type, int? materielId) {
    if (type == null || materielId == null) return null;
    // 从物料分组中查找同类型物料列表
    final list = _allMaterialsValue[type];
    if (list == null) return null;
    // 遍历匹配 ID
    for (final m in list) {
      if (m.id == materielId) return m.name;
    }
    return null;
  }
}

// ============================================================
// StatelessWidget 组件
// ============================================================

/// 未选择设备时的空状态占位
class _NoDeviceHint extends StatelessWidget {
  const _NoDeviceHint();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.devices_other, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(l10n.stockSelectDeviceFirst, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B))),
        const SizedBox(height: 8),
        Text(l10n.stockSelectDeviceHint, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
      ]),
    );
  }
}

/// 库存列表头部信息栏
/// 显示设备名称和当前库存项总数
class _StockHeader extends StatelessWidget {
  /// 设备名称或管理域标签
  final String deviceName;
  /// 库存项数量
  final int count;
  /// 设备ID（存在时显示库存流水记录入口）
  final int? deviceId;
  /// 设备标签（用于跳转时传递设备名）
  final String? deviceLabel;
  const _StockHeader({required this.deviceName, required this.count, this.deviceId, this.deviceLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // 库存图标
          const Icon(Icons.inventory_2, size: 18, color: Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          // 设备名
          Expanded(child: Text(deviceName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
          // 项数统计
          Text(l10n.stockTotalCount(count), style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ]),
        // 库存流水记录入口
        if (deviceId != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
            key: AppKeys.stockRecordEntry,
            onTap: () => StockRecordPage.actionStart(deviceId: deviceId ?? 0, deviceName: deviceLabel),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              const Icon(Icons.receipt_long_outlined, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Text(l10n.stockRecordTitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 14, color: Color(0xFFCBD5E1)),
            ]),
          ),
        ],
      ]),
    );
  }
}

/// 库存列表为空时的占位提示
class _EmptyListHint extends StatelessWidget {
  const _EmptyListHint();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // 库存图标
        Icon(Icons.inventory_outlined, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        // 空数据提示
        Text(l10n.stockEmptyHint, style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
      ]),
    );
  }
}

/// 库存模式标签
/// 显示库存管理方式（云端计算 / 硬件采集 / 设备计算 / 未知 / 无限）
class _StockModeTag extends StatelessWidget {
  /// 库存模式枚举值
  final StockMode mode;
  const _StockModeTag(this.mode);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      // 使用枚举关联的颜色和标签
      decoration: BoxDecoration(color: mode.badgeColor, borderRadius: BorderRadius.circular(6)),
      child: Text(mode.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: mode.badgeTextColor)),
    );
  }
}

/// 库存级别状态标签
/// 用于 HW_COLLECT / UNKNOWN 模式展示库存状态（2=库存充足 / 1=需补货 / 0=售罄）
class _StockLevelBadge extends StatelessWidget {
  /// 库存状态值（0/1/2）
  final int value;
  const _StockLevelBadge(this.value);

  @override
  Widget build(BuildContext context) {
    final level = StockLevelEnum.fromStatusValue(value);
    if (level == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: level.badgeColor, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          switch (level) {
            StockLevelEnum.NORMAL => Icons.check_circle,
            StockLevelEnum.LOW_STOCK => Icons.warning_amber_rounded,
            StockLevelEnum.SOLD_OUT => Icons.cancel,
          },
          size: 16,
          color: level.badgeTextColor,
        ),
        const SizedBox(width: 6),
        Text(level.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: level.badgeTextColor)),
      ]),
    );
  }
}

/// 库存进度条组件
/// 当 [maxStock] 为 null 或 0 时仅显示当前数量文本
/// 否则显示进度条 + 百分比，库存低于 20% 时显示警告色
/// HW_COLLECT / UNKNOWN 模式显示 [_StockLevelBadge] 替代进度条
class _StockProgressBar extends StatelessWidget {
  /// 当前库存数量（可能包含用户暂存修改后的值）
  final int displayStock;
  /// 最大库存容量（null 或 0 时不展示进度条）
  final int? maxStock;
  /// 库存单位
  final String unit;
  /// 库存模式，用于判断是否为状态值模式
  final StockMode? stockMode;
  const _StockProgressBar({required this.displayStock, this.maxStock, this.unit = "", this.stockMode});

  @override
  Widget build(BuildContext context) {
    // UNKNOWN 模式：显示库存状态标签，不显示进度条
    if (stockMode == StockMode.UNKNOWN) {
      return _StockLevelBadge(displayStock);
    }

    final max = maxStock;
    // 无最大容量时仅显示文本
    if (max == null || max <= 0) {
      return Row(children: [
        Icon(Icons.numbers, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(AppLocalizations.of(context).stockCurrentStock(displayStock, unit), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: displayStock <= 0 ? const Color(0xFFEF4444) : const Color(0xFF1E293B))),
      ]);
    }

    // 计算库存占比和告警阈值
    final ratio = (displayStock / max).clamp(0.0, 1.0);
    // 低于 20% 为低库存告警
    final isLow = ratio < 0.2;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // 数量与百分比
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(isLow ? Icons.warning_amber_rounded : Icons.check_circle, size: 14, color: isLow ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
          const SizedBox(width: 4),
          Text("$displayStock / $max $unit", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isLow ? const Color(0xFFF59E0B) : const Color(0xFF1E293B))),
        ]),
        Text("${(ratio * 100).toInt()}%", style: TextStyle(fontSize: 11, color: isLow ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8))),
      ]),
      const SizedBox(height: 6),
      // 进度条
      ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: ratio, minHeight: 6, backgroundColor: const Color(0xFFF1F5F9), valueColor: AlwaysStoppedAnimation<Color>(isLow ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)))),
    ]);
  }
}

/// 单条库存卡片
/// 显示组件名、库存模式标签、物料信息、进度条、操作按钮
/// 通过 [modificationsStream] 响应修改暂存状态变化
class _StockItemCard extends StatelessWidget {
  /// 列表索引
  final int index;
  /// 库存数据
  final DeviceStockVo item;
  /// 修改暂存流，用于监听用户变更
  final Stream<Map<int?, StockModification>?> modificationsStream;
  /// 修改暂存初始值
  final Map<int?, StockModification> initialMods;
  /// 全部物料分组数据（按 [GoodsMaterialType] 分组）
  final Map<GoodsMaterialType, List<ProductMaterielVo>> allMaterials;
  /// 编辑库存数量回调
  final void Function(DeviceStockVo) onEditStock;
  /// 更换物料回调
  final void Function(DeviceStockVo) onPickMaterial;
  /// 撤销修改回调
  final void Function(int?) onUndo;
  /// 根据物料类型和 ID 查找物料名称的函数
  final String? Function(GoodsMaterialType?, int?) getMaterialName;

  const _StockItemCard({
    required this.index,
    required this.item,
    required this.modificationsStream,
    required this.initialMods,
    required this.allMaterials,
    required this.onEditStock,
    required this.onPickMaterial,
    required this.onUndo,
    required this.getMaterialName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 监听修改暂存流
    return StreamBuilder<Map<int?, StockModification>?>(
      stream: modificationsStream,
      initialData: initialMods,
      builder: (context, modSnap) {
        // 获取当前库存项的修改记录
        final mods = modSnap.data ?? <int?, StockModification>{};
        final modification = mods[item.id];
        // 是否有修改
        final hasChange = modification?.isNotEmpty ?? false;
        // 显示的物料名称（优先使用修改后的物料）
        final displayMaterialName = modification?['newMaterielId'] != null ? getMaterialName(item.productMaterielType, modification!['newMaterielId']) : item.productMaterielName;
        // 显示的库存数量（模式感知：ADD 模式为 current + delta，SET 模式为直接值）
        final displayStock = () {
          if (modification == null || modification['newStock'] == null) return item.currentStock ?? 0;
          final newStock = modification['newStock'] as int;
          final saveMode = modification['newSaveMode'] as StockSaveMode?;
          if (saveMode == StockSaveMode.ADD) {
            // ADD 模式：显示库存增减后的结果值
            return (item.currentStock ?? 0) + newStock;
          }
          // SET 模式或未指定：直接使用目标值
          return newStock;
        }();
        // 库存模式
        final stockMode = item.stockMode;
        // 是否允许操作（编辑 / 补货 / 更换物料）
        final canOperate = stockMode != null && stockMode.canOperate;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
            // 有修改时显示蓝色边框
            border: hasChange ? Border.all(color: const Color(0xFF3B82F6), width: 1) : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 第一行：组件名 + 已修改标记 + 模式标签
            Row(children: [
              Expanded(child: Text(item.compName ?? l10n.stockUnnamedComponent, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
              // 已修改标记
              if (hasChange) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)), child: Text(l10n.stockChanged, style: const TextStyle(fontSize: 10, color: Color(0xFF3B82F6)))),
              // 库存模式标签
              if (stockMode != null) _StockModeTag(stockMode),
            ]),
            const SizedBox(height: 8),
            // 第二行：物料名称 + 更换物料按钮
            Row(children: [
              const Icon(Icons.grain, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(child: Text(displayMaterialName ?? l10n.stockNoMaterial, style: const TextStyle(fontSize: 13, color: Color(0xFF475569)))),
              if (canOperate) GestureDetector(key: AppKeys.stockBtnMaterial(index), onTap: () => onPickMaterial(item), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: Text(l10n.stockChangeMaterial, style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6))))),
            ]),
            const SizedBox(height: 12),
            // 第三行：库存进度条（HW_COLLECT/UNKNOWN 模式显示为状态标签）
            _StockProgressBar(displayStock: displayStock, maxStock: item.maxStock, unit: item.unit ?? "", stockMode: stockMode),
            const SizedBox(height: 10),
            // 第四行：操作区
            if (canOperate)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                // 修改库存按钮（统一入口，弹窗内可选 SET/ADD 方式）
                GestureDetector(key: AppKeys.stockBtnEdit(index), onTap: () => onEditStock(item), child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.edit, size: 14, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 4),
                  Text(
                    stockMode == StockMode.HW_COLLECT || stockMode == StockMode.UNKNOWN
                        ? l10n.stockStatusRefillRecordOnly
                        : (stockMode?.actionLabel ?? l10n.stockEdit),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6))),
                ])),
                // 变更数值摘要（显示模式感知的变更信息）
                if (modification?['newStock'] != null) () {
                  final mod = modification ?? {};
                  final stockVal = mod['newStock'] as int;
                  final saveMode = mod['newSaveMode'] as StockSaveMode?;
                  final unitStr = item.unit ?? '';
                  if (saveMode == StockSaveMode.ADD) {
                    // ADD 模式：显示增减量
                    final sign = stockVal >= 0 ? "+" : "";
                    return Text("$sign$stockVal $unitStr", style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w500));
                  } else {
                    // SET 模式：显示目标值
                    return Text("→ $stockVal $unitStr", style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w500));
                  }
                }(),
                // 撤销按钮
                if (hasChange) GestureDetector(key: AppKeys.stockUndo(index), onTap: () => onUndo(item.id), child: Text(l10n.stockUndo, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)))),
              ]),
          ]),
        );
      },
    );
  }
}

/// 底部提交按钮栏
/// 监听 [modificationsStream] 实时显示变更项计数，无变更时置灰禁用
class _StockSubmitBar extends StatelessWidget {
  /// 修改暂存流
  final Stream<Map<int?, StockModification>?> modificationsStream;
  /// 修改暂存初始值
  final Map<int?, StockModification> initialMods;
  /// 提交回调
  final VoidCallback onSubmit;

  const _StockSubmitBar({required this.modificationsStream, required this.initialMods, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StreamBuilder<Map<int?, StockModification>?>(
      stream: modificationsStream,
      initialData: initialMods,
      builder: (context, modSnap) {
        // 计算有变更的项数
        final mods = modSnap.data ?? <int?, StockModification>{};
        final changedCount = mods.values.where((m) => m.isNotEmpty).length;
        final hasChanges = changedCount > 0;

        return Container(
          key: AppKeys.stockSubmitBar,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2))]),
          child: SafeArea(top: false, child: SizedBox(height: 48, child: ElevatedButton(
            key: AppKeys.stockSubmitBtn,
            // 无变更时按钮禁用
            onPressed: hasChanges ? onSubmit : null,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E293B), disabledBackgroundColor: const Color(0xFFCBD5E1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            // 显示变更项计数或"无变更项"
            child: Text(hasChanges ? l10n.stockSubmitButton(changedCount) : l10n.stockNoChanges, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ))),
        );
      },
    );
  }
}

// ============================================================
// 业务逻辑混入
// ============================================================

/// 库存页面的业务逻辑混入
/// 实现 [IBaseStreamBloc]，使用 [StreamData] 管理所有响应式状态
/// 每个 StreamData 提供 value（当前值）、stream（监听流）和对应的 getter/setter
mixin _Bloc implements IBaseStreamBloc {
  /// 设备树数据（运营商 → 店铺 → 设备），用于抽屉组件
  final _operators = <OperationOperatorVo>[].streamData;
  /// 设备树当前值读取
  List<OperationOperatorVo>? get _operatorsValue => _operators.value;
  /// 设备树监听流，[DeviceDrawer] 通过 StreamBuilder 订阅
  Stream<List<OperationOperatorVo>?> get _operatorsStream => _operators.stream;
  /// 写入设备树数据，触发流推送
  set _operatorsValue(List<OperationOperatorVo>? v) => _operators.value = v;

  /// 当前选中的管理域（运营商 / 店铺 / 设备）
  final _selectedDomain = DeviceSelection(label: "库存管理").streamData;
  /// 管理域当前值读取
  DeviceSelection? get _selectedDomainValue => _selectedDomain.value;
  /// 管理域监听流，驱动 AppBar 标题和内容区域刷新
  Stream<DeviceSelection?> get _selectedDomainStream => _selectedDomain.stream;
  /// 写入管理域，触发流推送
  set _selectedDomainValue(DeviceSelection? v) => _selectedDomain.value = v;

  /// 当前设备的库存列表
  final _stockList = <DeviceStockVo>[].streamData;
  /// 库存列表当前值读取
  List<DeviceStockVo>? get _stockListValue => _stockList.value;
  /// 库存列表监听流，[SmartRefresher] 内通过 StreamBuilder 订阅
  Stream<List<DeviceStockVo>?> get _stockListStream => _stockList.stream;
  /// 写入库存列表，触发流推送
  set _stockListValue(List<DeviceStockVo>? v) => _stockList.value = v;

  /// 全部物料数据，按 [GoodsMaterialType] 分组
  final _allMaterials = <GoodsMaterialType, List<ProductMaterielVo>>{}.streamData;
  /// 物料分组当前值读取，默认空 Map
  Map<GoodsMaterialType, List<ProductMaterielVo>> get _allMaterialsValue => _allMaterials.value ?? {};
  /// 写入物料分组数据
  set _allMaterialsValue(Map<GoodsMaterialType, List<ProductMaterielVo>> v) => _allMaterials.value = v;

  /// 物料数据是否已从 API 加载完成
  final _materialsLoaded = false.streamData;
  /// 物料加载状态读取
  bool get _materialsLoadedValue => _materialsLoaded.value ?? false;
  /// 更新物料加载状态
  set _materialsLoadedValue(bool v) => _materialsLoaded.value = v;

  /// 用户修改暂存表，key 为库存记录 ID，value 为修改字段 Map
  final _modifications = <int?, StockModification>{}.streamData;
  /// 修改暂存当前值读取
  Map<int?, StockModification> get _modificationsValue => _modifications.value ?? {};
  /// 修改暂存监听流，驱动 [_StockItemCard] 和 [_StockSubmitBar] 的 StreamBuilder 重建
  Stream<Map<int?, StockModification>?> get _modificationsStream => _modifications.stream;
  /// 写入修改暂存，触发流推送
  set _modificationsValue(Map<int?, StockModification> v) => _modifications.value = v;

  /// 释放所有 StreamData 流，防止内存泄漏
  @override
  void streamDispose() {
    _operators.dispose();
    _selectedDomain.dispose();
    _stockList.dispose();
    _allMaterials.dispose();
    _materialsLoaded.dispose();
    _modifications.dispose();
  }
}
