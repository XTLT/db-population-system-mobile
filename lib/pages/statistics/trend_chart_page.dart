import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../api/statistics_api.dart';

class TrendChartPage extends StatefulWidget {
  const TrendChartPage({super.key});

  @override
  State<TrendChartPage> createState() => _TrendChartPageState();
}

class _TrendChartPageState extends State<TrendChartPage> {
  Map<String, dynamic>? _trendData;
  bool _isLoading = true;
  String _groupBy = 'month';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      String? startDate;
      String? endDate;

      if (_dateRange != null) {
        startDate = _dateRange!.start.toIso8601String().split('T')[0];
        endDate = _dateRange!.end.toIso8601String().split('T')[0];
      }

      final data = await StatisticsApi.getTrendData(
        startDate: startDate,
        endDate: endDate,
        groupBy: _groupBy,
      );

      setState(() {
        _trendData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 365)),
            end: now,
          ),
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('趋势分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: '选择时间范围',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildControls(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('分组方式', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('按天'),
                  selected: _groupBy == 'day',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _groupBy = 'day');
                      _loadData();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('按周'),
                  selected: _groupBy == 'week',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _groupBy = 'week');
                      _loadData();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('按月'),
                  selected: _groupBy == 'month',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _groupBy = 'month');
                      _loadData();
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('按年'),
                  selected: _groupBy == 'year',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _groupBy = 'year');
                      _loadData();
                    }
                  },
                ),
              ],
            ),
            if (_dateRange != null) ...[
              const SizedBox(height: 8),
              Text(
                '时间范围: ${DateFormat('yyyy-MM-dd').format(_dateRange!.start)} 至 ${DateFormat('yyyy-MM-dd').format(_dateRange!.end)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_trendData == null) {
      return const Center(child: Text('暂无数据'));
    }

    final labels = List<String>.from(_trendData!['labels'] ?? []);
    final additions = List<int>.from(_trendData!['additions'] ?? []);
    final deletions = List<int>.from(_trendData!['deletions'] ?? []);

    if (labels.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    
    final maxPoints = 12;
    final startIdx = labels.length > maxPoints ? labels.length - maxPoints : 0;
    final displayLabels = labels.sublist(startIdx);
    final displayAdditions = additions.sublist(startIdx);
    final displayDeletions = deletions.sublist(startIdx);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= displayLabels.length) {
                    return const Text('');
                  }
                  final label = displayLabels[idx];
                  
                  String displayLabel;
                  if (_groupBy == 'day') {
                    displayLabel = label.split('-').skip(1).join('-'); 
                  } else if (_groupBy == 'month') {
                    displayLabel = label; 
                  } else {
                    displayLabel = label; 
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      displayLabel,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
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
          minX: 0,
          maxX: (displayLabels.length - 1).toDouble(),
          minY: 0,
          maxY: [
                ...displayAdditions,
                ...displayDeletions,
              ].reduce((a, b) => a > b ? a : b).toDouble() +
              2,
          lineBarsData: [
            
            LineChartBarData(
              spots: List.generate(
                displayAdditions.length,
                (i) => FlSpot(i.toDouble(), displayAdditions[i].toDouble()),
              ),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
            
            LineChartBarData(
              spots: List.generate(
                displayDeletions.length,
                (i) => FlSpot(i.toDouble(), displayDeletions[i].toDouble()),
              ),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final idx = spot.x.toInt();
                  final label = idx < displayLabels.length ? displayLabels[idx] : '';
                  final type = spot.barIndex == 0 ? '新增' : '删除';
                  return LineTooltipItem(
                    '$label\n$type: ${spot.y.toInt()}',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
