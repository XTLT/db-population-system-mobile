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
  String? _loadError;
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

  // ---- 健壮解析：容忍 int/double/String/null 混入，杜绝 build 期 TypeError ----
  double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v is num) {
      final d = v.toDouble();
      return d.isNaN || d.isInfinite ? fallback : d;
    }
    if (v is String) {
      return double.tryParse(v.trim()) ?? fallback;
    }
    return fallback;
  }

  List<String> _toStringList(dynamic v) {
    if (v is List) {
      return v
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<double> _toDoubleList(dynamic v) {
    if (v is List) {
      return v.map((e) => _toDouble(e)).toList();
    }
    return [];
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final data = await StatisticsApi.getComparison(dimensions: _selectedDimensions);
      if (!mounted) return;
      setState(() {
        _comparisonData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _comparisonData = null;
        _isLoading = false;
        _loadError = e.toString();
      });
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

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? '未知错误',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loadError != null) {
      return _buildErrorView();
    }
    if (_comparisonData == null) {
      return const Center(child: Text('暂无数据'));
    }

    // 整段解析包在 try 中：即使服务端返回结构异常，也转为可见错误而非灰屏
    try {
      final dimensions = _toStringList(_comparisonData!['dimensions']);
      final rawValues = _toDoubleList(_comparisonData!['raw_values']);
      final normalizedValues = _toDoubleList(_comparisonData!['values'])
          .map((v) => v.clamp(0.0, 100.0).toDouble())
          .toList();
      final total = _toDouble(_comparisonData!['total']).toInt();

      if (dimensions.isEmpty) {
        return const Center(child: Text('暂无数据'));
      }

      // 对齐三个列表长度，防止下标越界；取三者最小长度
      final lenList = [
        dimensions.length,
        rawValues.length,
        normalizedValues.length,
      ];
      final n = lenList.reduce((a, b) => a < b ? a : b);
      if (n == 0) {
        return const Center(child: Text('暂无数据'));
      }
      final dims = dimensions.sublist(0, n);
      final raws = rawValues.sublist(0, n);
      final norms = normalizedValues.sublist(0, n);

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
                          radarBorderData:
                              const BorderSide(color: Colors.grey, width: 1),
                          gridBorderData:
                              const BorderSide(color: Colors.grey, width: 1),
                          titlePositionPercentageOffset: 0.2,
                          getTitle: (index, angle) {
                            if (index < 0 || index >= dims.length) {
                              return const RadarChartTitle(text: '');
                            }
                            return RadarChartTitle(
                              text: dims[index],
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
                                norms.length,
                                (i) => RadarEntry(value: norms[i]),
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
            _buildDetailList(dims, raws, norms),
          ],
        ),
      );
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined,
                  color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              Text('数据格式异常', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                '$e',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
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
                        value: (normalized / 100).clamp(0.0, 1.0).toDouble(),
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