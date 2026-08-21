import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../api/statistics_api.dart';

class RadarChartPage extends StatefulWidget {
  const RadarChartPage({super.key});

  @override
  State<RadarChartPage> createState() => _RadarChartPageState();
}

class _RadarChartPageState extends State<RadarChartPage> {
  Map<String, dynamic>? _comparisonData;
  bool _isLoading = true;
  final List<String> _selectedDimensions = ['age', 'disability', 'dibao', 'migration', 'student'];

  final Map<String, String> _dimensionLabels = {
    'age': '平均年龄',
    'disability': '残疾人员',
    'dibao': '低保人员',
    'migration': '迁出人员',
    'death': '去世人员',
    'student': '在读学生',
    'gender_male': '男性比例',
    'gender_female': '女性比例',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final data = await StatisticsApi.getComparison(dimensions: _selectedDimensions);
      setState(() {
        _comparisonData = data;
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

  Future<void> _showDimensionSelector() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '选择维度',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadData();
                        },
                        child: const Text('确定'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dimensionLabels.entries.map((entry) {
                      final isSelected = _selectedDimensions.contains(entry.key);
                      return FilterChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              if (!_selectedDimensions.contains(entry.key)) {
                                _selectedDimensions.add(entry.key);
                              }
                            } else {
                              _selectedDimensions.remove(entry.key);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedDimensions.length < 3)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        '建议至少选择 3 个维度',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('多维对比分析'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showDimensionSelector,
            tooltip: '选择维度',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_comparisonData == null || _selectedDimensions.isEmpty) {
      return const Center(child: Text('请选择至少一个维度'));
    }

    final dimensions = List<String>.from(_comparisonData!['dimensions'] ?? []);
    final values = List<double>.from(_comparisonData!['raw_values'] ?? []);
    final normalizedValues = List<double>.from(_comparisonData!['values'] ?? []);
    final total = _comparisonData!['total'] ?? 0;

    if (dimensions.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '数据概览',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '总人口: $total 人',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: RadarChart(
                      RadarChartData(
                        radarShape: RadarShape.polygon,
                        tickCount: 5,
                        ticksTextStyle: const TextStyle(fontSize: 10),
                        radarBorderData: const BorderSide(color: Colors.grey, width: 1),
                        gridBorderData: const BorderSide(color: Colors.grey, width: 1),
                        titlePositionPercentageOffset: 0.2,
                        getTitle: (index, angle) {
                          if (index < 0 || index >= dimensions.length) {
                            return const RadarChartTitle(text: '');
                          }
                          return RadarChartTitle(
                            text: dimensions[index],
                            angle: angle,
                            positionPercentageOffset: 0.2,
                          );
                        },
                        dataSets: [
                          RadarDataSet(
                            fillColor: Colors.blue.withOpacity(0.3),
                            borderColor: Colors.blue,
                            borderWidth: 2,
                            entryRadius: 4,
                            dataEntries: List.generate(
                              normalizedValues.length,
                              (i) => RadarEntry(value: normalizedValues[i]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          
          _buildDetailList(dimensions, values, normalizedValues),
        ],
      ),
    );
  }

  Widget _buildDetailList(
    List<String> dimensions,
    List<double> values,
    List<double> normalizedValues,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '详细数据',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...List.generate(dimensions.length, (index) {
              final dimension = dimensions[index];
              final value = values[index];
              final normalized = normalizedValues[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dimension,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _formatValue(dimension, value),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: normalized / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getColorForValue(normalized),
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '百分比: ${normalized.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatValue(String dimension, double value) {
    if (dimension == '平均年龄') {
      return '${value.toStringAsFixed(1)} 岁';
    } else {
      return '${value.toInt()} 人';
    }
  }

  Color _getColorForValue(double value) {
    if (value < 20) {
      return Colors.green;
    } else if (value < 40) {
      return Colors.lightGreen;
    } else if (value < 60) {
      return Colors.orange;
    } else if (value < 80) {
      return Colors.deepOrange;
    } else {
      return Colors.red;
    }
  }
}
