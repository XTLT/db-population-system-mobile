import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/backup_provider.dart';
import '../../models/backup_info.dart';

class BackupManagementPage extends StatefulWidget {
  const BackupManagementPage({super.key});

  @override
  State<BackupManagementPage> createState() => _BackupManagementPageState();
}

class _BackupManagementPageState extends State<BackupManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackupProvider>().loadBackups();
      context.read<BackupProvider>().loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('备份管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<BackupProvider>().loadBackups();
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<BackupProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.backups.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败: ${provider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadBackups(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildStatusCard(provider),
              Expanded(
                child: provider.backups.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('暂无备份'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.backups.length,
                        itemBuilder: (context, index) {
                          return _buildBackupItem(provider.backups[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBackupDialog(),
        icon: const Icon(Icons.add),
        label: const Text('创建备份'),
      ),
    );
  }

  Widget _buildStatusCard(BackupProvider provider) {
    final status = provider.status;
    if (status == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最后备份时间',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  status['last_backup'] ?? '从未备份',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupItem(BackupInfo backup) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backup.encrypted ? Colors.orange.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            backup.encrypted ? Icons.lock : Icons.backup,
            color: backup.encrypted ? Colors.orange : Colors.blue,
          ),
        ),
        title: Text(
          backup.time,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.storage, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  backup.formattedSize,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 12),
                Icon(
                  backup.manual ? Icons.touch_app : Icons.schedule,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  backup.manual ? '手动备份' : '自动备份',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: false,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleBackupAction(value, backup),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: ListTile(
                leading: Icon(Icons.restore),
                title: Text('恢复'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBackupAction(String action, BackupInfo backup) {
    switch (action) {
      case 'restore':
        _showRestoreDialog(backup);
        break;
      case 'delete':
        _showDeleteDialog(backup);
        break;
    }
  }

  /// 执行耗时的备份操作（服务器端需复制数据库 + gzip 压缩全部照片 + 加密，3412 人数据可能耗时数秒到数十秒）。
  ///
  /// 修复要点：
  /// 1. 点击「确定」后立即弹出**模态进度对话框**（可见进度 + barrierDismissible:false 阻断页面跳转），
  ///    不再是“点击后干等、完成才弹提示”。
  /// 2. 进度框绑定本页面路由：一旦用户离开本页面（页面被销毁），后续结果 SnackBar 直接不再弹出，
  ///    避免根级 ScaffoldMessenger 在别的界面残留提示。
  Future<void> _runBackupTask({
    required String workingText,
    required Future<bool> Function() task,
    required String successText,
    required String failureText,
    String? Function()? failureDetail,
    Duration successDuration = const Duration(seconds: 4),
  }) async {
    // 立即弹出模态进度框，给出可见反馈并阻断用户在等待期间跳转走
    bool progressShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: SizedBox(
          width: 260,
          child: Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(workingText)),
            ],
          ),
        ),
      ),
    ).then((_) => progressShowing = false);

    // 执行网络/服务器耗时操作
    var success = false;
    try {
      success = await task();
    } catch (_) {
      success = false;
    }

    // 页面已被销毁（用户已离开备份管理）：不关闭、不弹任何残留提示
    if (!mounted) return;

    if (progressShowing) {
      Navigator.of(context).pop(); // 关闭进度框
    }

    // 仅在本页面仍可见时弹出结果提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            success ? successText : (failureDetail?.call() ?? failureText)),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: success ? successDuration : const Duration(seconds: 4),
      ),
    );
  }

  void _showCreateBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建备份'),
        content: const Text('确定要创建新的备份吗？\n\n备份将包含数据库和所有照片。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final backupProvider = context.read<BackupProvider>();
              Navigator.pop(context);
              await _runBackupTask(
                workingText: '正在创建备份，请稍候...',
                task: () => backupProvider.createBackup(),
                successText: '备份创建成功',
                failureText: '备份创建失败',
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BackupInfo backup) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复备份'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('备份时间: ${backup.time}'),
            const SizedBox(height: 8),
            Text('文件大小: ${backup.formattedSize}'),
            const SizedBox(height: 16),
            Text(
              '⚠️ 警告：恢复备份将覆盖当前数据，此操作不可逆！',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
            if (backup.encrypted) ...[
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: '解密密码',
                  border: OutlineInputBorder(),
                  helperText: '此备份已加密，需要密码才能恢复',
                ),
                obscureText: true,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordController.dispose();
              Navigator.pop(context);
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final backupProvider = context.read<BackupProvider>();
              final password =
                  backup.encrypted ? passwordController.text : null;
              Navigator.pop(context);
              passwordController.dispose();
              await _runBackupTask(
                workingText: '正在恢复备份，请稍候...',
                task: () =>
                    backupProvider.restoreBackup(backup.path, password: password),
                successText: '备份恢复成功，请重新登录',
                failureText: '备份恢复失败',
                successDuration: const Duration(seconds: 5),
              );
            },
            child: const Text('确定恢复'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BackupInfo backup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备份'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('备份时间: ${backup.time}'),
            const SizedBox(height: 8),
            Text('文件大小: ${backup.formattedSize}'),
            const SizedBox(height: 16),
            Text(
              '⚠️ 确定要删除此备份吗？删除后无法恢复！',
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final backupProvider = context.read<BackupProvider>();
              Navigator.pop(context);
              await _runBackupTask(
                workingText: '正在删除备份，请稍候...',
                task: () => backupProvider.deleteBackup(backup.path),
                successText: '备份已删除',
                failureText: '删除失败',
                failureDetail: () =>
                    backupProvider.errorMessage ?? '删除失败',
              );
            },
            child: const Text('确定删除'),
          ),
        ],
      ),
    );
  }
}
