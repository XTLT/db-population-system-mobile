
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/sync_provider.dart';

class SyncStatusIndicator extends StatelessWidget {
  final bool showDetails;

  const SyncStatusIndicator({
    super.key,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return GestureDetector(
          onTap: () => _showSyncDetails(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(syncProvider).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(syncProvider),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIcon(syncProvider),
                const SizedBox(width: 8),
                _buildStatusText(syncProvider),
                if (syncProvider.hasPendingOperations) ...[
                  const SizedBox(width: 8),
                  _buildBadge(
                    syncProvider.pendingCount.toString(),
                    Colors.orange,
                  ),
                ],
                if (syncProvider.hasConflicts) ...[
                  const SizedBox(width: 4),
                  _buildBadge(
                    syncProvider.conflictCount.toString(),
                    Colors.red,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(SyncProvider syncProvider) {
    if (syncProvider.isSyncing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(syncProvider)),
        ),
      );
    }

    return Icon(
      _getStatusIcon(syncProvider),
      size: 16,
      color: _getStatusColor(syncProvider),
    );
  }

  Widget _buildStatusText(SyncProvider syncProvider) {
    String text = _getStatusText(syncProvider);

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: _getStatusColor(syncProvider),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(SyncProvider syncProvider) {
    switch (syncProvider.state) {
      case SyncState.idle:
        if (syncProvider.hasConflicts) {
          return Colors.red;
        } else if (syncProvider.hasPendingOperations) {
          return Colors.orange;
        }
        return Colors.green;
      case SyncState.syncing:
        return Colors.blue;
      case SyncState.success:
        return Colors.green;
      case SyncState.error:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(SyncProvider syncProvider) {
    switch (syncProvider.state) {
      case SyncState.idle:
        if (syncProvider.hasConflicts) {
          return Icons.error_outline;
        } else if (syncProvider.hasPendingOperations) {
          return Icons.sync_problem;
        }
        return Icons.cloud_done;
      case SyncState.syncing:
        return Icons.sync;
      case SyncState.success:
        return Icons.check_circle;
      case SyncState.error:
        return Icons.error;
    }
  }

  String _getStatusText(SyncProvider syncProvider) {
    switch (syncProvider.state) {
      case SyncState.idle:
        if (syncProvider.hasConflicts) {
          return '有冲突';
        } else if (syncProvider.hasPendingOperations) {
          return '待同步';
        }
        return '已同步';
      case SyncState.syncing:
        return '同步中...';
      case SyncState.success:
        return '同步成功';
      case SyncState.error:
        return '同步失败';
    }
  }

  void _showSyncDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SyncDetailsSheet(),
    );
  }
}

class _SyncDetailsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '同步状态',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (!syncProvider.isSyncing)
                    TextButton.icon(
                      onPressed: () {
                        syncProvider.syncAll();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.sync),
                      label: const Text('立即同步'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoTile(
                icon: Icons.pending_actions,
                title: '待同步操作',
                value: syncProvider.pendingCount.toString(),
                color: Colors.orange,
              ),
              _buildInfoTile(
                icon: Icons.warning,
                title: '冲突数量',
                value: syncProvider.conflictCount.toString(),
                color: Colors.red,
              ),
              if (syncProvider.lastSyncTime != null)
                _buildInfoTile(
                  icon: Icons.access_time,
                  title: '最近同步',
                  value: _formatLastSyncTime(syncProvider.lastSyncTime!),
                  color: Colors.grey,
                ),
              if (syncProvider.hasConflicts)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/conflicts');
                    },
                    icon: const Icon(Icons.sync_problem),
                    label: const Text('解决冲突'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatLastSyncTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) {
        return '刚刚';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}分钟前';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}小时前';
      } else {
        return '${diff.inDays}天前';
      }
    } catch (e) {
      return '未知';
    }
  }
}
