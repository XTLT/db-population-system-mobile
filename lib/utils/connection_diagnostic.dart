import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ConnectionDiagnostic {
  static Future<Map<String, dynamic>> runFullDiagnostic(String serverUrl) async {
    final results = <String, dynamic>{};
    
    
    results['basic_connectivity'] = await _testBasicConnectivity(serverUrl);
    
    
    results['health_endpoint'] = await _testHealthEndpoint(serverUrl);
    
    
    results['status_endpoint'] = await _testStatusEndpoint(serverUrl);
    
    
    results['login_endpoint'] = await _testLoginEndpoint(serverUrl);
    
    return results;
  }
  
  static Future<Map<String, dynamic>> _testBasicConnectivity(String url) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      final response = await dio.get(url);
      return {'success': true, 'status': response.statusCode};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.type.toString(),
        'message': _getDioErrorMessage(e),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> _testHealthEndpoint(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get('$url/api/health');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.type.toString(),
        'message': _getDioErrorMessage(e),
        'statusCode': e.response?.statusCode,
      };
    }
  }
  
  static Future<Map<String, dynamic>> _testStatusEndpoint(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get('$url/api/status');
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.type.toString(),
        'message': _getDioErrorMessage(e),
      };
    }
  }
  
  static Future<Map<String, dynamic>> _testLoginEndpoint(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '$url/api/health',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.type.toString(),
        'message': _getDioErrorMessage(e),
        'statusCode': e.response?.statusCode,
        'responseData': e.response?.data,
      };
    }
  }
  
  static String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.sendTimeout:
        return '发送超时';
      case DioExceptionType.receiveTimeout:
        return '接收超时';
      case DioExceptionType.connectionError:
        return '无法连接到服务器';
      case DioExceptionType.badResponse:
        return '服务器返回错误: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return '请求已取消';
      default:
        return '未知错误: ${e.message}';
    }
  }
  
  static void showDiagnosticResults(BuildContext context, Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接诊断结果'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResultItem('基础连通性', results['basic_connectivity']),
              const Divider(),
              _buildResultItem('/api/health', results['health_endpoint']),
              const Divider(),
              _buildResultItem('/api/status', results['status_endpoint']),
              const Divider(),
              _buildResultItem('登录接口', results['login_endpoint']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildResultItem(String title, Map<String, dynamic>? result) {
    if (result == null) return Text('$title: 未测试');
    
    final success = result['success'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title: ${success ? "✓ 成功" : "✗ 失败"}',
          style: TextStyle(
            color: success ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (!success && result['message'] != null)
          Text('错误: ${result['message']}', style: const TextStyle(fontSize: 12)),
        if (result['statusCode'] != null)
          Text('状态码: ${result['statusCode']}', style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
