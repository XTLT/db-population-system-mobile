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
    }
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
              Navigator.pop(context);

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('正在创建备份...')),
              );

              final success = await context.read<BackupProvider>().createBackup();

              if (mounted) {
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('备份创建成功'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('备份创建失败'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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
              Navigator.pop(context);

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('正在恢复备份...')),
              );

              final success = await context.read<BackupProvider>().restoreBackup(
                    backup.path,
                    password: backup.encrypted ? passwordController.text : null,
                  );

              passwordController.dispose();

              if (mounted) {
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('备份恢复成功，请重新登录'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 5),
                    ),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('备份恢复失败'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('确定恢复'),
          ),
        ],
      ),
    );
  }
}
