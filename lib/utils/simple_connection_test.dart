import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'dart:io';


class SimpleConnectionTest {
  static Future<Map<String, dynamic>> test(String url) async {
    final results = <String, dynamic>{};
    
    
    final dio = Dio(BaseOptions(
      baseUrl: url,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
      },
    ));
    
    // 配置HTTP客户端以允许自签名证书
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
    
    debugPrint('========== 简单连接测试 ==========');
    debugPrint('URL: $url');
    
    
    try {
      debugPrint('测试1: GET $url');
      final response = await dio.get(url);
      results['basic'] = {
        'success': true,
        'status': response.statusCode,
      };
      debugPrint('✓ 成功: ${response.statusCode}');
    } on DioException catch (e) {
      results['basic'] = {
        'success': false,
        'type': e.type.toString(),
        'message': e.message,
        'error': e.error?.toString(),
      };
      debugPrint('✗ 失败: ${e.type} - ${e.message}');
      debugPrint('  错误详情: ${e.error}');
    }
    
    
    try {
      debugPrint('\n测试2: GET $url/api/health');
      final response = await dio.get('/api/health');
      results['health'] = {
        'success': true,
        'data': response.data,
      };
      debugPrint('✓ 成功: ${response.data}');
    } on DioException catch (e) {
      results['health'] = {
        'success': false,
        'type': e.type.toString(),
        'message': e.message,
      };
      debugPrint('✗ 失败: ${e.type}');
    }
    
    
    try {
      debugPrint('\n测试3: POST $url/api/login (跳过 - 需要真实凭据)');
      results['login'] = {
        'success': false,
        'message': '测试连接请使用真实账户登录',
      };
    } on DioException catch (e) {
      results['login'] = {
        'success': false,
        'type': e.type.toString(),
        'message': e.message,
        'responseCode': e.response?.statusCode,
        'responseData': e.response?.data,
      };
      debugPrint('✗ 失败: ${e.type} - ${e.response?.statusCode}');
    }
    
    return results;
  }
  
  
  static void showResults(BuildContext context, Map<String, dynamic> results) {
    final basic = results['basic'] as Map<String, dynamic>?;
    final health = results['health'] as Map<String, dynamic>?;
    final login = results['login'] as Map<String, dynamic>?;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('连接测试结果'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSection('基础连接', basic),
              const Divider(),
              _buildSection('Health端点', health),
              const Divider(),
              _buildSection('登录接口', login),
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
  
  static Widget _buildSection(String title, Map<String, dynamic>? data) {
    if (data == null) return Text('$title: 未测试');
    
    final success = data['success'] == true;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (!success) ...[
          const SizedBox(height: 4),
          Text(
            '错误类型: ${data['type'] ?? '未知'}',
            style: const TextStyle(fontSize: 12),
          ),
          if (data['message'] != null)
            Text(
              '消息: ${data['message']}',
              style: const TextStyle(fontSize: 12),
            ),
          if (data['error'] != null)
            Text(
              '详情: ${data['error']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ],
      ],
    );
  }
}
