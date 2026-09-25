import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      final updateInfo = await UpdateService().checkUpdate();
      if (updateInfo != null && updateInfo.hasUpdate && context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(updateInfo: updateInfo),
        );
      }
    } catch (e) {
      debugPrint('检查更新失败: $e');
    }
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel('dialog_disposed');
    super.dispose();
  }

  String get _fileSizeText {
    if (widget.updateInfo.fileSize <= 0) return '';
    return UpdateService.formatFileSize(widget.updateInfo.fileSize);
  }

  String get _progressText {
    if (!_downloading) return '下载更新';
    return '${(_progress * 100).toStringAsFixed(0)}%';
  }

  Future<void> _startDownload() async {
    if (widget.updateInfo.downloadUrl == null || widget.updateInfo.downloadUrl!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载链接不可用，请手动下载安装')),
        );
      }
      return;
    }

    setState(() {
      _downloading = true;
      _progress = 0;
    });

    _cancelToken = CancelToken();
    final success = await UpdateService().downloadAndInstall(
      widget.updateInfo,
      cancelToken: _cancelToken,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
      } else {
        setState(() => _downloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('下载或安装失败，请手动下载安装'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          const Text('发现新版本'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'v${widget.updateInfo.latestVersion}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_fileSizeText.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text(
                    _fileSizeText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '更新内容：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.updateInfo.releaseNotes.isEmpty
                  ? '无更新说明'
                  : widget.updateInfo.releaseNotes,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 4),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_downloading)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('稍后再说'),
          ),
        ElevatedButton(
          onPressed: _downloading ? null : _startDownload,
          child: Text(_progressText),
        ),
      ],
    );
  }
}
