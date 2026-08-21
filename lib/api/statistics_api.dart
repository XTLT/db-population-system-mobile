
import 'api_client.dart';

class StatisticsApi {
  static final _dio = ApiClient().dio;
  
  
  static Future<Map<String, dynamic>> getPersonStatistics() async {
    try {
      final response = await _dio.get('/api/statistics');
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取统计失败');
      }
    } catch (e) {
      throw Exception('获取统计失败: $e');
    }
  }
  
  
  static Future<Map<String, dynamic>> getStudentStatistics() async {
    try {
      final response = await _dio.get('/api/students/statistics');
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取学生统计失败');
      }
    } catch (e) {
      throw Exception('获取学生统计失败: $e');
    }
  }
  
  
  static Future<List<Map<String, dynamic>>> getAgeDistribution() async {
    try {
      final response = await _dio.get('/api/statistics/age_distribution');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['distribution'] ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
  
  
  static Future<List<Map<String, dynamic>>> getVillageStatistics() async {
    try {
      final response = await _dio.get('/api/statistics/by_village');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['villages'] ?? [];
        return data.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  
  static Future<Map<String, dynamic>> getTrendData({
    String? startDate,
    String? endDate,
    String groupBy = 'month',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'group_by': groupBy,
      };
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _dio.get('/api/statistics/trend', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取趋势数据失败');
      }
    } catch (e) {
      throw Exception('获取趋势数据失败: $e');
    }
  }

  
  static Future<Map<String, int>> getDistribution(String field) async {
    try {
      final response = await _dio.get('/api/statistics/distribution', queryParameters: {'field': field});

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        return data.map((key, value) => MapEntry(key, value as int));
      } else {
        throw Exception('获取分布数据失败');
      }
    } catch (e) {
      throw Exception('获取分布数据失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> getComparison({List<String>? dimensions}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dimensions != null && dimensions.isNotEmpty) {
        
        queryParams['dimensions'] = dimensions;
      }

      final response = await _dio.get('/api/statistics/comparison', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取对比数据失败');
      }
    } catch (e) {
      throw Exception('获取对比数据失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> getLandSubsidyStatistics({String? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (year != null) queryParams['year'] = year;

      final response = await _dio.get('/api/land_subsidy/statistics', queryParameters: queryParams);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('获取地力补贴统计失败');
      }
    } catch (e) {
      throw Exception('获取地力补贴统计失败: $e');
    }
  }
}
