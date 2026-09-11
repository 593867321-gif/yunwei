import 'package:flutter/material.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:operation/ext/app_keys.dart';
import 'package:operation/ext/enums.dart';
import 'package:operation/l10n/app_localizations.dart';
import 'package:operation/net/api_device.dart';
import 'package:operation/net/api_device_detail.dart';
import 'package:operation/net/request_server.dart';
import 'package:operation/page/page_device.dart';
import 'package:operation/net/mqtt_manager.dart';
import 'package:operation/page/page_electrical_chart.dart';
import 'package:operation/page/page_remote_control.dart';

/// author: AI   2026/5/3
/// 设备状态详情页
/// 展示设备电气参数、温度、水路、奶路称重、故障告警、库存预警、
/// 在线事件历史、故障告警历史。支持点击 📊 图标查看曲线图。
class DeviceDetailPage extends StatefulWidget {
  final DeviceCardData device;
  const DeviceDetailPage({super.key, required this.device});

  static void actionStart({required DeviceCardData device}) {
    RouterUtil.navigatorKey.currentState?.push(MaterialPageRouteLifecycle(builder: (_) => DeviceDetailPage(device: device)));
  }

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> with _Bloc {
  @override
  void initState() {
    super.initState();
    final code = widget.device.deviceCode;
    if (code != null && code.isNotEmpty) {
      _loadOnlineEvents(code);
      _loadFaultHistory(code);
    }
  }

  @override
  void dispose() {
    streamDispose();
    super.dispose();
  }

  Future<void> _loadOnlineEvents(String deviceCode) async {
    _onlineEventsLoadingValue = true;
    try {
      final res = await ApiServer.instance.deviceOnlineEvents(
        OperationDeviceEventsRequestBody(deviceCode: deviceCode, limit: 50),
      );
      final page = res?.take();
      _onlineEventsValue = page?.content;
    } catch (_) {
      _onlineEventsValue = null;
    }
    _onlineEventsLoadingValue = false;
  }

  Future<void> _loadFaultHistory(String deviceCode) async {
    _faultHistoryLoadingValue = true;
    try {
      final res = await ApiServer.instance.deviceFaultHistory(
        OperationDeviceEventsRequestBody(deviceCode: deviceCode, limit: 50),
      );
      final page = res?.take();
      _faultHistoryValue = page?.content;
    } catch (_) {
      _faultHistoryValue = null;
    }
    _faultHistoryLoadingValue = false;
  }

  void _openChart(String metric, String metricName, String unit) {
    final code = widget.device.deviceCode;
    if (code == null || code.isEmpty) return;
    PageElectricalChart.actionStart(
      deviceCode: code,
      metric: metric,
      metricName: metricName,
      unit: unit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final device = widget.device;
    final electrical = device.electrical;
    final code = device.deviceCode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(device.deviceName ?? l10n.deviceDetailTitle),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(key: AppKeys.deviceDetailBackButton, icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            key: AppKeys.deviceBtnControl(0),
            icon: const Icon(Icons.settings_remote),
            tooltip: l10n.remoteControlTooltip,
            onPressed: () {
              final device = widget.device;
              final storeId = device.storeId;
              final deviceCode = device.deviceCode;
              if (storeId == null || deviceCode == null || deviceCode.isEmpty) return;
              final groupId = MqttManager.instance.groupId ?? '';
              final deviceClientId = groupId.isNotEmpty ? '$groupId@@@$deviceCode' : deviceCode;
              RemoteControlPage.actionStart(device: device, deviceClientId: deviceClientId, storeId: storeId);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DeviceStatusSection(
            deviceName: device.deviceName,
            deviceCode: device.deviceCode,
            deviceModel: device.model,
            runState: device.runState,
            onlineStatus: device.onlineStatus,
            title: l10n.deviceDetailSectionStatus,
            labelCode: l10n.deviceDetailLabelDeviceCode,
            labelModel: l10n.deviceDetailLabelModel,
          ),
          const SizedBox(height: 12),
          if (electrical != null)
            _ElectricalSection(
              electrical: electrical,
              title: l10n.deviceDetailSectionPower,
              noDataLabel: l10n.deviceDetailNoData,
              onChartTap: _openChart,
            ),
          if (electrical != null)
            _TemperatureSection(
              electrical: electrical,
              title: l10n.deviceDetailSectionTemp,
              noDataLabel: l10n.deviceDetailNoData,
              onChartTap: _openChart,
            ),
          if (electrical != null)
            _WaterSection(
              electrical: electrical,
              title: l10n.deviceDetailSectionWater,
              noDataLabel: l10n.deviceDetailNoData,
              normalLabel: l10n.deviceDetailNormal,
              shortageLabel: l10n.deviceDetailWaterShortage,
              onChartTap: _openChart,
            ),
          if (electrical != null)
            _MilkSection(
              electrical: electrical,
              title: l10n.deviceDetailSectionMilk,
              noDataLabel: l10n.deviceDetailNoData,
              onChartTap: _openChart,
            ),
          _AlertSection(
            errors: device.errors,
            warnings: device.warnings,
            title: l10n.deviceDetailSectionAlert,
            noDataLabel: l10n.deviceListNoAlert,
            alertMoreLabel: (int count) => l10n.deviceListAlertMore(count),
          ),
          const SizedBox(height: 12),
          _StockAlertSection(
            stockAlerts: device.stockAlerts,
            title: l10n.deviceDetailSectionStockAlert,
            noDataLabel: l10n.deviceListNoStockAlert,
            soldOutLabel: l10n.deviceListSoldOut,
            lowStockLabel: l10n.deviceListLowStock,
          ),
          const SizedBox(height: 12),
          if (code != null && code.isNotEmpty)
            StreamBuilder<List<OnlineEventVo>?>(
              stream: _onlineEventsStream,
              builder: (_, snap) => _OnlineEventsSection(
                events: snap.data,
                isLoading: _onlineEventsLoadingValue,
                title: l10n.deviceOnlineEvents,
                onlineLabel: l10n.deviceOnline,
                offlineLabel: l10n.deviceOffline,
                noDataLabel: l10n.deviceDetailNoData,
              ),
            ),
          if (code != null && code.isNotEmpty)
            StreamBuilder<List<FaultHistoryVo>?>(
              stream: _faultHistoryStream,
              builder: (_, snap) => _FaultHistorySection(
                history: snap.data,
                isLoading: _faultHistoryLoadingValue,
                title: l10n.deviceFaultHistory,
                noDataLabel: l10n.deviceDetailNoData,
              ),
            ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

// ============================================================
// Mixin Bloc
// ============================================================

mixin _Bloc implements IBaseStreamBloc {
  final _onlineEvents = <OnlineEventVo>[].streamData;
  Stream<List<OnlineEventVo>?> get _onlineEventsStream => _onlineEvents.stream;
  set _onlineEventsValue(List<OnlineEventVo>? v) => _onlineEvents.value = v;

  final _onlineEventsLoading = false.streamData;
  bool get _onlineEventsLoadingValue => _onlineEventsLoading.value ?? false;
  set _onlineEventsLoadingValue(bool v) => _onlineEventsLoading.value = v;

  final _faultHistory = <FaultHistoryVo>[].streamData;
  Stream<List<FaultHistoryVo>?> get _faultHistoryStream => _faultHistory.stream;
  set _faultHistoryValue(List<FaultHistoryVo>? v) => _faultHistory.value = v;

  final _faultHistoryLoading = false.streamData;
  bool get _faultHistoryLoadingValue => _faultHistoryLoading.value ?? false;
  set _faultHistoryLoadingValue(bool v) => _faultHistoryLoading.value = v;

  @override
  void streamDispose() {
    _onlineEvents.dispose();
    _onlineEventsLoading.dispose();
    _faultHistory.dispose();
    _faultHistoryLoading.dispose();
  }
}

// ============================================================
// 详情页 StatelessWidget 组件
// ============================================================

class _DeviceStatusSection extends StatelessWidget {
  final String? deviceName;
  final String? deviceCode;
  final String? deviceModel;
  final DeviceRunState? runState;
  final OnlineStatus? onlineStatus;
  final String title;
  final String labelCode;
  final String labelModel;

  const _DeviceStatusSection({this.deviceName, this.deviceCode, this.deviceModel, this.runState, this.onlineStatus, required this.title, required this.labelCode, required this.labelModel});

  @override
  Widget build(BuildContext context) {
    final run = runState;
    final online = onlineStatus;
    final code = deviceCode;
    final model = deviceModel;

    return _DetailCard(
      title: title,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (run != null)
          Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: run.badgeTextColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(run.label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: run.badgeTextColor)),
            const SizedBox(width: 12),
            if (online != null)
              Text("(${online.apiValue})", style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          ]),
        const SizedBox(height: 10),
        if (code != null && code.isNotEmpty)
          _DetailRow(label: labelCode, value: code),
        if (model != null && model.isNotEmpty)
          _DetailRow(label: labelModel, value: model),
      ]),
    );
  }
}

class _ElectricalSection extends StatelessWidget {
  final OperationDeviceElectricalVo electrical;
  final String title;
  final String noDataLabel;
  final void Function(String metric, String metricName, String unit) onChartTap;

  const _ElectricalSection({required this.electrical, required this.title, required this.noDataLabel, required this.onChartTap});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final v = electrical.currentVoltage;
    final cur = electrical.currentCurrent;
    final pwr = electrical.activeActivePower;
    final ene = electrical.reactivePower;

    if (v != null && v > 0) rows.add(_DetailRow(label: "输入电压", value: "$v V", onChartTap: () => onChartTap('inputVoltage', '输入电压', 'V')));
    if (cur != null && cur > 0) rows.add(_DetailRow(label: "当前电流", value: "$cur A", onChartTap: () => onChartTap('current', '当前电流', 'A')));
    if (pwr != null && pwr > 0) rows.add(_DetailRow(label: "有功功率", value: "$pwr W", onChartTap: () => onChartTap('power', '有功功率', 'W')));
    if (ene != null && ene > 0) rows.add(_DetailRow(label: "有功电能", value: "$ene kWh", onChartTap: () => onChartTap('energy', '有功电能', 'kWh')));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _DetailCard(title: title, child: rows.isEmpty ? _EmptyHint(label: noDataLabel) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows)),
    );
  }
}

