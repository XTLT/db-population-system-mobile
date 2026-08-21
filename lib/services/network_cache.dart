
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkCache {
  static final NetworkCache _instance = NetworkCache._internal();
  factory NetworkCache() => _instance;

  NetworkCache._internal();

  static const String _cachePrefix = 'network_cache_';
  static const String _cacheVersionKey = 'network_cache_version';
  
  static const int _cacheVersion = 2; 
  static const int _defaultCacheDuration = 5 * 60; 

  
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getInt(_cacheVersionKey) ?? 0;

      if (savedVersion < _cacheVersion) {
        
        await clear();
        await prefs.setInt(_cacheVersionKey, _cacheVersion);
      }
    } catch (e) {
      
    }
  }

  
  Future<void> set(
    String key,
    dynamic data, {
    int? duration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final expireTime = DateTime.now().add(
        Duration(seconds: duration ?? _defaultCacheDuration),
      );

      final cacheData = {
        'data': data,
        'expire_time': expireTime.toIso8601String(),
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      
    }
  }
  
  
  Future<dynamic> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      final cacheString = prefs.getString(cacheKey);
      
      if (cacheString == null) return null;
      
      final cacheData = jsonDecode(cacheString);
      final expireTime = DateTime.parse(cacheData['expire_time']);
      
      
      if (DateTime.now().isAfter(expireTime)) {
        await remove(key);
        return null;
      }
      
      return cacheData['data'];
    } catch (e) {
      return null;
    }
  }
  
  
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _cachePrefix + key;
      await prefs.remove(cacheKey);
    } catch (e) {
      
    }
  }
  
  
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      
    }
  }
  
  
  Future<int> getCacheSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          final value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length;
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  
  static String generateKey(String method, String path, [Map<String, dynamic>? params]) {
    final buffer = StringBuffer();
    buffer.write(method.toUpperCase());
    buffer.write(':');
    buffer.write(path);
    
    if (params != null && params.isNotEmpty) {
      final sortedKeys = params.keys.toList()..sort();
      buffer.write('?');
      for (final key in sortedKeys) {
        buffer.write('$key=${params[key]}&');
      }
    }
    
    return buffer.toString();
  }
  
  
  static bool shouldCache(String method, String path) {
    
    if (method.toUpperCase() != 'GET') return false;
    
    
    if (path.contains('/statistics')) return true;
    
    
    if (path.contains('/students') && !path.contains('/search')) return true;
    
    
    if (path.contains('/person/') || path.contains('/student/')) return true;
    
    return false;
  }
  
  
  static int getCacheDuration(String path) {
    
    if (path.contains('/statistics')) {
      return 10 * 60; 
    }
    
    
    if (path.contains('/person/') || path.contains('/student/')) {
      return 2 * 60; 
    }
    
    
    return 1 * 60; 
  }
}
