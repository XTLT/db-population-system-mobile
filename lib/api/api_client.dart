import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
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
  String? _pinnedCertFingerprint; // 服务器证书 SHA-256 指纹（从 assets 加载）

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
    
    // 证书固定：从 assets 加载服务端证书指纹
    _loadPinnedCert();
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
  
  /// 从 assets 加载服务器证书，计算 SHA-256 指纹用于钉扎验证
  Future<void> _loadPinnedCert() async {
    try {
      final data = await rootBundle.load('assets/certs/server.crt');
      final pemStr = String.fromCharCodes(data.buffer.asUint8List());
      final derBytes = _pemToDer(pemStr);
      _pinnedCertFingerprint = sha256.convert(derBytes).toString();
      debugPrint('证书钉扎: 已加载服务器证书指纹');
    } catch (e) {
      debugPrint('证书钉扎: 加载证书失败: $e');
    }
  }

  /// PEM 转 DER（去头尾、Base64 解码）
  Uint8List _pemToDer(String pem) {
    final lines = pem.split('\n');
    final b64 = lines
        .where((l) => !l.startsWith('-----') && l.trim().isNotEmpty)
        .join();
    return base64.decode(b64);
  }

  /// 验证服务器证书是否与钉扎证书匹配
  bool _verifyPinnedCert(X509Certificate cert, String host) {
    if (_pinnedCertFingerprint == null) {
      debugPrint('证书钉扎: 指纹未加载，拒绝连接 (host: $host)');
      return false;
    }
    try {
      final serverFp = sha256.convert(cert.der).toString();
      if (serverFp == _pinnedCertFingerprint) {
        return true;
      }
      debugPrint('证书钉扎: 证书不匹配 (host: $host)');
    } catch (e) {
      debugPrint('证书钉扎: 验证异常 (host: $host): $e');
    }
    return false;
  }

  /// 为外部 Dio 实例（如 healthDio）设置证书钉扎
  static void applyCertificatePinning(Dio dio) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      onHttpClientCreate: (client) {
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          return _instance._verifyPinnedCert(cert, host);
        };
        return client;
      },
    );
  }

  /// 初始化证书固定
  ///
  /// 安全方案：
  /// 1. 从 assets/certs/server.crt 加载证书，计算 SHA-256 指纹
  /// 2. badCertificateCallback 中比对服务器证书指纹，匹配才放行
  /// 3. 证书未加载时拒绝所有连接（fail closed）
  void _initCertificatePinning() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
      client.connectionTimeout = const Duration(seconds: 15);
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return _verifyPinnedCert(cert, host);
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
      applyCertificatePinning(dio);
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
