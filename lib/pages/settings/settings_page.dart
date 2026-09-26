import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';
import '../../services/domain_service.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'app_settings_page.dart';
import '../logs/operation_log_list_page.dart';
import '../backup/backup_management_page.dart';
import '../data/data_management_page.dart';
import '../user/user_management_page.dart';
import '../notification/send_notification_page.dart';
import '../../widgets/update_dialog.dart';
import '../../services/update_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _urlController = TextEditingController();
  final _backupUrlController = TextEditingController();
  bool _isTesting = false;
  Map<String, dynamic>? _testResult;
  List<Map<String, dynamic>> _allDomainResults = [];
  
  @override
  void initState() {
    super.initState();
    _urlController.text = AppConfig.apiBaseUrl;
    _loadBackupUrls();
  }
  
  void _loadBackupUrls() {
    setState(() {
      _backupUrlController.text = AppConfig.backupUrls.join('\n');
    });
  }
  
  @override
  void dispose() {
    _urlController.dispose();
    _backupUrlController.dispose();
    super.dispose();
  }
  
  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    
    final result = await DomainService.testCurrentDomain();
    
    setState(() {
      _isTesting = false;
      _testResult = result;
    });
  }
  
  Future<void> _testAllDomains() async {
    setState(() {
      _isTesting = true;
      _allDomainResults = [];
    });
    
    final results = await DomainService.checkAllDomains();
    
    setState(() {
      _isTesting = false;
      _allDomainResults = results;
    });
    
    if (mounted) {
      _showDomainResultsDialog();
    }
  }
  
  void _showDomainResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('域名检测结果'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _allDomainResults.length,
            itemBuilder: (context, index) {
              final result = _allDomainResults[index];
              final isAvailable = result['available'] == true;
              
              return ListTile(
                leading: Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                title: Text(
                  result['url'],
                  style: const TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  isAvailable 
                      ? '响应时间: ${result['response_time']}ms'
                      : '连接失败',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateDomain() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('域名不能为空')),
      );
      return;
    }
    
    
    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('域名格式错误，必须以 http:// 或 https:// 开头')),
      );
      return;
    }
    
    await AppConfig.updateBaseUrl(newUrl);
    ApiClient().resetEffectiveBaseUrl();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('域名已更新')),
      );
    }
  }
  
  Future<void> _updateBackupUrls() async {
    final urls = _backupUrlController.text
        .split('\n')
        .map((url) => AppConfig.normalizeUrl(url))
        .where((url) => url.isNotEmpty)
        .toList();
    
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('backup_urls', urls);
    
    
    AppConfig.backupUrls = urls;
    _backupUrlController.text = urls.join('\n');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已更新 ${urls.length} 个备用域名')),
      );
    }
  }
  
  Future<void> _resetToDefault() async {
    await AppConfig.resetToDefault();
    ApiClient().resetEffectiveBaseUrl();
    _urlController.text = AppConfig.apiBaseUrl;
    _loadBackupUrls();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已恢复默认域名')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            _buildSection(
              'API 域名配置',
              [
                const Text(
                  '当前域名',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'https://api.yourdomain.com',
                    helperText: '示例: https://api.yourdomain.com 或 https://192.168.1.100:5000',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check),
                      label: const Text('测试连接'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _updateDomain,
                      icon: const Icon(Icons.save),
                      label: const Text('保存'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _resetToDefault,
                      child: const Text('恢复默认'),
                    ),
                  ],
                ),
                if (_testResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _testResult!['available'] == true
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _testResult!['available'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _testResult!['available'] == true
                                  ? Icons.check_circle
                                  : Icons.error,
                              color: _testResult!['available'] == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _testResult!['available'] == true 
                                  ? '连接成功' 
                                  : '连接失败',
                              style: TextStyle(
                                color: _testResult!['available'] == true
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (_testResult!['response_time'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '响应时间: ${_testResult!['response_time']}ms',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        if (_testResult!['fallback'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _testResult!['fallback'] == 'IPv6 链路本地'
                                  ? '通过 IPv6 链路本地地址连接成功（同局域网）'
                                  : _testResult!['fallback'] == 'IPv4'
                                    ? '通过 IPv4 回退连接成功'
                                    : '通过备用地址连接成功',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        if (_testResult!['error'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '错误: ${_testResult!['error']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            
            _buildSection(
              '备用域名',
              [
                const Text(
                  '备用域名列表（每行一个）',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _backupUrlController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'https://api-backup.yourdomain.com\nhttps://192.168.1.100:5000',
                    helperText: '每行一个域名，当主域名不可用时会自动切换',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _testAllDomains,
                      icon: const Icon(Icons.checklist),
                      label: const Text('测试所有域名'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _updateBackupUrls,
                      icon: const Icon(Icons.save),
                      label: const Text('保存备用域名'),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            
            _buildSection(
              '应用设置',
              [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.settings_applications),
                    title: const Text('应用管理'),
                    subtitle: const Text('缓存管理、数据同步'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppSettingsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            
            _buildSection(
              '审计功能',
              [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history, color: Colors.orange),
                    title: const Text('操作日志'),
                    subtitle: const Text('查看系统操作记录'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OperationLogListPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            
            _buildSection(
              '数据管理',
              [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.backup, color: Colors.orange),
                    title: const Text('备份管理'),
                    subtitle: const Text('创建、查看、恢复备份'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BackupManagementPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.table_chart, color: Colors.green),
                    title: const Text('数据导入导出'),
                    subtitle: const Text('Excel 批量导入导出'),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DataManagementPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                if (!auth.isAdmin) return const SizedBox.shrink();
                
                return _buildSection(
                  '系统管理',
                  [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.people, color: Colors.purple),
                        title: const Text('用户管理'),
                        subtitle: const Text('管理用户账号和权限'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserManagementPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.send, color: Colors.blue),
                        title: const Text('发送通知'),
                        subtitle: const Text('向用户发送系统通知'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SendNotificationPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.cloud_sync, color: Colors.teal),
                        title: const Text('服务器代码更新'),
                        subtitle: const Text('从Gitee拉取最新代码并重启服务器'),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () => _showServerUpdateDialog(context),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            
            
            _buildSection(
              '关于',
              [
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('应用名称'),
                  subtitle: Text(AppConfig.appName),
                ),
                ListTile(
                  leading: const Icon(Icons.verified),
                  title: const Text('版本'),
                  subtitle: Text(AppConfig.appVersion),
                ),
                ListTile(
                  leading: const Icon(Icons.system_update),
                  title: const Text('检查更新'),
                  subtitle: const Text('检查是否有新版本可用'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final updateInfo = await UpdateService().checkUpdate();
                    if (!mounted) return;
                    if (updateInfo != null && updateInfo.hasUpdate) {
                      showDialog(
                        context: context,
                        builder: (_) => UpdateDialog(updateInfo: updateInfo),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('当前已是最新版本')),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  void _showServerUpdateDialog(BuildContext context) {
    String statusText = '准备更新...';
    bool isRunning = true;
    ServerUpdateResult? result;
    void Function(void Function())? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            dialogSetState = setState;
            return AlertDialog(
              title: const Text('服务器代码更新'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRunning) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(statusText),
                  ] else ...[
                    Icon(
                      result!.success ? Icons.check_circle : Icons.error,
                      color: result!.success ? Colors.green : Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(result!.success
                        ? (result!.oldCommit == result!.newCommit
                            ? '已是最新版本!'
                            : '更新成功!')
                        : '更新失败'),
                    const SizedBox(height: 8),
                    if (result!.oldCommit != null)
                      Text('旧版本: ${result!.oldCommit}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (result!.newCommit != null)
                      Text('新版本: ${result!.newCommit}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (result!.error != null)
                      Text(result!.error!,
                          style: const TextStyle(fontSize: 12, color: Colors.red)),
                    if (result!.deployLog != null &&
                        result!.deployLog!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('更新日志:',
                          style:
                              TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        child: SingleChildScrollView(
                          child: Text(
                            result!.deployLog!,
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              actions: [
                if (!isRunning)
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('关闭'),
                  ),
              ],
            );
          },
        );
      },
    );

    UpdateService().updateServer(
      onStatus: (msg) {
        statusText = msg;
        dialogSetState?.call(() {});
      },
    ).then((r) {
      result = r;
      isRunning = false;
      dialogSetState?.call(() {});
    });
  }
}
