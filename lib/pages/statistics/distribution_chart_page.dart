import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../api/statistics_api.dart';

class DistributionChartPage extends StatefulWidget {
  const DistributionChartPage({super.key});

  @override
  State<DistributionChartPage> createState() => _DistributionChartPageState();
}

class _DistributionChartPageState extends State<DistributionChartPage> {
  Map<String, int>? _distributionData;
  bool _isLoading = true;
  String _selectedField = 'age_group';

  final Map<String, String> _fieldLabels = {
    'age_group': '年龄段',
    'disability': '残疾情况',
    'dibao': '低保类别',
    'gender': '性别',
  };

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await StatisticsApi.getDistribution(_selectedField);
      setState(() {
        _distributionData = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('分布分析'),
      ),
      body: Column(
        children: [
          _buildFieldSelector(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _selectedField,
          decoration: const InputDecoration(
            labelText: '分析字段',
            border: OutlineInputBorder(),
          ),
          items: _fieldLabels.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedField = value);
              _loadData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_distributionData == null || _distributionData!.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final total = _distributionData!.values.reduce((a, b) => a + b);
    final entries = _distributionData!.entries.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: List.generate(entries.length, (index) {
                  final entry = entries[index];
                  final percentage = (entry.value / total * 100).toStringAsFixed(1);
                  final color = _colors[index % _colors.length];

                  return PieChartSectionData(
                    value: entry.value.toDouble(),
                    title: '$percentage%',
                    color: color,
                    radius: 100,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(entries, total),
        ],
      ),
    );
  }

  Widget _buildLegend(List<MapEntry<String, int>> entries, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据详情',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...entries.asMap().entries.map((mapEntry) {
              final index = mapEntry.key;
              final entry = mapEntry.value;
              final color = _colors[index % _colors.length];
              final percentage = (entry.value / total * 100).toStringAsFixed(1);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key.isEmpty ? '未知' : entry.key,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${entry.value} ($percentage%)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '总计',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  total.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
