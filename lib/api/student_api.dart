
import 'package:dio/dio.dart';
import '../models/student.dart';
import 'api_client.dart';
import 'person_api.dart' show OfflineQueueException;

class StudentApi {
  static final _dio = ApiClient().dio;

  /// 与 PersonApi 同口径：网络层失败抛 [OfflineQueueException]，
  /// 页面据此把表单转入离线队列；服务端有响应则照常抛普通异常。
  static Object _mapWriteError(DioException e, String action) {
    final typeName = e.type.name;
    final isNetworkFailure = e.response == null &&
        typeName != 'badCertificate' &&
        typeName != 'cancel';
    if (isNetworkFailure) {
      return OfflineQueueException('网络不可用');
    }
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return Exception(data['error'].toString());
    }
    return Exception('$action：服务器返回 ${e.response?.statusCode ?? typeName}');
  }
  
  
  static Future<List<Student>> searchStudents(String name) async {
    try {
      final response = await _dio.get('/api/students/search', queryParameters: {
        'name': name,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? [];
        return data.map((json) => Student.fromJson(json)).toList();
      } else {
        throw Exception('查询失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('查询失败: $e');
    }
  }
  
  
  static Future<List<Student>> getAllStudents({int? limit, int? offset}) async {
    try {
      final response = await _dio.get('/api/students', queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['students'] ?? [];
        return data.map((json) => Student.fromJson(json)).toList();
      } else {
        throw Exception('获取学生列表失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取学生列表失败: $e');
    }
  }
  
  
  static Future<bool> updateStudent(String idCard, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/api/student/$idCard', data: data);
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      throw _mapWriteError(e, '更新失败');
    } catch (e) {
      throw Exception('更新失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> getStudent(String idCard) async {
    try {
      final response = await _dio.get('/api/student/$idCard');

      if (response.statusCode == 200) {
        return response.data['student'];
      } else {
        throw Exception('获取学生信息失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取学生信息失败: $e');
    }
  }

  
  static Future<bool> addStudent(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/student', data: data);
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      throw _mapWriteError(e, '添加失败');
    } catch (e) {
      throw Exception('添加失败: $e');
    }
  }

  
  static Future<bool> deleteStudent(String idCard) async {
    try {
      final response = await _dio.delete('/api/student/$idCard');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw Exception('删除失败: $e');
    }
  }
  
  
  static Future<Map<String, dynamic>> getStudentStatistics() async {
    try {
      final response = await _dio.get('/api/students/statistics');
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取统计失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取统计失败: $e');
    }
  }
}
