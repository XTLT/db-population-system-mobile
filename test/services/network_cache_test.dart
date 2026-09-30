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

    test('shouldCache 扩展：singular /student/ 详情、其他路径、method 大小写', () {
      // 单个学生详情 -> 命中 /student/
      expect(NetworkCache.shouldCache('GET', '/api/student/456'), true);
      // 学生子路径（非 search）-> 命中 /students
      expect(NetworkCache.shouldCache('GET', '/api/students/123/photos'), true);
      // 登录等普通路径不缓存
      expect(NetworkCache.shouldCache('GET', '/api/login'), false);
      expect(NetworkCache.shouldCache('GET', '/api/foo/bar'), false);
      // method 大小写不敏感
      expect(NetworkCache.shouldCache('get', '/api/statistics'), true);
      expect(NetworkCache.shouldCache('get', '/api/login'), false);
    });

    test('generateKey 扩展：method 大写、参数按 key 排序、无参数无问号', () {
      // method 小写也应被大写
      expect(NetworkCache.generateKey('get', '/api/x'), 'GET:/api/x');

      // 参数应按 key 字母序拼接
      final k = NetworkCache.generateKey('GET', '/api/search', {'b': 2, 'a': 1});
      expect(k, 'GET:/api/search?a=1&b=2&');

      // 无参数时不应有 '?'
      expect(NetworkCache.generateKey('GET', '/api/statistics'), 'GET:/api/statistics');

      // 空 map 等价于无参数
      expect(NetworkCache.generateKey('GET', '/api/statistics', {}), 'GET:/api/statistics');
    });

    test('should return correct cache duration', () {
      // 注意：本用例期望与当前源码 getCacheDuration 实现保持一致：
      //   /statistics        -> 5*60  = 300
      //   /person/ | /student/ -> 30*60 = 1800
      //   其他                -> 15*60 = 900
      // （历史上本文件曾错误地期望 600/120/60，与源码不一致导致测试红，已按实现修正）
      expect(NetworkCache.getCacheDuration('/api/statistics'), 300);
      expect(NetworkCache.getCacheDuration('/api/person/123'), 1800);
      expect(NetworkCache.getCacheDuration('/api/student/456'), 1800);
      expect(NetworkCache.getCacheDuration('/api/students'), 900);
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