class _TemperatureSection extends StatelessWidget {
  final OperationDeviceElectricalVo electrical;
  final String title;
  final String noDataLabel;
  final void Function(String metric, String metricName, String unit) onChartTap;

  const _TemperatureSection({required this.electrical, required this.title, required this.noDataLabel, required this.onChartTap});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final bt = electrical.bottomTemp;
    final tt = electrical.topTemp;
    final ct = electrical.coldTemp;
    final it = electrical.iceTemp;
    final wpt = electrical.waterPressureTemp;
    final wst = electrical.waterSurfaceTemp;

    if (bt != null && bt > 0) rows.add(_DetailRow(label: "底仓温度", value: "$bt ℃", onChartTap: () => onChartTap('bottomTemp', '底仓温度', '℃')));
    if (tt != null && tt > 0) rows.add(_DetailRow(label: "上仓温度", value: "$tt ℃", onChartTap: () => onChartTap('topTemp', '上仓温度', '℃')));
    if (ct != null && ct > 0) rows.add(_DetailRow(label: "冷水温度", value: "$ct ℃", onChartTap: () => onChartTap('coldTemp', '冷水温度', '℃')));
    if (it != null && it > 0) rows.add(_DetailRow(label: "冰藏箱温度", value: "$it ℃", onChartTap: () => onChartTap('iceTemp', '冰藏箱温度', '℃')));
    if (wpt != null && wpt > 0) rows.add(_DetailRow(label: "进水温度", value: "$wpt ℃"));
    if (wst != null && wst > 0) rows.add(_DetailRow(label: "水管表面温度", value: "$wst ℃"));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _DetailCard(title: title, child: rows.isEmpty ? _EmptyHint(label: noDataLabel) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows)),
    );
  }
}

