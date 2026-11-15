import 'package:flutter/material.dart';

import '../../api/person_api.dart';
import '../person/person_detail_page.dart';

/// 待核销人员清单
///
/// 列出"已标记死亡或迁出、但名下仍挂着补贴发放记录"的人员。
/// 只读排查清单：点进去到人员详情处理对应补贴，不在本页改任何数据。
class PendingCorrectionPage extends StatefulWidget {
  const PendingCorrectionPage({super.key});

  @override
  State<PendingCorrectionPage> createState() => _PendingCorrectionPageState();
}

class _PendingCorrectionPageState extends State<PendingCorrectionPage> {
  bool _isLoading = true;
  String? _errorMessage;
  int _total = 0;
  List<Map<String, dynamic>> _items = [];

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
      final data = await PersonApi.getPendingCorrection();
      final rawList = (data['items'] as List?) ?? const [];
      final items = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _items = items;
        _total = (data['total'] as num?)?.toInt() ?? items.length;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('待核销人员'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : _items.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败：$_errorMessage', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, size: 72, color: Colors.green.shade300),
          const SizedBox(height: 16),
          Text(
            '没有需要核销的人员',
            style: TextStyle(fontSize: 17, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            '已死亡或迁出的人员名下已无补贴发放记录',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '共 $_total 人待核销：这些人已标记死亡或迁出，但名下还有在发的补贴记录，需要到对应补贴模块停发/删除。',
                  style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._items.map(_buildPersonCard),
      ],
    );
  }

  Widget _buildPersonCard(Map<String, dynamic> item) {
    final name = (item['name'] ?? '').toString();
    final idCard = (item['id_card'] ?? '').toString();
    final huHao = (item['hu_hao'] ?? '').toString();
    final groupName = (item['group_name'] ?? '').toString();
    final isDead = (item['is_dead'] ?? '').toString() == '是';
    final isMigrated = (item['is_migrated'] ?? '').toString() == '是';
    final moduleCount = (item['module_count'] as num?)?.toInt() ?? 0;
    final modules = ((item['modules'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          if (idCard.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PersonDetailPage(idCard: idCard),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name.isEmpty ? '（无姓名）' : name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isDead)
                    _buildTag('已死亡', Colors.red),
                  if (isDead && isMigrated) const SizedBox(width: 4),
                  if (isMigrated) _buildTag('已迁出', Colors.orange),
                  const Spacer(),
                  Text(
                    '$moduleCount 类补贴',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '身份证: ${idCard.isEmpty ? "未知" : idCard}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              if (huHao.isNotEmpty || groupName.isNotEmpty)
                Text(
                  [
                    if (huHao.isNotEmpty) '户号 $huHao',
                    if (groupName.isNotEmpty) groupName,
                  ].join('  '),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              const SizedBox(height: 8),
              ...modules.map(_buildModuleRow),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
                  Text(
                    '点击查看人员详情去处理',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleRow(Map<String, dynamic> m) {
    final label = (m['label'] ?? '').toString();
    final count = (m['count'] as num?)?.toInt() ?? 0;
    final latest = (m['latest_period'] ?? '').toString();
    final lastAmount = (m['last_amount'] ?? '').toString();
    final totalAmount = (m['total_amount'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.red.shade700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                '$count 笔',
                if (latest.isNotEmpty) '最近 $latest',
                if (lastAmount.isNotEmpty) '¥$lastAmount',
                if (totalAmount.isNotEmpty) '合计 ¥$totalAmount',
              ].join('  '),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color.shade800),
      ),
    );
  }
}
