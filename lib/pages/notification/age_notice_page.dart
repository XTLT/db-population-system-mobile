import 'package:flutter/material.dart';

import '../../api/notification_api.dart';
import '../../models/age_notice.dart';

/// 到龄提醒：累积的待办名单。
///
/// 没办的人会一直留着；点「已办理」后当月仍然显示（标记为已办理），
/// 到下一个自然月才从名单里消失。
class AgeNoticePage extends StatefulWidget {
  const AgeNoticePage({super.key});

  @override
  State<AgeNoticePage> createState() => _AgeNoticePageState();
}

class _AgeNoticePageState extends State<AgeNoticePage> {
  bool _isLoading = true;
  String? _errorMessage;
  AgeNoticeData _data = const AgeNoticeData();

  // 正在提交的人员，防止连点重复请求
  final Set<String> _handling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final raw = await NotificationApi.getAgeNotice();
      if (!mounted) return;
      setState(() {
        _data = AgeNoticeData.fromJson(raw);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markHandled(AgeNoticePerson person, int ageGroup) async {
    final key = '${person.personId}_$ageGroup';
    if (_handling.contains(key)) return;
    setState(() => _handling.add(key));
    try {
      final ok = await NotificationApi.markAgeNoticeHandled(
        personId: person.personId,
        ageGroup: ageGroup,
        name: person.name,
        idCard: person.idCard,
        month: person.targetMonth.isNotEmpty
            ? person.targetMonth
            : _data.monthKey,
      );
      if (!mounted) return;
      if (!ok) throw Exception('服务端未确认');
      setState(() => _data = _data.markHandled(person.personId, ageGroup));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已办理「${person.name}」，下月起不再提醒')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('标记失败：$e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _handling.remove(key));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('到龄提醒'),
        actions: [
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
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
            ElevatedButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSummary(),
          ..._data.groups.map(_buildGroup),
          if (_data.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 56),
              child: Center(
                child: Text('没有需要办理的到龄人员',
                    style: TextStyle(color: Colors.grey)),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final pending = _data.pendingCount;
    final handled = _data.handledCount;
    final clean = pending == 0;
    final accent = clean ? Colors.green : Colors.blue;
    final text = clean
        ? (_data.total == 0
            ? '没有待办理的到龄人员'
            : '本月 $handled 人已全部办理，下月起不再提醒')
        : '共 $pending 人待办理'
            '${handled > 0 ? '，本月已办理 $handled 人（下月不再提醒）' : ''}';
    return Card(
      elevation: 0,
      color: accent.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(clean ? Icons.verified : Icons.cake_outlined,
                color: accent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(AgeNoticeGroup group) {
    if (group.persons.isEmpty) return const SizedBox.shrink();
    final handled = group.handledCount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            '满 ${group.age} 周岁（待办 ${group.pendingCount} 人'
            '${handled > 0 ? '，已办理 $handled 人' : ''}）',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        ...group.persons.map((p) => _buildPersonCard(p, group.age)),
      ],
    );
  }

  Widget _buildPersonCard(AgeNoticePerson person, int ageGroup) {
    final key = '${person.personId}_$ageGroup';
    final busy = _handling.contains(key);
    final handled = person.handled;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              (handled ? Colors.green : Colors.blue).withValues(alpha: 0.12),
          child: Text(
            person.name.isEmpty ? '?' : person.name.substring(0, 1),
            style: TextStyle(
                color: handled ? Colors.green : Colors.blue, fontSize: 14),
          ),
        ),
        title: Text(
          person.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: handled ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          person.detailLine,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            height: 1.4,
          ),
        ),
        isThreeLine: true,
        trailing: busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : handled
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 4),
                      Text('已办理',
                          style:
                              TextStyle(color: Colors.green, fontSize: 13)),
                    ],
                  )
                : OutlinedButton(
                    onPressed: () => _markHandled(person, ageGroup),
                    child: const Text('已办理'),
                  ),
      ),
    );
  }
}