class _WaterSection extends StatelessWidget {
  final OperationDeviceElectricalVo electrical;
  final String title;
  final String noDataLabel;
  final String normalLabel;
  final String shortageLabel;
  final void Function(String metric, String metricName, String unit) onChartTap;

  const _WaterSection({required this.electrical, required this.title, required this.noDataLabel, required this.normalLabel, required this.shortageLabel, required this.onChartTap});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final wu = electrical.waterUsage;
    final wp = electrical.waterPressure;
    final tds = electrical.waterTDS;

    if (wu != null && wu > 0) rows.add(_DetailRow(label: "用水量", value: "$wu L", onChartTap: () => onChartTap('waterUsage', '用水量', 'L')));
    if (wp != null && wp > 0) rows.add(_DetailRow(label: "进水压力", value: "$wp bar", onChartTap: () => onChartTap('waterPressure', '进水压力', 'bar')));
    if (tds != null && tds > 0) rows.add(_DetailRow(label: "进水TDS", value: "$tds ppm", onChartTap: () => onChartTap('waterTDS', '进水TDS', 'ppm')));

    final sw = electrical.systemWater;
    if (sw != null) {
      final shortage = sw;
      rows.add(_DetailRow(
        label: "系统缺水",
        value: shortage ? shortageLabel : normalLabel,
        valueColor: shortage ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      ));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _DetailCard(title: title, child: rows.isEmpty ? _EmptyHint(label: noDataLabel) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows)),
    );
  }
}

