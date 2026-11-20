import 'package:flutter/material.dart';

/// 面积类字段变更原因的通用对话框。
///
/// 土地面积、地方/国家公益林、非国有天然商品林四处规则完全一致，
/// 区别只有标题、文案与提示语，抽出来避免四份重复代码各自漂移。
Future<String?> showPersonChangeReasonDialog({
  required BuildContext context,
  required String title,
  required String label,
  required String oldValue,
  required String newValue,
  required String hint,
}) async {
  final reasonController = TextEditingController();
  try {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label已从 "$oldValue" 亩修改为 "$newValue" 亩',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              '请输入修改原因：',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('请输入修改原因')),
                );
                return;
              }
              Navigator.of(dialogContext).pop(reason);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  } finally {
    reasonController.dispose();
  }
}
