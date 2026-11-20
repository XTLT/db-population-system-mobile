import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/notification_api.dart';
import '../../api/person_api.dart';
import '../../providers/sync_provider.dart';
import '../../utils/todo_summary.dart';
import '../correction/pending_correction_page.dart';
import '../data/data_health_page.dart';
import '../notification/notification_center_page.dart';
import 'offline_queue_page.dart';

/// 村级待办工作台
///
/// 把分散在体检页、待核销页、通知中心、离线队列里的"该做的事"汇总成一屏，
/// 每条都能直接点进去处理。所有计数只读，不改任何业务数据。
class TodoCenterPage extends StatefulWidget {
  const TodoCenterPage({super.key});

  @override
  State<TodoCenterPage> createState() => _TodoCenterPageState();
}

class _TodoCenterPageState extends State<TodoCenterPage> {
  bool _loading = true;
  bool _inFlight = false;
  bool _healthError = false;
  bool _correctionError = false;
  bool _ageError = false;

  HealthTodoSummary _health = const HealthTodoSummary();
  int _correctionTotal = 0;
  AgeTodoSummary _age = const AgeTodoSummary();
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // 连点刷新 / 下拉与切页同时触发时，只保留一轮请求
    if (_inFlight) return;
    _inFlight = true;
    try {
      await Future.wait([
        _loadHealth(),
        _loadCorrection(),
        _loadAge(),
      ]);
      if (!mounted) return;
      await context.read<SyncProvider>().loadStatus();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _lastUpdated = DateTime.now();
      });
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _loadHealth() async {
    try {
      final data = await PersonApi.getDataHealth();
      if (!mounted) return;
      setState(() {
        _health = summarizeDataHealth(data);
        _healthError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _healthError = true);
    }
  }

  Future<void> _loadCorrection() async {
    try {
      final data = await PersonApi.getPendingCorrection();
      if (!mounted) return;
      setState(() {
        _correctionTotal = (data['total'] as num?)?.toInt() ?? 0;
        _correctionError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _correctionError = true);
    }
  }

  Future<void> _loadAge() async {
    try {
      final list = await NotificationApi.getNotifications(limit: 50);
      if (!mounted) return;
      setState(() {
        _age = summarizeAgeNotifications(list);
        _ageError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _ageError = true);
    }
  }

  /// 进子页面处理完回来，重新汇总一次，数字立刻跟上。
  Future<void> _openAndRefresh(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final total = _health.issueCount +
        _correctionTotal +
        _age.persons +
        sync.pendingCount;

    return RefreshIndicator(
      onRefresh: _load,
      child: _loading
          ? ListView(
              children: const [
                SizedBox(height: 160),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _buildHeader(total, sync),
                const SizedBox(height: 4),
                _card(
                  icon: Icons.fact_check_outlined,
                  color: Colors.teal,
                  title: '数据体检',
                  value: _healthError ? '—' : '${_health.issueCount} 条',
                  subtitle: _healthError
                      ? '加载失败，下拉刷新重试'
                      : _health.isEmpty
                          ? '数据完整，没有待补录项'
                          : '${_health.issuePersons} 人 · ${_health.topItems}',
                  onTap: () => _openAndRefresh(const DataHealthPage()),
                ),
                _card(
                  icon: Icons.assignment_late_outlined,
                  color: Colors.deepOrange,
                  title: '待核销',
                  value: _correctionError ? '—' : '$_correctionTotal 人',
                  subtitle: _correctionError
                      ? '加载失败，下拉刷新重试'
                      : '已死亡或迁出，但名下仍有补贴记录',
                  onTap: () => _openAndRefresh(const PendingCorrectionPage()),
                ),
                _card(
                  icon: Icons.cake_outlined,
                  color: Colors.blue,
                  title: '到龄提醒',
                  value: _ageError ? '—' : '${_age.persons} 人',
                  subtitle: _ageError
                      ? '加载失败，下拉刷新重试'
                      : _age.isEmpty
                          ? '暂无下月满 60/80 周岁人员'
                          : '${_age.monthLabel}满 60/80 周岁'
                              '${_age.unread > 0 ? '，${_age.unread} 条未读' : ''}',
                  onTap: () => _openAndRefresh(const NotificationCenterPage()),
                ),
                _card(
                  icon: Icons.cloud_upload_outlined,
                  color: sync.conflictCount > 0
                      ? Colors.red.shade700
                      : Colors.purple,
                  title: '待同步数据',
                  value: '${sync.pendingCount} 条',
                  subtitle: sync.conflictCount > 0
                      ? '其中 ${sync.conflictCount} 条冲突待处理'
                      : sync.pendingCount > 0
                          ? '断网保存的改动，联网后自动提交'
                          : '没有待同步的数据',
                  onTap: () => _openAndRefresh(const OfflineQueuePage()),
                ),
                const SizedBox(height: 8),
                Text(
                  '合计为项次之和：同一个人可能同时出现在多项里，不能当作人数。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(int total, SyncProvider sync) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.teal.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '村级待办',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  total == 0 ? '今天没有待办事项' : '共 $total 项待处理',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
                if (_lastUpdated != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '更新于 ${_formatClock(_lastUpdated!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
                if (sync.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    sync.errorMessage!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  String _formatClock(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}';
  }

  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
