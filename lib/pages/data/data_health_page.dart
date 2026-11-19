import 'package:flutter/material.dart';

import '../../api/person_api.dart';
import '../person/person_detail_page.dart';

/// 村级数据体检
///
/// 按常见数据质量问题分组列出待补录人员：缺身份证、身份证格式错、
/// 缺电话、缺户号、本户无户主、同一身份证挂多个户号、学生缺监护人电话。
/// 只读清单，点人跳人员详情去改，不在本页修改任何数据。
class DataHealthPage extends StatefulWidget {
  const DataHealthPage({super.key});

  @override
  State<DataHealthPage> createState() => _DataHealthPageState();
}

class _DataHealthPageState extends State<DataHealthPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String _checkedAt = '';
  int _totalAlive = 0;
  int _totalIssuePersons = 0;
  int _totalIssueCount = 0;
  List<Map<String, dynamic>> _checks = [];

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
      final data = await PersonApi.getDataHealth();
      final rawChecks = (data['checks'] as List?) ?? const [];
      final checks = rawChecks
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _checks = checks;
        _checkedAt = (data['checked_at'] as String?) ?? '';
        _totalAlive = (data['total_alive'] as num?)?.toInt() ?? 0;
        _totalIssuePersons =
            (data['total_issue_persons'] as num?)?.toInt() ?? 0;
        _totalIssueCount =
            (data['total_issue_count'] as num?)?.toInt() ?? 0;
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
        title: const Text('数据体检'),
        actions: [
          IconButton(
            tooltip: '重新体检',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildError()
              : _buildBody(),
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

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 8),
          if (_checks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('暂无体检结果')),
            )
          else
            ..._checks.map(_buildCheckCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final clean = _totalIssuePersons == 0;
    final accent = clean ? Colors.green : Colors.orange;
    return Card(
      elevation: 0,
      color: accent.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  clean ? Icons.verified : Icons.assignment_late,
                  color: accent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  clean ? '数据很干净' : '有 $_totalIssuePersons 人需要补录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSummaryStat('在册在世', '$_totalAlive'),
                _buildSummaryStat('涉及人数', '$_totalIssuePersons'),
                _buildSummaryStat('问题条数', '$_totalIssueCount'),
              ],
            ),
            if (_checkedAt.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '体检时间：$_checkedAt',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckCard(Map<String, dynamic> check) {
    final label = (check['label'] as String?) ?? '';
    final count = (check['count'] as num?)?.toInt() ?? 0;
    final severity = (check['severity'] as String?) ?? 'medium';
    final truncated = (check['truncated'] as bool?) ?? false;
    final rawItems = (check['items'] as List?) ?? const [];
    final items =
        rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    final color = count == 0
        ? Colors.grey
        : (severity == 'high' ? Colors.red.shade600 : Colors.orange.shade700);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: EdgeInsets.zero,
        leading: Icon(
          count == 0 ? Icons.check_circle : Icons.error_outline,
          color: color,
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          count == 0 ? '无问题' : '$count 条',
          style: TextStyle(fontSize: 12, color: color),
        ),
        trailing: count == 0
            ? const SizedBox.shrink()
            : const Icon(Icons.keyboard_arrow_down),
        children: items.isEmpty
            ? const []
            : [
                ...items.map(_buildPersonTile),
                if (truncated)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Text(
                      '只显示前 ${items.length} 条，请到电脑端查看完整清单',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
      ),
    );
  }

  Widget _buildPersonTile(Map<String, dynamic> item) {
    final name = (item['name'] as String?) ?? '';
    final huHao = (item['hu_hao'] as String?) ?? '';
    final group = (item['group_name'] as String?) ?? '';
    final detail = (item['detail'] as String?) ?? '';
    final idCard = (item['id_card'] as String?) ?? '';
    final personId = (item['person_id'] as String?) ?? '';

    final subtitleParts = <String>[
      if (huHao.isNotEmpty) '户号 $huHao',
      if (group.isNotEmpty) group,
      if (detail.isNotEmpty) detail,
    ];

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey.shade200,
        child: Text(
          name.isNotEmpty ? name.substring(0, 1) : '?',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
      ),
      title: Text(name.isEmpty ? '（无姓名）' : name),
      subtitle: subtitleParts.isEmpty
          ? null
          : Text(
              subtitleParts.join(' · '),
              style: const TextStyle(fontSize: 12),
            ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        final target = idCard.isNotEmpty ? idCard : personId;
        if (target.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PersonDetailPage(idCard: target),
          ),
        );
      },
    );
  }
}
