
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkCache {
  static final NetworkCache _instance = NetworkCache._internal();
  factory NetworkCache() => _instance;

  NetworkCache._internal();

  static const String _cachePrefix = 'network_cache_';
  static const String _cacheVersionKey = 'network_cache_version';
  
  static const int _cacheVersion = 3;
  static const int _defaultCacheDuration = 30 * 60; 

  
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
            totalSize += value.length * 2;
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
  
  
  // 缓存时长策略（BUG-06 评估：保留现有实现）：
  //  - 统计类 /statistics：5 分钟（300s）——聚合数随人员/补贴增删频繁变化，需较短过期以尽快反映最新统计；
  //  - 人员/学生详情 /person/、/student/：30 分钟（1800s）——单条档案相对稳定，离线弱网下可较长复用；
  //  - 其他可缓存 GET：15 分钟（900s）——折中默认，兼顾新鲜度与离线可用性。
  static int getCacheDuration(String path) {
    if (path.contains('/statistics')) {
      return 5 * 60;
    }
    if (path.contains('/person/') || path.contains('/student/')) {
      return 30 * 60;
    }
    return 15 * 60;
  }
}
