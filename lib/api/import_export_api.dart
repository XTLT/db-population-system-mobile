
library;

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';

class ImportExportApi {
  static final _dio = ApiClient().dio;

  
  
  
  
  
  static Future<Map<String, dynamic>> importPersonExcel(
    File file, {
    String mode = 'incremental',
    Function(int)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'mode': mode,
      });

      final response = await _dio.post(
        '/api/import/excel',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress((sent / total * 100).toInt());
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('导入失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? e.message ?? '未知错误';
      throw Exception('导入失败: $errorMsg');
    } catch (e) {
      throw Exception('导入失败: $e');
    }
  }

  
  
  
  
  static Future<String> exportPersonExcel({
    required String password,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await _dio.post(
        '/api/export/excel',
        data: {
          'password': password,
          if (filters != null) 'filters': filters,
        },
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${tempDir.path}/person_export_$timestamp.xlsx';

        final file = File(filePath);
        await file.writeAsBytes(response.data as List<int>);

        return filePath;
      } else {
        throw Exception('导出失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // responseType.bytes 下错误响应体是 Uint8List（属于 List<int>），
      // 需先 utf8.decode + jsonDecode 才能取出服务端 JSON 里的 error。
      final data = e.response?.data;
      String? errorMsg;
      if (data is List<int>) {
        try {
          final decoded =
              jsonDecode(utf8.decode(data)) as Map<String, dynamic>?;
          errorMsg = decoded?['error']?.toString();
        } catch (_) {
          errorMsg = null;
        }
      } else if (data is Map<String, dynamic>) {
        errorMsg = data['error']?.toString();
      }
      errorMsg ??= e.message ?? '未知错误';
      throw Exception('导出失败: $errorMsg');
    } catch (e) {
      throw Exception('导出失败: $e');
    }
  }

  
  
  
  static Future<String> exportStudentExcel({
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/students/export',
        data: {'password': password},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${tempDir.path}/student_export_$timestamp.xlsx';

        final file = File(filePath);
        await file.writeAsBytes(response.data as List<int>);

        return filePath;
      } else {
        throw Exception('导出失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      // responseType.bytes 下错误响应体是 Uint8List（属于 List<int>），
      // 需先 utf8.decode + jsonDecode 才能取出服务端 JSON 里的 error。
      final data = e.response?.data;
      String? errorMsg;
      if (data is List<int>) {
        try {
          final decoded =
              jsonDecode(utf8.decode(data)) as Map<String, dynamic>?;
          errorMsg = decoded?['error']?.toString();
        } catch (_) {
          errorMsg = null;
        }
      } else if (data is Map<String, dynamic>) {
        errorMsg = data['error']?.toString();
      }
      errorMsg ??= e.message ?? '未知错误';
      throw Exception('导出失败: $errorMsg');
    } catch (e) {
      throw Exception('导出失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> importStudentExcel(
    File file, {
    Function(int)? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });

      final response = await _dio.post(
        '/api/students/import',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress((sent / total * 100).toInt());
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('导入失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? e.message ?? '未知错误';
      throw Exception('导入失败: $errorMsg');
    } catch (e) {
      throw Exception('导入失败: $e');
    }
  }

  
  static Future<String> downloadPersonTemplate() async {
    try {
      final response = await _dio.get(
        '/api/template/excel',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/person_import_template.xlsx';

        final file = File(filePath);
        await file.writeAsBytes(response.data as List<int>);

        return filePath;
      } else {
        throw Exception('下载模板失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? e.message ?? '未知错误';
      throw Exception('下载模板失败: $errorMsg');
    } catch (e) {
      throw Exception('下载模板失败: $e');
    }
  }

  
  static Future<String> downloadStudentTemplate() async {
    try {
      final response = await _dio.get(
        '/api/template/student',
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/student_import_template.xlsx';

        final file = File(filePath);
        await file.writeAsBytes(response.data as List<int>);

        return filePath;
      } else {
        throw Exception('下载模板失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? e.message ?? '未知错误';
      throw Exception('下载模板失败: $errorMsg');
    } catch (e) {
      throw Exception('下载模板失败: $e');
    }
  }
}
