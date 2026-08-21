
import '../models/student.dart';
import 'api_client.dart';

class StudentApi {
  static final _dio = ApiClient().dio;
  
  
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
