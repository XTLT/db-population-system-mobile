
import 'api_client.dart';
import '../models/operation_log.dart';

class OperationLogApi {
  static final _dio = ApiClient().dio;
  
  
  static Future<List<OperationLog>> getOperationLogs({
    int limit = 100,
    String? username,
    String? operationType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _dio.get('/api/logs', queryParameters: {
        'limit': limit,
        if (username != null && username.isNotEmpty) 'username': username,
        if (operationType != null && operationType.isNotEmpty) 'operation_type': operationType,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => OperationLog.fromJson(json)).toList();
      } else {
        throw Exception('获取操作日志失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取操作日志失败: $e');
    }
  }
  
  
  static Future<List<String>> getOperationTypes() async {
    try {
      final response = await _dio.get('/api/logs/types');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['types'] ?? [];
        return data.cast<String>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  
  static Future<Map<String, dynamic>> getOperationLogStats() async {
    try {
      final response = await _dio.get('/api/logs/stats');
      
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
