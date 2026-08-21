

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../config/app_config.dart';

class SecureImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SecureImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<SecureImage> createState() => _SecureImageState();
}

class _SecureImageState extends State<SecureImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  String? _error;
  int _cacheBuster = 0;

  @override
  void initState() {
    super.initState();
    _cacheBuster = DateTime.now().millisecondsSinceEpoch;
    _loadImage();
  }

  @override
  void didUpdateWidget(SecureImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _cacheBuster = DateTime.now().millisecondsSinceEpoch;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = ApiClient().dio;
      final fullUrl = widget.url.startsWith('http')
          ? widget.url
          : '${AppConfig.apiBaseUrl}${widget.url}';

      final response = await dio.get<List<int>>(
        '$fullUrl?t=$_cacheBuster',
        options: Options(responseType: ResponseType.bytes),
      );

      if (!mounted) return;

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _imageData = Uint8List.fromList(response.data!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '加载失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  void refresh() {
    _cacheBuster = DateTime.now().millisecondsSinceEpoch;
    _loadImage();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    if (_error != null || _imageData == null) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 8),
                Text(_error ?? '加载失败',
                    style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          );
    }

    return Image.memory(
      _imageData!,
      fit: widget.fit,
    );
  }
}
