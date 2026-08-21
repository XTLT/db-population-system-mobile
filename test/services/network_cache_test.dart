import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/services/network_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NetworkCache Tests', () {
    setUp(() {
      // 设置 SharedPreferences 的 mock 初始值
      SharedPreferences.setMockInitialValues({});
    });

    test('should cache and retrieve data', () async {
      final cache = NetworkCache();
      const key = 'test_key';
      final data = {'name': '张三', 'age': 30};

      // 保存数据
      await cache.set(key, data, duration: 60);

      // 获取数据
      final retrieved = await cache.get(key);
      
      expect(retrieved, isNotNull);
      expect(retrieved['name'], '张三');
      expect(retrieved['age'], 30);
    });

    test('should return null for non-existent key', () async {
      final cache = NetworkCache();
      final retrieved = await cache.get('non_existent_key');
      expect(retrieved, isNull);
    });

    test('should remove cached data', () async {
      final cache = NetworkCache();
      const key = 'test_key';
      final data = {'name': '张三'};

      // 保存数据
      await cache.set(key, data);

      // 删除数据
      await cache.remove(key);

      // 确认已删除
      final retrieved = await cache.get(key);
      expect(retrieved, isNull);
    });

    test('should clear all cache', () async {
      final cache = NetworkCache();

      // 保存多条数据
      await cache.set('key1', {'data': 1});
      await cache.set('key2', {'data': 2});
      await cache.set('key3', {'data': 3});

      // 清空所有缓存
      await cache.clear();

      // 确认都已删除
      expect(await cache.get('key1'), isNull);
      expect(await cache.get('key2'), isNull);
      expect(await cache.get('key3'), isNull);
    });

    test('should expire cached data', () async {
      final cache = NetworkCache();
      const key = 'test_key';
      final data = {'name': '张三'};

      // 保存数据，过期时间为1秒
      await cache.set(key, data, duration: 1);

      // 立即获取应该成功
      final retrieved1 = await cache.get(key);
      expect(retrieved1, isNotNull);

      // 等待2秒
      await Future.delayed(const Duration(seconds: 2));

      // 过期后应该返回null
      final retrieved2 = await cache.get(key);
      expect(retrieved2, isNull);
    });

    test('should generate correct cache key', () {
      final key1 = NetworkCache.generateKey('GET', '/api/statistics');
      expect(key1, 'GET:/api/statistics');

      final key2 = NetworkCache.generateKey('POST', '/api/login', {'username': 'admin'});
      expect(key2, contains('POST:/api/login'));
      expect(key2, contains('username=admin'));
    });

    test('should determine if request should be cached', () {
      // 统计数据应该缓存
      expect(NetworkCache.shouldCache('GET', '/api/statistics'), true);
      
      // 学生列表应该缓存
      expect(NetworkCache.shouldCache('GET', '/api/students'), true);
      
      // 搜索不应该缓存
      expect(NetworkCache.shouldCache('GET', '/api/students/search'), false);
      
      // POST 请求不应该缓存
      expect(NetworkCache.shouldCache('POST', '/api/login'), false);
      
      // 详情应该缓存
      expect(NetworkCache.shouldCache('GET', '/api/person/123'), true);
    });

    test('should return correct cache duration', () {
      // 统计数据缓存时间长
      expect(NetworkCache.getCacheDuration('/api/statistics'), 600);
      
      // 详情数据缓存时间中等
      expect(NetworkCache.getCacheDuration('/api/person/123'), 120);
      
      // 列表数据缓存时间短
      expect(NetworkCache.getCacheDuration('/api/students'), 60);
    });

    test('should calculate cache size', () async {
      final cache = NetworkCache();

      // 保存一些数据
      await cache.set('key1', 'A' * 100);
      await cache.set('key2', 'B' * 200);

      // 获取缓存大小
      final size = await cache.getCacheSize();
      expect(size, greaterThan(0));
    });
  });
}
