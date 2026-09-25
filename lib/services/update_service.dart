import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../api/api_client.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final int latestCode;
  final String releaseNotes;
  final String? downloadUrl;
  final int fileSize;
  final String? checksum;
  final bool isExternalUrl;

  UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.latestCode,
    required this.releaseNotes,
    this.downloadUrl,
    this.fileSize = 0,
    this.checksum,
    this.isExternalUrl = false,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      hasUpdate: json['has_update'] ?? false,
      latestVersion: json['latest_version'] ?? '',
      latestCode: json['latest_code'] ?? 0,
      releaseNotes: json['release_notes'] ?? '',
      downloadUrl: json['download_url'],
      fileSize: json['file_size'] ?? 0,
      checksum: json['checksum'],
      isExternalUrl: json['is_external_url'] ?? false,
    );
  }
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  final Dio _dio = ApiClient().dio;

  Future<UpdateInfo?> checkUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await _dio.get(
        '/api/update/check',
        queryParameters: {
          'type': 'mobile',
          'version_code': currentCode,
        },
      );

      if (response.statusCode == 200) {
        return UpdateInfo.fromJson(response.data);
      }
    } catch (e) {
      debugPrint('检查更新失败: $e');
    }
    return null;
  }

  Future<bool> downloadAndInstall(
    UpdateInfo updateInfo, {
    Function(double)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (updateInfo.downloadUrl == null || updateInfo.downloadUrl!.isEmpty) {
      return false;
    }

    try {
      final status = await Permission.storage.request();
      if (!status.isGranted && !status.isLimited) {
        final installStatus = await Permission.requestInstallPackages.request();
        if (!installStatus.isGranted) return false;
      }

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/population-query-${updateInfo.latestVersion}.apk';

      String downloadUrl = updateInfo.downloadUrl!;
      
      // 如果是相对路径，拼接baseUrl
      if (!downloadUrl.startsWith('http')) {
        final baseUrl = _dio.options.baseUrl;
        downloadUrl = '$baseUrl$downloadUrl';
      }

      final downloadDio = Dio(BaseOptions(
        followRedirects: true,
        maxRedirects: 10,
        receiveTimeout: const Duration(minutes: 30),
        headers: {'User-Agent': 'PopulationApp/1.0'},
      ));

      await downloadDio.download(
        downloadUrl,
        filePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      return await _installApk(filePath);
    } catch (e) {
      debugPrint('下载更新失败: $e');
      return false;
    }
  }

  Future<bool> _installApk(String filePath) async {
    try {
      if (!Platform.isAndroid) return false;

      final channel = MethodChannel('com.population/install_apk');
      final result = await channel.invokeMethod<bool>('installApk', {'path': filePath});
      return result ?? false;
    } catch (e) {
      debugPrint('安装APK失败: $e');
      return false;
    }
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class ServerUpdateResult {
  final bool success;
  final String? oldCommit;
  final String? newCommit;
  final String? error;
  final String? deployLog;

  ServerUpdateResult({
    required this.success,
    this.oldCommit,
    this.newCommit,
    this.error,
    this.deployLog,
  });
}

extension ServerUpdate on UpdateService {
  Future<ServerUpdateResult> updateServer({
    Function(String)? onStatus,
  }) async {
    String? oldCommit;
    String effectiveUrl = ApiClient().dio.options.baseUrl;
    try {
      onStatus?.call('正在发送更新指令...');
      final response = await ApiClient().dio.post('/api/update/server');
      if (response.statusCode != 200) {
        return ServerUpdateResult(
          success: false,
          error: response.data['error'] ?? '请求失败',
        );
      }
      oldCommit = response.data['old_commit'];
      // 捕获 POST 请求实际使用的 URL（ApiClient 拦截器可能通过 IPv4/IPv6/备用域名回退）
      if (response.requestOptions.baseUrl.isNotEmpty) {
        effectiveUrl = response.requestOptions.baseUrl;
      }
      onStatus?.call('服务器正在拉取代码 (旧版本: $oldCommit)...');
    } catch (e) {
      return ServerUpdateResult(success: false, error: '发送更新指令失败: $e');
    }

    // 轮询健康检查，等待 gunicorn 重启完成
    onStatus?.call('等待服务器重启...');
    final healthDio = Dio(BaseOptions(
      baseUrl: effectiveUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    healthDio.httpClientAdapter = IOHttpClientAdapter(
      onHttpClientCreate: (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );

    const maxAttempts = 20;
    const interval = Duration(seconds: 3);
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);
      try {
        final resp = await healthDio.get('/api/health');
        if (resp.statusCode == 200 && resp.data['healthy'] == true) {
          onStatus?.call('服务器已重启，正在获取更新结果...');
          try {
            final statusResp = await ApiClient().dio.get('/api/update/server_status');
            if (statusResp.statusCode == 200) {
              return ServerUpdateResult(
                success: true,
                oldCommit: oldCommit,
                newCommit: statusResp.data['current_commit'],
                deployLog: statusResp.data['deploy_log'],
              );
            }
          } catch (_) {}
          return ServerUpdateResult(success: true, oldCommit: oldCommit);
        }
      } catch (_) {}
      onStatus?.call('等待服务器重启... (${i + 1}/$maxAttempts)');
    }

    return ServerUpdateResult(
      success: false,
      error: '更新超时，服务器可能仍在重启中，请稍后手动检查',
      oldCommit: oldCommit,
    );
  }
}
