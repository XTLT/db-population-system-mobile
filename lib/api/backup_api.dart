
import '../models/backup_info.dart';
import 'api_client.dart';

class BackupApi {
  static final _dio = ApiClient().dio;

  
  static Future<Map<String, dynamic>> createBackup() async {
    try {
      final response = await _dio.post('/api/backup');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('创建备份失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('创建备份失败: $e');
    }
  }

  
  static Future<List<BackupInfo>> getBackupList() async {
    try {
      final response = await _dio.get('/api/backup/list');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['backups'] ?? [];
        return data.map((json) => BackupInfo.fromJson(json)).toList();
      } else {
        throw Exception('获取备份列表失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取备份列表失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> restoreBackup(
    String backupPath, {
    String? password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/backup/restore',
        data: {
          'name': backupPath,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('恢复备份失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('恢复备份失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> getBackupStatus() async {
    try {
      final response = await _dio.get('/api/backup/status');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取备份状态失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取备份状态失败: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteBackup(String name) async {
    try {
      final response = await _dio.post(
        '/api/backup/delete',
        data: {'name': name},
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception(response.data['error'] ?? '删除备份失败');
      }
    } catch (e) {
      throw Exception('删除备份失败: $e');
    }
  }
}
