import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../api/backup_api.dart';
import '../../api/import_export_api.dart';
import '../../models/backup_info.dart';

/// 数据管理页：人员/学生 Excel 导入导出、模板下载、备份管理入口。
///
/// 由设置页 `Navigator.push` 打开，构造器可 const、无必填参数。
/// 不引入新插件：文件选择复用已依赖的 file_picker。
class DataManagementPage extends StatefulWidget {
  const DataManagementPage({super.key});

  @override
  State<DataManagementPage> createState() => _DataManagementPageState();
}

class _DataManagementPageState extends State<DataManagementPage> {
  bool _busy = false;
  List<BackupInfo> _backups = [];
  bool _backupsLoading = true;
  String? _backupsError;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  // ---------------------------------------------------------------- backups
  Future<void> _loadBackups() async {
    setState(() {
      _backupsLoading = true;
      _backupsError = null;
    });
    try {
      final list = await BackupApi.getBackupList();
      if (!mounted) return;
      setState(() {
        _backups = list;
        _backupsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupsError = e.toString();
        _backupsLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    messenger.showSnackBar(const SnackBar(content: Text('正在创建备份...')));
    try {
      await BackupApi.createBackup();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('备份创建成功'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('备份创建失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- import
  Future<void> _pickAndImport({required bool isStudent}) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xls', 'xlsx'],
    );
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;

    setState(() => _busy = true);
    messenger.showSnackBar(SnackBar(content: Text('正在导入 ${isStudent ? '学生' : '人员'} Excel...')));
    try {
      final Map<String, dynamic> resp = isStudent
          ? await ImportExportApi.importStudentExcel(File(path))
          : await ImportExportApi.importPersonExcel(File(path));
      if (!mounted) return;
      final created = resp['created'] ?? resp['success'] ?? resp['imported'] ?? '';
      final failed = resp['failed'] ?? '';
      messenger.showSnackBar(
        SnackBar(
          content: Text('导入完成：成功 $created，失败 $failed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('导入失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- export
  Future<void> _showExportDialog({required bool isPerson}) async {
    final passwordController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isPerson ? '导出人员 Excel' : '导出学生 Excel'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '请输入导出密码',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('导出'),
          ),
        ],
      ),
    );
    if (ok != true) {
      passwordController.dispose();
      return;
    }
    final password = passwordController.text.trim();
    passwordController.dispose();

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    messenger.showSnackBar(const SnackBar(content: Text('正在导出...')));
    try {
      final String filePath = isPerson
          ? await ImportExportApi.exportPersonExcel(password: password)
          : await ImportExportApi.exportStudentExcel(password: password);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('导出成功，已保存到: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- template
  Future<void> _downloadTemplate({required bool isPerson}) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    messenger.showSnackBar(const SnackBar(content: Text('正在下载模板...')));
    try {
      final String filePath = isPerson
          ? await ImportExportApi.downloadPersonTemplate()
          : await ImportExportApi.downloadStudentTemplate();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('模板已下载: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('下载模板失败: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------- build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Excel 导入'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    icon: Icons.person_add,
                    color: Colors.blue,
                    label: '导入人员',
                    onTap: _busy ? null : () => _pickAndImport(isStudent: false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(
                    icon: Icons.school,
                    color: Colors.purple,
                    label: '导入学生',
                    onTap: _busy ? null : () => _pickAndImport(isStudent: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('Excel 导出'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    icon: Icons.download,
                    color: Colors.green,
                    label: '导出人员',
                    onTap: _busy ? null : () => _showExportDialog(isPerson: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(
                    icon: Icons.download,
                    color: Colors.teal,
                    label: '导出学生',
                    onTap: _busy ? null : () => _showExportDialog(isPerson: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('导入模板'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    icon: Icons.table_chart,
                    color: Colors.orange,
                    label: '人员模板',
                    onTap: _busy ? null : () => _downloadTemplate(isPerson: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(
                    icon: Icons.table_chart,
                    color: Colors.deepOrange,
                    label: '学生模板',
                    onTap: _busy ? null : () => _downloadTemplate(isPerson: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('备份管理'),
            const SizedBox(height: 8),
            _buildBackupSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _createBackup,
        icon: const Icon(Icons.backup),
        label: const Text('新建备份'),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );

  Widget _actionCard({
    required IconData icon,
    required Color color,
    required String label,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    if (_backupsLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_backupsError != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text('备份列表加载失败: $_backupsError',
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _loadBackups, child: const Text('重试')),
            ],
          ),
        ),
      );
    }
    if (_backups.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('暂无备份，点击右下角"新建备份"创建')),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final b in _backups)
            ListTile(
              leading: Icon(
                b.encrypted ? Icons.lock : Icons.storage,
                color: b.encrypted ? Colors.orange : Colors.blue,
              ),
              title: Text(b.time.isEmpty ? b.timestamp : b.time),
              subtitle: Text(
                '${b.formattedSize} · ${b.manual ? '手动' : '自动'}${b.encrypted ? ' · 已加密' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }
}
