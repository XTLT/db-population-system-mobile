
import 'package:flutter/material.dart';
import '../../models/offline_operation.dart';

class ConflictItemWidget extends StatelessWidget {
  final Map<String, dynamic> conflict;
  final VoidCallback onUseLocal;
  final VoidCallback onUseServer;
  final VoidCallback onDismiss;

  const ConflictItemWidget({
    super.key,
    required this.conflict,
    required this.onUseLocal,
    required this.onUseServer,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final operation = OfflineOperation.fromJson(conflict['operation']);
    final serverData = conflict['server_data'] as Map<String, dynamic>;
    final detectedAt = DateTime.parse(conflict['detected_at']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                Icon(
                  _getOperationIcon(operation.type),
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getOperationTitle(operation),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDateTime(detectedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const Divider(),
            
            _buildInfoRow('实体类型', operation.entityType),
            _buildInfoRow('实体ID', operation.entityId),
            if (operation.conflictReason != null)
              _buildInfoRow('冲突原因', operation.conflictReason!),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onUseLocal,
                    icon: const Icon(Icons.phone_android),
                    label: const Text('使用本地'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onUseServer,
                    icon: const Icon(Icons.cloud),
                    label: const Text('使用服务器'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.schedule),
                label: const Text('稍后处理'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getOperationIcon(OperationType type) {
    switch (type) {
      case OperationType.create:
        return Icons.add_circle;
      case OperationType.update:
        return Icons.edit;
      case OperationType.delete:
        return Icons.delete;
      case OperationType.addPhoto:
        return Icons.add_photo_alternate;
      case OperationType.deletePhoto:
        return Icons.remove_circle;
    }
  }

  String _getOperationTitle(OfflineOperation operation) {
    final typeStr = _getOperationTypeString(operation.type);
    return '$typeStr - ${operation.entityType}';
  }

  String _getOperationTypeString(OperationType type) {
    switch (type) {
      case OperationType.create:
        return '创建';
      case OperationType.update:
        return '更新';
      case OperationType.delete:
        return '删除';
      case OperationType.addPhoto:
        return '添加照片';
      case OperationType.deletePhoto:
        return '删除照片';
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }
}
