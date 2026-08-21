import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../services/network_cache.dart';
import 'dart:io';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late Dio _dio;
  String? _token;
  
  
  final Map<String, int> _activeRequests = {};
  static const int _maxConcurrentRequests = 20;  
  
  
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    
    
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
      client.connectionTimeout = const Duration(seconds: 15);
      return client;
    };
    
    debugPrint('ApiClient 初始化，baseUrl: ${AppConfig.apiBaseUrl}');
    
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        
        final requestKey = '${options.method}:${options.path}';
        final currentCount = _activeRequests[requestKey] ?? 0;
        if (currentCount >= _maxConcurrentRequests) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.cancel,
              message: '请求过多，请稍后再试',
            ),
          );
        }
        
        
        _activeRequests[requestKey] = (_activeRequests[requestKey] ?? 0) + 1;
        
        
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        
        
        options.baseUrl = AppConfig.apiBaseUrl;
        
        
        if (NetworkCache.shouldCache(options.method, options.path)) {
          final cacheKey = NetworkCache.generateKey(
            options.method,
            options.path,
            options.queryParameters,
          );
          
          final cachedData = await NetworkCache().get(cacheKey);
          if (cachedData != null) {
            
            return handler.resolve(
              Response(
                requestOptions: options,
                data: cachedData,
                statusCode: 200,
                statusMessage: 'OK (from cache)',
              ),
            );
          }
        }
        
        return handler.next(options);
      },
      
      onResponse: (response, handler) async {
        
        final requestKey = '${response.requestOptions.method}:${response.requestOptions.path}';
        _activeRequests[requestKey] = (_activeRequests[requestKey] ?? 1) - 1;
        
        
        if (NetworkCache.shouldCache(
          response.requestOptions.method,
          response.requestOptions.path,
        )) {
          final cacheKey = NetworkCache.generateKey(
            response.requestOptions.method,
            response.requestOptions.path,
            response.requestOptions.queryParameters,
          );
          
          final duration = NetworkCache.getCacheDuration(
            response.requestOptions.path,
          );
          
          await NetworkCache().set(cacheKey, response.data, duration: duration);
        }
        
        return handler.next(response);
      },
      
      onError: (error, handler) async {
        
        final requestKey = '${error.requestOptions.method}:${error.requestOptions.path}';
        _activeRequests[requestKey] = (_activeRequests[requestKey] ?? 1) - 1;
        
        
        final retryCount = error.requestOptions.extra['retry_count'] ?? 0;
        
        if (retryCount < _maxRetries && _shouldRetry(error)) {
          
          await Future.delayed(_retryDelay);
          
          
          error.requestOptions.extra['retry_count'] = retryCount + 1;
          
          try {
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            
          }
        }
        
        
        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout) {
          
          final newDomain = await _tryBackupDomain();
          if (newDomain != null) {
            
            error.requestOptions.baseUrl = newDomain;
            error.requestOptions.extra['retry_count'] = 0;
            
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              
            }
          }
        }
        
        return handler.next(error);
      },
    ));
  }
  
  Dio get dio => _dio;
  
  void setToken(String token) {
    _token = token;
  }
  
  void clearToken() {
    _token = null;
  }
  
  
  Future<void> clearCache() async {
    await NetworkCache().clear();
  }
  
  
  Future<void> invalidatePath(String method, String path) async {
    final cacheKey = NetworkCache.generateKey(method, path);
    await NetworkCache().remove(cacheKey);
  }
  
  
  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError;
  }
  
  Future<String?> _tryBackupDomain() async {
    for (final url in AppConfig.backupUrls) {
      if (await _checkDomain(url)) {
        await AppConfig.updateBaseUrl(url);
        return url;
      }
    }
    return null;
  }
  
  Future<bool> _checkDomain(String url) async {
    try {
      final response = await Dio().get(
        '$url/api/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  
  void cancelAllRequests() {
    _dio.close(force: true);
  }
}