class _MilkSection extends StatelessWidget {
  final OperationDeviceElectricalVo electrical;
  final String title;
  final String noDataLabel;
  final void Function(String metric, String metricName, String unit) onChartTap;

  const _MilkSection({required this.electrical, required this.title, required this.noDataLabel, required this.onChartTap});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final m1 = electrical.milkClog1;
    final m2 = electrical.milkClog2;

    if (m1 != null && m1 > 0) rows.add(_DetailRow(label: "奶路称重1", value: "$m1 g", onChartTap: () => onChartTap('milkClog1', '奶路称重1', 'g')));
    if (m2 != null && m2 > 0) rows.add(_DetailRow(label: "奶路称重2", value: "$m2 g", onChartTap: () => onChartTap('milkClog2', '奶路称重2', 'g')));

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _DetailCard(title: title, child: rows.isEmpty ? _EmptyHint(label: noDataLabel) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows)),
    );
  }
}

class _AlertSection extends StatelessWidget {
  final List<DeviceErrorKey> errors;
  final List<DeviceWaringKey> warnings;
  final String title;
  final String noDataLabel;
  final String Function(int count) alertMoreLabel;

  const _AlertSection({required this.errors, required this.warnings, required this.title, required this.noDataLabel, required this.alertMoreLabel});

  @override
  Widget build(BuildContext context) {
    final tags = <Widget>[];
    const maxDisplay = 6;

    for (final err in errors) {
      if (tags.length >= maxDisplay) break;
      tags.add(_AlertTag(label: err.label, color: err.badgeTextColor, bgColor: err.badgeColor));
    }
    for (final waring in warnings) {
      if (tags.length >= maxDisplay) break;
      tags.add(_AlertTag(label: waring.label, color: waring.badgeTextColor, bgColor: waring.badgeColor));
    }

    final totalCount = errors.length + warnings.length;
    if (totalCount > maxDisplay) {
      tags.add(_AlertTag(label: alertMoreLabel(totalCount - maxDisplay), color: const Color(0xFF64748B), bgColor: const Color(0xFFF1F5F9)));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _DetailCard(title: title, child: tags.isEmpty ? _EmptyHint(label: noDataLabel) : Wrap(spacing: 6, runSpacing: 4, children: tags)),
    );
  }
}

class _StockAlertSection extends StatelessWidget {
  final List<DeviceStockAlertVo> stockAlerts;
  final String title;
  final String noDataLabel;
  final String soldOutLabel;
  final String lowStockLabel;

