import 'package:flutter/material.dart';
import 'package:itwo_flutter_base/itwo_flutter_base.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../net/api_device_detail.dart';
import '../net/request_server.dart';
import 'page_webview.dart';

/// 电气曲线图页面
///
/// 接收 [deviceCode]、[metric]、[metricName]、[unit] 参数，
/// 通过 API 拉取曲线数据后载入 WebView 的 ECharts 模板。
class PageElectricalChart extends StatefulWidget {
  final String deviceCode;
  final String metric;
  final String metricName;
  final String unit;

  const PageElectricalChart({
    super.key,
    required this.deviceCode,
    required this.metric,
    required this.metricName,
    required this.unit,
  });

  static void actionStart({
    required String deviceCode,
    required String metric,
    required String metricName,
    required String unit,
  }) {
    RouterUtil.navigatorKey.currentState?.push(
      MaterialPageRouteLifecycle(
        builder: (_) => PageElectricalChart(
          deviceCode: deviceCode,
          metric: metric,
          metricName: metricName,
          unit: unit,
        ),
      ),
    );
  }

  @override
  State<PageElectricalChart> createState() => _PageElectricalChartState();
}

class _PageElectricalChartState extends State<PageElectricalChart> {
  /// 所选日期（零点毫秒时间戳）
  late int _selectedDate;
  bool _loading = true;
  List<ElectricalChartPointVo>? _points;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = _todayMidnightMs();
    _loadChartData();
  }

  static int _todayMidnightMs() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    return midnight.millisecondsSinceEpoch;
  }

  Future<void> _loadChartData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final req = OperationElectricalChartRequestBody(
        deviceCode: widget.deviceCode,
        date: _selectedDate,
        metric: widget.metric,
      );
      final res = await ApiServer.instance.deviceElectricalChart(req);
      final data = res?.take();
      if (data != null) {
        _points = data.cast<ElectricalChartPointVo>();
      } else {
        _points = null;
      }
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _onDateChanged(DateTime date) {
    final midnight = DateTime(date.year, date.month, date.day);
    _selectedDate = midnight.millisecondsSinceEpoch;
    _loadChartData();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.fromMillisecondsSinceEpoch(_selectedDate),
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now,
      helpText: '选择查询日期',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked != null) {
      _onDateChanged(picked);
    }
  }

  Future<void> _openWebView() async {
    final points = _points;
    if (points == null || points.isEmpty) return;

    final jsonData = points
        .map((p) => '{"ts":${p.ts},"value":${p.value}}')
        .join(',');
    final js = '''
setChartData('${widget.metricName}', '${widget.unit}', [${jsonData}]);
''';

    PageWebView.actionStart(
      title: widget.metricName,
      url: 'https://oss.youdake.com/static/h5/operation/op_chart.html',
      onPageFinished: (WebViewController ctrl) => ctrl.runJavaScript(js),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.metricName),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        // 日期选择栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.white,
          child: Row(children: [
            const Text('查询日期：', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            GestureDetector(
              onTap: _pickDate,
              child: Row(children: [
                Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF94A3B8)),
              ]),
            ),
            const Spacer(),
            if (_points != null && _points!.isNotEmpty)
              TextButton.icon(
                onPressed: _openWebView,
                icon: const Icon(Icons.show_chart, size: 18),
                label: const Text('查看曲线图'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
              ),
          ]),
        ),
        const SizedBox(height: 1, child: ColoredBox(color: Color(0xFFF1F5F9))),
        // 内容区
        Expanded(
          child: _buildBody(),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('加载失败', style: const TextStyle(fontSize: 14, color: Color(0xFFEF4444))),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadChartData, child: const Text('重试')),
        ]),
      );
    }
    final points = _points;
    if (points == null || points.isEmpty) {
      return const Center(child: Text('该日期暂无数据', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: points.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
      itemBuilder: (_, i) {
        final p = points[i];
        final time = DateTime.fromMillisecondsSinceEpoch(p.ts);
        final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(timeStr, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            Text(
              '${p.value ?? '-'} ${widget.unit}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ]),
        );
      },
    );
  }

  String _formatDate(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
