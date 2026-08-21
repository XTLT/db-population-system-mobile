
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/offline_operation.dart';
import '../../services/offline_data_service.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/conflict_item_widget.dart';

class ConflictResolutionPage extends StatefulWidget {
  const ConflictResolutionPage({super.key});

  @override
  State<ConflictResolutionPage> createState() => _ConflictResolutionPageState();
}

class _ConflictResolutionPageState extends State<ConflictResolutionPage> {
  List<Map<String, dynamic>> _conflicts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConflicts();
  }

  Future<void> _loadConflicts() async {
    setState(() {
      _isLoading = true;
    });

    final conflicts = await OfflineDataService().getConflicts();

    setState(() {
      _conflicts = conflicts;
      _isLoading = false;
    });
  }

  Future<void> _resolveConflict(String operationId, String resolution) async {
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);

    await syncProvider.resolveConflict(operationId, resolution);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          resolution == 'use_local'
              ? '已选择使用本地版本'
              : '已选择使用服务器版本',
        ),
      ),
    );

    await _loadConflicts();

    
    if (_conflicts.isEmpty && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _dismissConflict(String operationId) async {
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已跳过此冲突')),
    );

    await _loadConflicts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('解决冲突'),
        actions: [
          if (_conflicts.isNotEmpty)
            TextButton.icon(
              onPressed: _showHelp,
              icon: const Icon(Icons.help_outline, color: Colors.white),
              label: const Text(
                '帮助',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conflicts.isEmpty
              ? _buildEmptyState()
              : _buildConflictList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green[300],
          ),
          const SizedBox(height: 16),
          const Text(
            '没有冲突需要解决',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            '所有数据已同步',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictList() {
    return Column(
      children: [
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.orange[50],
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '发现 ${_conflicts.length} 个冲突需要解决',
                  style: TextStyle(color: Colors.orange[900]),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadConflicts,
            child: ListView.builder(
              itemCount: _conflicts.length,
              itemBuilder: (context, index) {
                final conflict = _conflicts[index];
                final operation =
                    OfflineOperation.fromJson(conflict['operation']);

                return ConflictItemWidget(
                  conflict: conflict,
                  onUseLocal: () {
                    _resolveConflict(operation.id, 'use_local');
                  },
                  onUseServer: () {
                    _resolveConflict(operation.id, 'use_server');
                  },
                  onDismiss: () {
                    _dismissConflict(operation.id);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('如何解决冲突?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.phone_android, color: Colors.blue),
              title: Text('使用本地版本'),
              subtitle: Text('保留您在离线时的修改，覆盖服务器上的数据'),
            ),
            ListTile(
              leading: Icon(Icons.cloud, color: Colors.green),
              title: Text('使用服务器版本'),
              subtitle: Text('放弃您的本地修改，使用服务器上的最新数据'),
            ),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('稍后处理'),
              subtitle: Text('暂时跳过此冲突，稍后再决定'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
