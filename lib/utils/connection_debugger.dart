

library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ConnectionDebugger {
  
  static Future<Map<String, dynamic>> testConnection(String url) async {
    final results = <String, dynamic>{};
    
    debugPrint('============ 连接调试开始 ============');
    debugPrint('目标URL: $url');
    debugPrint('当前时间: ${DateTime.now()}');
    
    
    results['step1_basic'] = await _testBasicHttp(url);
    
    
    results['step2_health'] = await _testHealthEndpoint(url);
    
    
    results['step3_status'] = await _testStatusEndpoint(url);
    
    
    results['step4_login'] = await _testLoginEndpoint(url);
    
    debugPrint('============ 连接调试结束 ============');
    
    return results;
  }
  
  static Future<Map<String, dynamic>> _testBasicHttp(String url) async {
    debugPrint('\n[步骤1] 测试基础 HTTP 连接...');
    
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      
      final response = await dio.get(url);
      
      debugPrint('[步骤1] ✓ 成功');
      debugPrint('  状态码: ${response.statusCode}');
      debugPrint('  响应长度: ${response.data.toString().length}');
      
      return {
        'success': true,
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      debugPrint('[步骤1] ✗ 失败');
      debugPrint('  错误类型: ${e.type}');
      debugPrint('  错误消息: ${e.message}');
      debugPrint('  错误详情: ${e.error}');
      
      return {
        'success': false,
        'errorType': e.type.toString(),
        'errorMessage': e.message,
        'errorDetail': e.error?.toString(),
      };
    } catch (e) {
      debugPrint('[步骤1] ✗ 异常: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> _testHealthEndpoint(String url) async {
    debugPrint('\n[步骤2] 测试 /api/health...');
    
    try {
      final dio = Dio();
      final response = await dio.get('$url/api/health');
      
      debugPrint('[步骤2] ✓ 成功');
      debugPrint('  响应: ${response.data}');
      
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      debugPrint('[步骤2] ✗ 失败: ${e.type} - ${e.message}');
      return {
        'success': false,
        'errorType': e.type.toString(),
        'errorMessage': e.message,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _testStatusEndpoint(String url) async {
    debugPrint('\n[步骤3] 测试 /api/status...');
    
    try {
      final dio = Dio();
      final response = await dio.get('$url/api/status');
      
      debugPrint('[步骤3] ✓ 成功');
      debugPrint('  响应: ${response.data}');
      
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      debugPrint('[步骤3] ✗ 失败: ${e.type} - ${e.message}');
      return {
        'success': false,
        'errorType': e.type.toString(),
        'errorMessage': e.message,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _testLoginEndpoint(String url) async {
    debugPrint('\n[步骤4] 测试登录接口...');
    
    try {
      final dio = Dio();
      final response = await dio.get(
        '$url/api/health',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      
      debugPrint('[步骤4] ✓ 健康检查成功');
      
      return {
        'success': true,
        'healthy': response.data['healthy'] ?? response.data['status'] == 'ok',
      };
    } on DioException catch (e) {
      debugPrint('[步骤4] ✗ 失败: ${e.type} - ${e.message}');
      if (e.response != null) {
        debugPrint('  响应状态: ${e.response?.statusCode}');
        debugPrint('  响应数据: ${e.response?.data}');
      }
      
      return {
        'success': false,
        'errorType': e.type.toString(),
        'errorMessage': e.message,
        'statusCode': e.response?.statusCode,
        'responseData': e.response?.data,
      };
    }
  }
  
  
  static void printNetworkConfig(String url) {
    debugPrint('\n============ 网络配置信息 ============');
    debugPrint('API Base URL: $url');
    
    try {
      final uri = Uri.parse(url);
      debugPrint('协议: ${uri.scheme}');
      debugPrint('主机: ${uri.host}');
      debugPrint('端口: ${uri.port}');
      debugPrint('路径: ${uri.path}');
      debugPrint('是否HTTPS: ${uri.scheme == "https"}');
    } catch (e) {
      debugPrint('URL解析错误: $e');
    }
    
    debugPrint('======================================\n');
  }
}