  const _StockAlertSection({required this.stockAlerts, required this.title, required this.noDataLabel, required this.soldOutLabel, required this.lowStockLabel});

  @override
  Widget build(BuildContext context) {
    if (stockAlerts.isEmpty) {
      return _DetailCard(title: title, child: _EmptyHint(label: noDataLabel));
    }

    return _DetailCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: stockAlerts.map((alert) {
          final isSoldOut = alert.level == StockAlertLevel.SOLD_OUT;
          final levelLabel = isSoldOut ? soldOutLabel : lowStockLabel;
          final levelColor = isSoldOut ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              _AlertTag(label: levelLabel, color: levelColor, bgColor: isSoldOut ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB)),
              const SizedBox(width: 8),
              Expanded(child: Text(alert.materialName ?? '-', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

/// 在线事件历史区块
class _OnlineEventsSection extends StatelessWidget {
  final List<OnlineEventVo>? events;
  final bool isLoading;
  final String title;
  final String onlineLabel;
  final String offlineLabel;
  final String noDataLabel;

  const _OnlineEventsSection({required this.events, required this.isLoading, required this.title, required this.onlineLabel, required this.offlineLabel, required this.noDataLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _DetailCard(
        title: title,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final list = events;
    if (list == null || list.isEmpty) {
      return _EmptyHint(label: noDataLabel);
    }
    return _Timeline(
      items: list.take(20).map((e) {
        final dt = DateTime.fromMillisecondsSinceEpoch(e.ts);
        final timeStr = '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        final isOnline = e.online == 'online';
        return _TimelineItem(
          time: timeStr,
          label: isOnline ? onlineLabel : offlineLabel,
          color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
        );
      }).toList(),
    );
  }
}

/// 故障历史区块
class _FaultHistorySection extends StatelessWidget {
  final List<FaultHistoryVo>? history;
  final bool isLoading;
  final String title;
  final String noDataLabel;

  const _FaultHistorySection({required this.history, required this.isLoading, required this.title, required this.noDataLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _DetailCard(
        title: title,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final list = history;
    if (list == null || list.isEmpty) {
      return _EmptyHint(label: noDataLabel);
    }
    return _Timeline(
      items: list.take(20).map((e) {
        final dt = DateTime.fromMillisecondsSinceEpoch(e.ts);
        final timeStr = '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        final parts = <String>[];
        parts.addAll(e.warnings.map((w) => _waringLabel(w)));
        parts.addAll(e.errors.map((err) => _errorLabel(err)));
        return _TimelineItem(
          time: timeStr,
          label: parts.isNotEmpty ? parts.join(' · ') : '--',
          color: e.errors.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
        );
      }).toList(),
    );
  }

  String _waringLabel(String code) {
    final key = DeviceWaringKey.fromApiString(code);
    return key.label;
  }

  String _errorLabel(String code) {
    final key = DeviceErrorKey.fromApiString(code);
    return key.label;
  }
}

// ============================================================
// 通用组件
// ============================================================

class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  final Color? valueColor;
  final VoidCallback? onChartTap;
  final Key? _metricKey;

  _DetailRow({required this.label, this.value, this.valueColor, this.onChartTap}) : _metricKey = onChartTap != null ? AppKeys.deviceDetailChartBtn(label) : null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value ?? '-', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF1E293B))),
          if (onChartTap != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              key: _metricKey,
              onTap: onChartTap,
              child: const Text('📊', style: TextStyle(fontSize: 16)),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String label;

  const _EmptyHint({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))));
  }
}

class _AlertTag extends StatelessWidget {
  final String label;
  final Color color;
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

/// 时间线容器
class _Timeline extends StatelessWidget {
  final List<_TimelineItem> items;
  const _Timeline({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => item).toList(),
    );
  }
}

/// 时间线条目
class _TimelineItem extends StatelessWidget {
  final String time;
  final String label;
  final Color color;
  const _TimelineItem({required this.time, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 100,
          child: Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ),
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
      ]),
    );
  }
}
