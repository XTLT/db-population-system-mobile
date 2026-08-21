
import 'package:dio/dio.dart';
import 'api_client.dart';

class BatchOperationApi {
  static final _dio = ApiClient().dio;

  
  static Future<Map<String, dynamic>> batchDeletePersons(List<String> ids) async {
    try {
      final response = await _dio.post('/api/persons/batch-delete', data: {'ids': ids});
      return response.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('批量删除失败: ${e.message}');
    } catch (e) {
      throw Exception('批量删除失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> batchUpdatePersons(
    List<String> ids,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _dio.post('/api/persons/batch-update', data: {
        'ids': ids,
        'updates': updates,
      });
      return response.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('批量更新失败: ${e.message}');
    } catch (e) {
      throw Exception('批量更新失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> batchDeleteStudents(List<String> ids) async {
    try {
      final response = await _dio.post('/api/students/batch-delete', data: {'ids': ids});
      return response.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('批量删除学生失败: ${e.message}');
    } catch (e) {
      throw Exception('批量删除学生失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> batchUpdateStudents(
    List<String> ids,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _dio.post('/api/students/batch-update', data: {
        'ids': ids,
        'updates': updates,
      });
      return response.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('批量更新学生失败: ${e.message}');
    } catch (e) {
      throw Exception('批量更新学生失败: $e');
    }
  }

  
  
  static Future<Map<String, dynamic>> batchDeletePhotos(List<Map<String, String>> photos) async {
    try {
      final response = await _dio.post('/api/photos/batch-delete', data: {'photos': photos});
      return response.data;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('批量删除照片失败: ${e.message}');
    } catch (e) {
      throw Exception('批量删除照片失败: $e');
    }
  }
}
