
import 'package:dio/dio.dart';
import '../models/custom_report.dart';
import 'api_client.dart';

class CustomReportApi {
  static final _dio = ApiClient().dio;
  
  
  static Future<CustomReport> createReport({
    required String title,
    required String reportType,
    List<String> dimensions = const [],
    Map<String, String> dateRange = const {},
    String chartType = 'bar',
    Map<String, dynamic> filters = const {},
  }) async {
    try {
      final response = await _dio.post('/api/reports/custom', data: {
        'title': title,
        'report_type': reportType,
        'dimensions': dimensions,
        'date_range': dateRange,
        'chart_type': chartType,
        'filters': filters,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CustomReport.fromJson(response.data['report']);
      } else {
        throw Exception('创建报表失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('网络错误，请检查网络连接');
    } catch (e) {
      throw Exception('创建报表失败: $e');
    }
  }
  
  
  static Future<List<CustomReport>> getReports({
    String? reportType,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get('/api/reports/custom', queryParameters: {
        if (reportType != null && reportType.isNotEmpty) 'report_type': reportType,
        'limit': limit,
      });
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['reports'] ?? [];
        return data.map((json) => CustomReport.fromJson(json)).toList();
      } else {
        throw Exception('获取报表列表失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('网络错误，请检查网络连接');
    } catch (e) {
      throw Exception('获取报表列表失败: $e');
    }
  }
  
  
  static Future<CustomReport> getReport(String reportId) async {
    try {
      final response = await _dio.get('/api/reports/custom/$reportId');
      
      if (response.statusCode == 200) {
        return CustomReport.fromJson(response.data['report']);
      } else {
        throw Exception('获取报表详情失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('网络错误，请检查网络连接');
    } catch (e) {
      throw Exception('获取报表详情失败: $e');
    }
  }
  
  
  static Future<CustomReport> updateReport(
    String reportId, {
    String? title,
    String? reportType,
    List<String>? dimensions,
    Map<String, String>? dateRange,
    String? chartType,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (reportType != null) data['report_type'] = reportType;
      if (dimensions != null) data['dimensions'] = dimensions;
      if (dateRange != null) data['date_range'] = dateRange;
      if (chartType != null) data['chart_type'] = chartType;
      if (filters != null) data['filters'] = filters;
      
      final response = await _dio.put('/api/reports/custom/$reportId', data: data);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        return CustomReport.fromJson(response.data['report']);
      } else {
        throw Exception('更新报表失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('网络错误，请检查网络连接');
    } catch (e) {
      throw Exception('更新报表失败: $e');
    }
  }
  
  
  static Future<bool> deleteReport(String reportId) async {
    try {
      final response = await _dio.delete('/api/reports/custom/$reportId');
      return response.statusCode == 200 && response.data['success'] == true;
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('网络错误，请检查网络连接');
    } catch (e) {
      throw Exception('删除报表失败: $e');
    }
  }
  
  
  static Future<Map<String, dynamic>> generateReport({
    required String reportType,
    required List<String> dimensions,
    Map<String, String> dateRange = const {},
    Map<String, dynamic> filters = const {},
  }) async {
    try {
      final response = await _dio.post('/api/reports/generate', data: {
        'report_type': reportType,
        'dimensions': dimensions,
        'date_range': dateRange,
        'filters': filters,
      });
      
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('生成报表失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('网络错误，请检查网络连接');
    } catch (e) {
      throw Exception('生成报表失败: $e');
    }
  }
}
