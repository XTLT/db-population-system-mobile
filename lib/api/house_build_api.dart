import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'api_client.dart';

/// 宅基地建房申请接口（列表/详情/增改删/身份证预填/导出）。
class HouseBuildApi {
  static final _dio = ApiClient().dio;

  static Never _rethrow(DioException e, String action) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    throw Exception('$action：${e.response?.statusCode ?? e.type.name}');
  }

  static Future<Map<String, dynamic>> list({
    String keyword = '',
    String status = '',
    String year = '',
    int page = 1,
    int pageSize = 200,
  }) async {
    try {
      final response = await _dio.get('/api/persons/house-build/list',
          queryParameters: {
            if (keyword.isNotEmpty) 'keyword': keyword,
            if (status.isNotEmpty) 'status': status,
            if (year.isNotEmpty) 'year': year,
            'page': page,
            'page_size': pageSize,
          });
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      _rethrow(e, '查询建房申请失败');
    }
  }

  static Future<Map<String, dynamic>> get(String appId) async {
    try {
      final response = await _dio.get('/api/persons/house-build/$appId');
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      _rethrow(e, '读取建房申请失败');
    }
  }

  static Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/persons/house-build', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      _rethrow(e, '保存建房申请失败');
    }
  }

  static Future<Map<String, dynamic>> update(
      String appId, Map<String, dynamic> data) async {
    try {
      final response =
          await _dio.put('/api/persons/house-build/$appId', data: data);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      _rethrow(e, '更新建房申请失败');
    }
  }

  static Future<void> delete(String appId) async {
    try {
      await _dio.delete('/api/persons/house-build/$appId');
    } on DioException catch (e) {
      _rethrow(e, '删除建房申请失败');
    }
  }

  static Future<Map<String, dynamic>> prefill(String idCard) async {
    try {
      final response = await _dio.get('/api/persons/house-build/prefill',
          queryParameters: {'id_card': idCard});
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      _rethrow(e, '从人口库带出失败');
    }
  }

  /// 下载导出文件到应用文档目录，返回本地绝对路径。
  static Future<String> download(String appId, String fmt) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/house_build');
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${outDir.path}/建房申请_${appId}_$stamp.$fmt';
    try {
      final response = await _dio.get(
        '/api/persons/house-build/$appId/export',
        queryParameters: {'fmt': fmt},
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data as List<int>;
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      return path;
    } on DioException catch (e) {
      _rethrow(e, '导出失败');
    }
  }
}
