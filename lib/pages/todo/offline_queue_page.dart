import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/offline_operation.dart';
import '../../providers/sync_provider.dart';
import '../../services/offline_data_service.dart';
import '../sync/conflict_resolution_page.dart';

/// 离线待同步队列
///
/// 断网或服务器不可达时保存的人员改动会落在这里；网络恢复后自动重试，
/// 也可以在本页手动重试、或删除不再需要的草稿。
class OfflineQueuePage extends StatefulWidget {
  const OfflineQueuePage({super.key});

  @override
  State<OfflineQueuePage> createState() => _OfflineQueuePageState();
}

class _OfflineQueuePageState extends State<OfflineQueuePage> {
  bool _loading = true;
  bool _syncing = false;
  List<OfflineOperation> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ops = await OfflineDataService().getPendingOperations();
    if (!mounted) return;
    setState(() {
      _items = ops.where((o) => o.status != SyncStatus.synced).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _loading = false;
    });
  }

  Future<void> _syncAll() async {
    if (_syncing || !mounted) return;
    setState(() => _syncing = true);
    final provider = context.read<SyncProvider>();
    try {
      await provider.syncAll();
      await _load();
      if (!mounted) return;
      final remaining = _items.length;
      final msg = provider.errorMessage ??
          (remaining == 0
              ? '同步完成'
              : '仍有 $remaining 条未同步，可点右侧菜单逐条重试');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              provider.errorMessage == null && remaining == 0
                  ? null
                  : Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _retry(OfflineOperation op) async {
    await OfflineDataService().resetOperationForRetry(op.id);
    if (!mounted) return;
    await _syncAll();
  }

  Future<void> _openConflicts() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ConflictResolutionPage()),
    );
    if (!mounted) return;
    await context.read<SyncProvider>().loadStatus();
    await _load();
  }

  Future<void> _delete(OfflineOperation op) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除这条草稿？'),
        content: Text('${(op.data['name'] ?? '').toString()}\n'
            '删除后无法恢复，人员数据不会受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await OfflineDataService().removeOperation(op.id);
    if (!mounted) return;
    await context.read<SyncProvider>().loadStatus();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('待同步数据'),
        actions: [
          IconButton(
            tooltip: '全部同步',
            icon: _syncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: _syncing ? null : _syncAll,
          ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_buildEmpty()],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length + 2,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) return _buildSummary();
                        if (index == _items.length + 1) return _buildFooter();
                        return _buildTile(_items[index - 1]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 140),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_done, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('没有待同步的数据'),
          const SizedBox(height: 8),
          Text(
            '断网时保存的人员改动会先放在这里',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// 顶部汇总：让村里一眼知道是"还在等网络"还是"需要人工处理"。
  Widget _buildSummary() {
    int pending = 0;
    int failed = 0;
    int conflict = 0;
    for (final op in _items) {
      if (op.status == SyncStatus.failed) {
        failed++;
      } else if (op.status == SyncStatus.conflict) {
        conflict++;
      } else {
        pending++; // 待同步 / 同步中
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _stat('待同步', pending, Colors.orange.shade800),
          _stat('失败', failed, Colors.red.shade700),
          _stat('冲突', conflict, Colors.purple.shade700),
        ],
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: value > 0 ? color : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        '网络恢复后会自动同步；失败项可点右侧菜单手动重试或删除。',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    );
  }

  Widget _buildTile(OfflineOperation op) {
    final isCreate = op.type == OperationType.create;
    final isStudent = op.entityType == 'student';
    final name = (op.data['name'] ?? '').toString().trim();
    final title = '${isCreate ? '新增' : '修改'}${isStudent ? '学生' : '人员'} · '
        '${name.isEmpty ? op.entityId : name}';
    final statusColor = _statusColor(op.status);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.12),
          child: Icon(
            isStudent
                ? Icons.school_outlined
                : (isCreate ? Icons.person_add : Icons.edit),
            color: statusColor,
          ),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('身份证 ${op.entityId}',
                style: const TextStyle(fontSize: 12)),
            Row(
              children: [
                Text(
                  '保存于 ${_formatTime(op.createdAt)}',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 6),
                Text(
                  _statusText(op.status),
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
              ],
            ),
            if ((op.conflictReason ?? '').isNotEmpty)
              Text(
                op.conflictReason!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            if (op.nextRetryAt != null &&
                op.status == SyncStatus.failed &&
                op.nextRetryAt!.isAfter(DateTime.now()))
              Text(
                '下次自动重试 ${_formatTime(op.nextRetryAt!)}',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'retry') {
              _retry(op);
            } else if (value == 'delete') {
              _delete(op);
            } else if (value == 'conflict') {
              _openConflicts();
            }
          },
          itemBuilder: (context) => [
            // 冲突项重试只会再次冲突，直接去冲突页选本地/服务器版本
            if (op.status == SyncStatus.conflict)
              const PopupMenuItem(value: 'conflict', child: Text('处理冲突'))
            else
              const PopupMenuItem(value: 'retry', child: Text('重试同步')),
            const PopupMenuItem(value: 'delete', child: Text('删除草稿')),
          ],
        ),
      ),
    );
  }

  String _statusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
        return '待同步';
      case SyncStatus.syncing:
        return '同步中';
      case SyncStatus.synced:
        return '已同步';
      case SyncStatus.conflict:
        return '有冲突';
      case SyncStatus.failed:
        return '同步失败';
    }
  }

  Color _statusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.pending:
      case SyncStatus.syncing:
        return Colors.orange.shade800;
      case SyncStatus.synced:
        return Colors.green.shade700;
      case SyncStatus.conflict:
      case SyncStatus.failed:
        return Colors.red.shade700;
    }
  }

  String _formatTime(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }
}
