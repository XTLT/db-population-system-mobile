import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../config/app_config.dart';
import 'dart:io';

class DomainService {
  
  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    
    
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
      client.connectionTimeout = const Duration(seconds: 5);
      return client;
    };
    
    return dio;
  }
  
  
  static Future<bool> checkDomain(String url) async {
    try {
      final response = await _createDio().get(
        '$url/api/health',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  
  static Future<Map<String, dynamic>> testCurrentDomain() async {
    final url = AppConfig.apiBaseUrl;
    final startTime = DateTime.now();
    
    try {
      final response = await _createDio().get('$url/api/health');
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      
      return {
        'url': url,
        'available': response.statusCode == 200,
        'response_time': duration,
      };
    } catch (e) {
      return {
        'url': url,
        'available': false,
        'response_time': 0,
        'error': e.toString(),
      };
    }
  }
  
  
  static Future<List<Map<String, dynamic>>> checkAllDomains() async {
    final results = <Map<String, dynamic>>[];
    
    
    results.add(await testCurrentDomain());
    
    
    for (final url in AppConfig.backupUrls) {
      final startTime = DateTime.now();
      try {
        final response = await _createDio().get('$url/api/health');
        final endTime = DateTime.now();
        
        results.add({
          'url': url,
          'available': response.statusCode == 200,
          'response_time': endTime.difference(startTime).inMilliseconds,
        });
      } catch (e) {
        results.add({
          'url': url,
          'available': false,
          'response_time': 0,
        });
      }
    }
    
    return results;
  }
}
