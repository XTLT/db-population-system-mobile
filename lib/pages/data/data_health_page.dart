import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/person_api.dart';
import '../../utils/validators.dart';
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

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _errorMessage = null);
    }

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
      if (silent) {
        // 静默刷新失败时保留已有清单，只提示，不把页面刷成错误页
        _snack('刷新体检结果失败：$e');
        return;
      }
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
    final key = (check['key'] as String?) ?? '';
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
                ...items.map(
                  (it) => _buildPersonTile(
                    it,
                    canFillPhone: key == 'phone_empty',
                  ),
                ),
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

  Widget _buildPersonTile(
    Map<String, dynamic> item, {
    bool canFillPhone = false,
  }) {
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
      trailing: canFillPhone
          ? TextButton(
              onPressed: () => _promptPhone(item),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('补录'),
            )
          : const Icon(Icons.chevron_right, size: 18),
      onTap: () async {
        final target = idCard.isNotEmpty ? idCard : personId;
        if (target.isEmpty) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PersonDetailPage(idCard: target),
          ),
        );
        // 详情页可能改过户主/电话等，返回后必须重新体检，否则清单停在旧数据
        if (!mounted) return;
        await _loadData(silent: true);
      },
    );
  }

  /// 在清单里直接补录手机号：弹窗校验 → PUT 保存 → 静默刷新体检结果
  Future<void> _promptPhone(Map<String, dynamic> item) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    final name = (item['name'] as String?) ?? '';
    final huHao = (item['hu_hao'] as String?) ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('补录电话'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty
                    ? '未命名人员'
                    : (huHao.isEmpty ? name : '$name（户号 $huHao）'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '手机号',
                  hintText: '11 位手机号',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  final t = (v ?? '').replaceAll(RegExp(r'\s'), '');
                  if (t.isEmpty) return '请输入手机号';
                  return Validators.validatePhone(t);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    final phone = controller.text.replaceAll(RegExp(r'\s'), '');
    // 不在对话框关闭后立即 dispose，避免 TextField 还持有监听时抛
    // "used after being disposed"；控制器由 GC 回收

    if (confirmed != true || phone.isEmpty) return;

    final idCard = (item['id_card'] as String?) ?? '';
    final personId = (item['person_id'] as String?) ?? '';
    final target = idCard.isNotEmpty ? idCard : personId;
    if (target.isEmpty) {
      _snack('缺少人员标识，无法保存');
      return;
    }

    try {
      final ok = await PersonApi.updatePerson(target, {'phone': phone});
      if (!mounted) return;
      if (!ok) {
        _snack('保存失败，数据可能已被他人修改，请下拉刷新后重试');
        return;
      }
      _snack('已保存 $name 的电话：$phone');
      await _loadData(silent: true);
    } catch (e) {
      if (!mounted) return;
      _snack('保存失败：$e');
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }
}
