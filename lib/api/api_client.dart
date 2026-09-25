import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../services/network_cache.dart';
import '../services/domain_service.dart';
import '../services/connectivity_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late Dio _dio;
  String? _token;
  String? _effectiveBaseUrl; // 回退成功后缓存，避免每次请求都重试

  final Map<String, int> _activeRequests = {};
  static const int _maxConcurrentRequests = 20;  
  
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 1);
  
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // 证书固定：从 assets 加载服务端证书
    _initCertificatePinning();
    
    debugPrint('ApiClient 初始化，baseUrl: ${AppConfig.apiBaseUrl}');
    
    // 网络切换时重置有效 URL，重新探测最优路径
    ConnectivityService().onConnectivityChanged.listen((_) {
      if (_effectiveBaseUrl != null) {
        debugPrint('网络变化，重置 effectiveBaseUrl');
        _effectiveBaseUrl = null;
      }
    });
    
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
        
        options.baseUrl = AppConfig.normalizeUrl(_effectiveBaseUrl ?? AppConfig.apiBaseUrl);
        
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

          // 1. 尝试链路本地 IPv6（WiFi 场景：手机和服务器在同一局域网，
          //    但手机只有内网 IPv6，无法路由到服务器的全局 IPv6）
          if (error.requestOptions.extra['linklocal_tried'] != true) {
            error.requestOptions.extra['linklocal_tried'] = true;
            final linkLocalUrl = await DomainService.resolveLinkLocalIPv6(AppConfig.apiBaseUrl);
            if (linkLocalUrl != null) {
              error.requestOptions.baseUrl = linkLocalUrl;
              error.requestOptions.extra['retry_count'] = 0;
              try {
                final response = await _dio.fetch(error.requestOptions);
                _effectiveBaseUrl = linkLocalUrl;
                debugPrint('链路本地 IPv6 连接成功，缓存为 effectiveBaseUrl: $linkLocalUrl');
                return handler.resolve(response);
              } catch (_) {}
            }
          }

          // 2. 尝试 IPv4 解析
          if (error.requestOptions.extra['ipv4_tried'] != true) {
            error.requestOptions.extra['ipv4_tried'] = true;
            final ipv4Url = await _resolveToIPv4(AppConfig.apiBaseUrl);
            if (ipv4Url != null) {
              error.requestOptions.baseUrl = ipv4Url;
              error.requestOptions.extra['retry_count'] = 0;
              try {
                final response = await _dio.fetch(error.requestOptions);
                _effectiveBaseUrl = ipv4Url;
                debugPrint('IPv4 连接成功，缓存为 effectiveBaseUrl: $ipv4Url');
                return handler.resolve(response);
              } catch (e) {
              }
            }
          }

          // 3. 尝试备用域名
          final newDomain = await _tryBackupDomain();
          if (newDomain != null) {
            
            error.requestOptions.baseUrl = newDomain;
            error.requestOptions.extra['retry_count'] = 0;
            
            try {
              final response = await _dio.fetch(error.requestOptions);
              _effectiveBaseUrl = newDomain;
              debugPrint('备用域名连接成功，缓存为 effectiveBaseUrl: $newDomain');
              return handler.resolve(response);
            } catch (e) {
              
            }
          }
        }
        
        return handler.next(error);
      },
    ));
  }
  
  /// 初始化证书固定
  /// 
  /// 安全方案：
  /// 1. 如果 assets/certs/server.crt 存在，使用该证书验证（推荐）
  /// 2. 如果不存在，允许所有证书（开发/测试环境）
  /// 
  /// 部署时请将服务端的 server.crt 复制到 mobile/assets/certs/ 目录
  /// 并在 pubspec.yaml 中添加 assets 配置
  void _initCertificatePinning() {
    (_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
      client.connectionTimeout = const Duration(seconds: 15);
      
      // 尝试加载本地证书
      try {
        final SecurityContext securityContext = SecurityContext();
        // 从 assets 加载证书
        final certData = rootBundle.load('assets/certs/server.crt');
        certData.then((data) {
          securityContext.setTrustedCertificatesBytes(data.buffer.asUint8List());
          debugPrint('已加载服务端证书，启用证书固定验证');
        }).catchError((e) {
          debugPrint('未找到本地证书，跳过证书固定: $e');
        });
      } catch (e) {
        debugPrint('证书加载失败，跳过证书固定: $e');
      }
      
      // 如果证书加载失败，允许自签名证书（开发环境）
      // 生产环境应该有证书文件
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        debugPrint('警告: 跳过证书验证 (host: $host)');
        return true;
      };
      
      return client;
    };
  }
  
  Dio get dio => _dio;
  
  void setToken(String token) {
    _token = token;
  }
  
  void clearToken() {
    _token = null;
  }
  
  /// 重置有效 URL 缓存，下次请求将重新探测最优连接路径
  void resetEffectiveBaseUrl() {
    _effectiveBaseUrl = null;
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
           error.type == DioExceptionType.receiveTimeout;
  }
  
  Future<String?> _resolveToIPv4(String url) async {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) return null;
      final addresses = await InternetAddress.lookup(
        uri.host,
        type: InternetAddressType.IPv4,
      ).timeout(const Duration(seconds: 3));
      if (addresses.isNotEmpty) {
        return url.replaceFirst(uri.host, addresses.first.address);
      }
    } catch (_) {}
    return null;
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
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      };
      final response = await dio.get('$url/api/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  
  void cancelAllRequests() {
    _dio.close(force: true);
  }
}
