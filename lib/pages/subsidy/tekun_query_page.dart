import 'package:flutter/material.dart';
import '../../api/statistics_api.dart';

class TekunQueryPage extends StatefulWidget {
  const TekunQueryPage({super.key});

  @override
  State<TekunQueryPage> createState() => _TekunQueryPageState();
}

class _TekunQueryPageState extends State<TekunQueryPage> {
  String? _selectedPeriod;
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  List<String> _periods = [];

  @override
  void initState() {
    super.initState();
    _loadPeriods();
  }

  @override
  void dispose() {
    _idCardController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadPeriods() async {
    final periods = await StatisticsApi.getTekunPaymentPeriods();
    setState(() {
      _periods = ['全部', ...periods];
      _selectedPeriod = '全部';
    });
  }

  Future<void> _doSearch() async {
    if (_selectedPeriod == null && _idCardController.text.trim().isEmpty && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入身份证号/姓名或选择月份')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await StatisticsApi.queryTekunPayments(
        period: _selectedPeriod,
        idCard: _idCardController.text.trim(),
        name: _nameController.text.trim(),
      );
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      if (mounted) {
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
        title: const Text('特困发放查询'),
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
              value: _selectedPeriod,
              decoration: const InputDecoration(
                labelText: '费款所属期',
                border: OutlineInputBorder(),
                isDense: true,
                hintText: '选择月份',
              ),
              items: _periods.map((p) {
                final display = p.length >= 6
                    ? '${p.substring(0, 4)}年${p.substring(4)}月'
                    : p;
                return DropdownMenuItem(value: p, child: Text(display));
              }).toList(),
              onChanged: (v) => setState(() => _selectedPeriod = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idCardController,
              decoration: const InputDecoration(
                labelText: '身份证号',
                border: OutlineInputBorder(),
                isDense: true,
                hintText: '输入身份证号查询',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                border: OutlineInputBorder(),
                isDense: true,
                hintText: '输入姓名查询',
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
        child: Text('输入条件后点击查询', style: TextStyle(color: Colors.grey)),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return const Center(child: Text('未找到特困发放记录'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final record = _results[index];
        final period = record['period'] ?? '';
        final periodDisplay = period.length >= 6
            ? '${period.substring(0, 4)}年${period.substring(4)}月'
            : period;

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
                      record['name'] ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(periodDisplay, style: TextStyle(fontSize: 12, color: Colors.teal.shade700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('身份证号：${record['id_card'] ?? ''}', style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text('银行账号：${record['bank_account'] ?? ''}', style: const TextStyle(fontSize: 13)),
                if (record['relation'] != null && record['relation'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('和申请人关系：${record['relation']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '金额：${record['amount'] ?? '0'} 元',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                    ),
                    if (record['payment_status'] != null && record['payment_status'].toString().isNotEmpty)
                      Chip(
                        label: Text(record['payment_status'], style: const TextStyle(fontSize: 11)),
                        backgroundColor: record['payment_status'] == '支付成功'
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
