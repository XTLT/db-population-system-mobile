import 'package:flutter/material.dart';
import '../../api/statistics_api.dart';

class LandSubsidyQueryPage extends StatefulWidget {
  const LandSubsidyQueryPage({super.key});

  @override
  State<LandSubsidyQueryPage> createState() => _LandSubsidyQueryPageState();
}

class _LandSubsidyQueryPageState extends State<LandSubsidyQueryPage> {
  String? _selectedYear;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  List<String> _years = [];

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadYears() async {
    try {
      final years = await StatisticsApi.getLandSubsidyYears();
      if (mounted) {
        setState(() {
          _years = ['全部', ...years];
          _selectedYear = '全部';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _years = ['全部'];
          _selectedYear = '全部';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('年度加载失败: $e')),
        );
      }
    }
  }

  Future<void> _doSearch() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await StatisticsApi.queryLandSubsidies(
        year: _selectedYear,
        search: _searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('查询失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地力补贴明细'),
      ),
      body: Column(
        children: [
          _buildFilterCard(),
          Expanded(child: _buildResultList()),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedYear,
              menuMaxHeight: 300,
              decoration: const InputDecoration(
                labelText: '补贴年度',
                border: OutlineInputBorder(),
                isDense: true,
                hintText: '选择年度',
              ),
              items: _years.map((y) {
                return DropdownMenuItem(value: y, child: Text(y == '全部' ? '全部年度' : '$y 年'));
              }).toList(),
              onChanged: (v) => setState(() => _selectedYear = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '姓名/身份证号',
                border: OutlineInputBorder(),
                isDense: true,
                hintText: '输入姓名或身份证号查询',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _doSearch,
                icon: _isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search),
                label: const Text('查询'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultList() {
    if (!_hasSearched) {
      return const Center(
        child: Text('选择年度或输入姓名后点击查询', style: TextStyle(color: Colors.grey)),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return const Center(child: Text('未找到地力补贴记录'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final s = _results[index];
        final year = s['year'] ?? '';
        final yearDisplay = year.toString().isNotEmpty ? '$year 年' : '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${index + 1}. ${s['name'] ?? ''}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (yearDisplay.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(yearDisplay, style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                _infoRow('身份证号', s['id_card'] ?? ''),
                _infoRow('电话号码', s['phone'] ?? ''),
                _infoRow('银行账号', s['bank_account'] ?? ''),
                _infoRow('金融机构', s['bank_name'] ?? ''),
                _infoRow('上账时间', s['land_time'] ?? ''),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '发放金额：${s['total_amount'] ?? '0'} 元',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _infoRow('耕地面积', '${s['certified_area'] ?? ''} 亩'),
                _infoRow('耕地标准', '${s['base_standard'] ?? ''} 元/亩'),
                _infoRow('油菜面积', '${s['rape_area'] ?? ''} 亩'),
                _infoRow('油菜标准', '${s['rape_standard'] ?? ''} 元/亩'),
                _infoRow('油菜金额', '${s['rape_amount'] ?? ''} 元'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label：',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Expanded(
            child: Text(
              value.toString().isEmpty ? '-' : value.toString(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
