import 'package:flutter/material.dart';
import '../../models/custom_report.dart';
import '../../api/custom_report_api.dart';

class CustomReportBuilderPage extends StatefulWidget {
  final CustomReport? report;

  const CustomReportBuilderPage({super.key, this.report});

  @override
  State<CustomReportBuilderPage> createState() => _CustomReportBuilderPageState();
}

class _CustomReportBuilderPageState extends State<CustomReportBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  
  String? _reportType;
  List<String> _selectedDimensions = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _chartType = 'bar';
  Map<String, dynamic> _filters = {};
  
  bool _isLoading = false;
  bool _isPreviewLoading = false;
  Map<String, dynamic>? _previewData;
  
  final Map<String, List<String>> _dimensionOptions = {
    'person': ['性别', '年龄段', '民族', '文化程度', '婚姻状况', '政治面貌'],
    'student': ['年级', '学校', '性别', '年龄段', '民族'],
    'subsidy': ['补贴类型', '发放状态', '年龄段', '性别'],
  };
  
  final Map<String, Map<String, List<String>>> _filterOptions = {
    'person': {
      'is_dead': ['是', '否'],
      'poor_type': ['贫困户', '低保户', '特困户', '非贫困户'],
      'disability': ['是', '否'],
      'dibao': ['是', '否', '低保边缘家庭', '特困家庭'],
    },
    'student': {
      'grade': ['托班', '幼儿园小班', '幼儿园中班', '幼儿园大班', '小学1年级', '小学2年级', '小学3年级', '小学4年级', '小学5年级', '小学6年级', '初中1年级', '初中2年级', '初中3年级', '高中1年级', '高中2年级', '高中3年级', '职高1年级', '职高2年级', '职高3年级', '技校1年级', '技校2年级', '技校3年级', '中专1年级', '中专2年级', '中专3年级', '专科1年级', '专科2年级', '专科3年级', '大学1年级', '大学2年级', '大学3年级', '大学4年级', '大学5年级', '硕士1年级', '硕士2年级', '硕士3年级', '博士1年级', '博士2年级', '博士3年级', '博士4年级', '已毕业'],
    },
    'subsidy': {
      'status': ['已发放', '未发放', '已取消'],
    },
  };

  @override
  void initState() {
    super.initState();
    
    if (widget.report != null) {
      _titleController.text = widget.report!.title;
      _reportType = widget.report!.reportType;
      _selectedDimensions = List.from(widget.report!.dimensions);
      _chartType = widget.report!.chartType;
      _filters = Map.from(widget.report!.filters);
      
      if (widget.report!.dateRange.containsKey('start')) {
        _startDate = DateTime.tryParse(widget.report!.dateRange['start']!);
      }
      if (widget.report!.dateRange.containsKey('end')) {
        _endDate = DateTime.tryParse(widget.report!.dateRange['end']!);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _previewReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reportType == null || _selectedDimensions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择报表类型和统计维度')),
      );
      return;
    }

    setState(() {
      _isPreviewLoading = true;
      _previewData = null;
    });

    try {
      final data = await CustomReportApi.generateReport(
        reportType: _reportType!,
        dimensions: _selectedDimensions,
        dateRange: _buildDateRange(),
        filters: _filters,
      );

      setState(() {
        _previewData = data;
        _isPreviewLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('预览生成成功')),
        );
      }
    } catch (e) {
      setState(() {
        _isPreviewLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('预览失败: $e')),
        );
      }
    }
  }

  Future<void> _saveReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reportType == null || _selectedDimensions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择报表类型和统计维度')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.report != null) {
        await CustomReportApi.updateReport(
          widget.report!.id,
          title: _titleController.text,
          reportType: _reportType,
          dimensions: _selectedDimensions,
          dateRange: _buildDateRange(),
          chartType: _chartType,
          filters: _filters,
        );
      } else {
        await CustomReportApi.createReport(
          title: _titleController.text,
          reportType: _reportType!,
          dimensions: _selectedDimensions,
          dateRange: _buildDateRange(),
          chartType: _chartType,
          filters: _filters,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.report != null ? '报表已更新' : '报表已创建')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Map<String, String> _buildDateRange() {
    final range = <String, String>{};
    if (_startDate != null) {
      range['start'] = _startDate!.toIso8601String().split('T')[0];
    }
    if (_endDate != null) {
      range['end'] = _endDate!.toIso8601String().split('T')[0];
    }
    return range;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.report != null ? '编辑报表' : '创建报表'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.preview),
              tooltip: '预览',
              onPressed: _isPreviewLoading ? null : _previewReport,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '报表标题',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入报表标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _reportType,
              decoration: const InputDecoration(
                labelText: '报表类型',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'person', child: Text('人口统计')),
                DropdownMenuItem(value: 'student', child: Text('学生统计')),
                DropdownMenuItem(value: 'subsidy', child: Text('补贴统计')),
              ],
              onChanged: (value) {
                setState(() {
                  _reportType = value;
                  _selectedDimensions.clear();
                  _filters.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            
            if (_reportType != null) ...[
              const Text(
                '统计维度',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_dimensionOptions[_reportType] ?? []).map((dim) {
                  final isSelected = _selectedDimensions.contains(dim);
                  return FilterChip(
                    label: Text(dim),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDimensions.add(dim);
                        } else {
                          _selectedDimensions.remove(dim);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            const Text(
              '时间范围',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '开始日期',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _startDate != null
                            ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                            : '选择日期',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '结束日期',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _endDate != null
                            ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                            : '选择日期',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              initialValue: _chartType,
              decoration: const InputDecoration(
                labelText: '图表类型',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bar_chart),
              ),
              items: const [
                DropdownMenuItem(value: 'bar', child: Text('柱状图')),
                DropdownMenuItem(value: 'line', child: Text('折线图')),
                DropdownMenuItem(value: 'pie', child: Text('饼图')),
                DropdownMenuItem(value: 'radar', child: Text('雷达图')),
              ],
              onChanged: (value) {
                setState(() {
                  _chartType = value ?? 'bar';
                });
              },
            ),
            const SizedBox(height: 16),
            
            if (_reportType != null && _filterOptions[_reportType] != null) ...[
              const Text(
                '筛选条件',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._filterOptions[_reportType]!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _filters[entry.key],
                    decoration: InputDecoration(
                      labelText: _getFilterLabel(entry.key),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('不限')),
                      ...entry.value.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        if (value != null) {
                          _filters[entry.key] = value;
                        } else {
                          _filters.remove(entry.key);
                        }
                      });
                    },
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            
            if (_isPreviewLoading)
              const Center(child: CircularProgressIndicator())
            else if (_previewData != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '预览数据',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('共 ${_previewData!['total_count'] ?? 0} 条记录'),
                      if (_previewData!['dimension_data'] != null)
                        Text('维度: ${_previewData!['dimension_data'].keys.join(', ')}'),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveReport,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.report != null ? '更新报表' : '创建报表'),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterLabel(String key) {
    const labels = {
      'is_dead': '是否去世',
      'poor_type': '贫困户类型',
      'disability': '残疾情况',
      'dibao': '低保情况',
      'grade': '年级',
      'status': '发放状态',
    };
    return labels[key] ?? key;
  }
}
