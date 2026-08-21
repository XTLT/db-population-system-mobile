import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import '../../models/custom_report.dart';
import '../../api/custom_report_api.dart';
import '../../services/report_pdf_service.dart';
import '../../services/report_storage_service.dart';
import 'custom_report_builder_page.dart';

class CustomReportViewPage extends StatefulWidget {
  final String reportId;

  const CustomReportViewPage({super.key, required this.reportId});

  @override
  State<CustomReportViewPage> createState() => _CustomReportViewPageState();
}

class _CustomReportViewPageState extends State<CustomReportViewPage> {
  CustomReport? _report;
  Map<String, dynamic>? _reportData;
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final report = await CustomReportApi.getReport(widget.reportId);
      
      final data = await CustomReportApi.generateReport(
        reportType: report.reportType,
        dimensions: report.dimensions,
        dateRange: report.dateRange,
        filters: report.filters,
      );

      setState(() {
        _report = report;
        _reportData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _editReport() async {
    if (_report == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CustomReportBuilderPage(report: _report),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _exportPdf() async {
    if (_report == null || _reportData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报表数据不完整，无法导出')),
        );
      }
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在生成 PDF...')),
        );
      }

      
      Uint8List? chartBytes;
      try {
        final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            chartBytes = byteData.buffer.asUint8List();
          }
        }
      } catch (e) {
        debugPrint('图表截图失败: $e');
      }

      
      final pdfPath = await ReportPdfService.generateReportPdf(
        _report!,
        _reportData!,
        chartBytes: chartBytes,
      );

      
      await ReportStorageService.saveReport(_report!, pdfPath);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF 已生成并保存'),
            action: SnackBarAction(
              label: '分享',
              onPressed: () async {
                await Share.shareXFiles(
                  [XFile(pdfPath)],
                  subject: _report!.title,
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF 生成失败: $e')),
        );
      }
    }
  }

  Future<void> _shareReport() async {
    if (_report == null || _reportData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报表数据不完整，无法分享')),
        );
      }
      return;
    }

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在生成 PDF...')),
        );
      }

      
      Uint8List? chartBytes;
      try {
        final boundary = _chartKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            chartBytes = byteData.buffer.asUint8List();
          }
        }
      } catch (e) {
        debugPrint('图表截图失败: $e');
      }

      
      final pdfPath = await ReportPdfService.generateReportPdf(
        _report!,
        _reportData!,
        chartBytes: chartBytes,
      );

      
      await Share.shareXFiles(
        [XFile(pdfPath)],
        subject: _report!.title,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_report?.title ?? '报表详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editReport();
                  break;
                case 'export':
                  _exportPdf();
                  break;
                case 'share':
                  _shareReport();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('编辑报表'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('导出 PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('分享'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('加载失败: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _report == null
                  ? const Center(child: Text('报表不存在'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportInfo(),
          const SizedBox(height: 24),
          if (_reportData != null && _reportData!['dimension_data'] != null) ...[
            const Text(
              '数据图表',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _chartKey,
              child: _buildChart(),
            ),
            const SizedBox(height: 24),
          ],
          if (_reportData != null) ...[
            const Text(
              '数据详情',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildDataTable(),
          ],
        ],
      ),
    );
  }

  Widget _buildReportInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getChartIcon(_report!.chartType),
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _report!.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('报表类型', _report!.reportTypeDisplayName),
            _buildInfoRow('图表类型', _report!.chartTypeDisplayName),
            if (_report!.dimensions.isNotEmpty)
              _buildInfoRow('统计维度', _report!.dimensions.join('、')),
            if (_report!.dateRange.isNotEmpty)
              _buildInfoRow(
                '时间范围',
                '${_report!.dateRange['start'] ?? '未设置'} 至 ${_report!.dateRange['end'] ?? '未设置'}',
              ),
            _buildInfoRow('创建时间', _formatDateTime(_report!.createdAt)),
            if (_report!.updatedAt != null)
              _buildInfoRow('更新时间', _formatDateTime(_report!.updatedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final dimensionData = _reportData!['dimension_data'] as Map<String, dynamic>?;
    if (dimensionData == null || dimensionData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('暂无数据'),
          ),
        ),
      );
    }

    final firstDimension = dimensionData.entries.first;
    final data = firstDimension.value as Map<String, dynamic>;

    switch (_report!.chartType) {
      case 'bar':
        return _buildBarChart(data);
      case 'line':
        return _buildLineChart(data);
      case 'pie':
        return _buildPieChart(data);
      default:
        return _buildBarChart(data);
    }
  }

  Widget _buildBarChart(Map<String, dynamic> data) {
    final entries = data.entries.toList();
    final maxY = entries.fold<double>(0, (max, e) {
      final value = (e.value as num).toDouble();
      return value > max ? value : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${entries[group.x.toInt()].key}: ${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= entries.length) {
                        return const Text('');
                      }
                      final label = entries[value.toInt()].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label.length > 4 ? '${label.substring(0, 4)}...' : label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: entries.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: (entry.value.value as num).toDouble(),
                      color: Theme.of(context).primaryColor,
                      width: 16,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(Map<String, dynamic> data) {
    final entries = data.entries.toList();
    final maxY = entries.fold<double>(0, (max, e) {
      final value = (e.value as num).toDouble();
      return value > max ? value : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 300,
          child: LineChart(
            LineChartData(
              maxY: maxY * 1.2,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${entries[spot.x.toInt()].key}: ${spot.y.toInt()}',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= entries.length) {
                        return const Text('');
                      }
                      final label = entries[value.toInt()].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label.length > 4 ? '${label.substring(0, 4)}...' : label,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: entries.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      (entry.value.value as num).toDouble(),
                    );
                  }).toList(),
                  isCurved: true,
                  color: Theme.of(context).primaryColor,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> data) {
    final entries = data.entries.toList();
    final total = entries.fold<double>(0, (sum, e) {
      return sum + (e.value as num).toDouble();
    });

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: entries.asMap().entries.map((entry) {
                    final value = (entry.value.value as num).toDouble();
                    final percentage = total > 0 ? (value / total * 100) : 0;
                    return PieChartSectionData(
                      value: value,
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: colors[entry.key % colors.length],
                      radius: 80,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: entries.asMap().entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[entry.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.value.key,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    final totalCount = _reportData!['total_count'] ?? 0;
    final dimensionData = _reportData!['dimension_data'] as Map<String, dynamic>?;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '总计: $totalCount 条记录',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (dimensionData != null && dimensionData.isNotEmpty) ...[
              const Divider(height: 24),
              ...dimensionData.entries.map((entry) {
                final data = entry.value as Map<String, dynamic>;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DataTable(
                      headingRowHeight: 40,
                      dataRowMinHeight: 40,
                      dataRowMaxHeight: 40,
                      columns: const [
                        DataColumn(label: Text('分类')),
                        DataColumn(label: Text('数量'), numeric: true),
                        DataColumn(label: Text('占比'), numeric: true),
                      ],
                      rows: data.entries.map((e) {
                        final value = (e.value as num).toDouble();
                        final percentage = totalCount > 0
                            ? (value / totalCount * 100).toStringAsFixed(1)
                            : '0.0';
                        return DataRow(
                          cells: [
                            DataCell(Text(e.key)),
                            DataCell(Text(e.value.toString())),
                            DataCell(Text('$percentage%')),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getChartIcon(String chartType) {
    switch (chartType) {
      case 'bar':
        return Icons.bar_chart;
      case 'line':
        return Icons.show_chart;
      case 'pie':
        return Icons.pie_chart;
      case 'radar':
        return Icons.radar;
      default:
        return Icons.assessment;
    }
  }

  String _formatDateTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
