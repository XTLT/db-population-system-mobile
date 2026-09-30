import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/utils/pagination_mixin.dart';

void main() {
  group('PaginationHelper Tests', () {
    late PaginationHelper<int> helper;

    setUp(() {
      helper = PaginationHelper<int>(
        fetchData: (page, pageSize) async {
          // 模拟分页数据
          final start = page * pageSize;
          final end = start + pageSize;
          
          // 模拟总共50条数据
          if (start >= 50) {
            return [];
          }
          
          return List.generate(
            (end > 50 ? 50 - start : pageSize), 
            (i) => start + i,
          );
        },
        pageSize: 10,
      );
    });

    test('should initialize with correct defaults', () {
      expect(helper.items, isEmpty);
      expect(helper.isLoading, false);
      expect(helper.hasMore, true);
      expect(helper.currentPage, 0);
      expect(helper.pageSize, 10);
    });

    test('should load first page', () async {
      await helper.load((callback) => callback());

      expect(helper.items.length, 10);
      expect(helper.items[0], 0);
      expect(helper.items[9], 9);
      expect(helper.currentPage, 1);
      expect(helper.hasMore, true);
    });

    test('should load multiple pages', () async {
      // 第一页
      await helper.load((callback) => callback());
      expect(helper.items.length, 10);

      // 第二页
      await helper.load((callback) => callback());
      expect(helper.items.length, 20);
      expect(helper.currentPage, 2);

      // 第三页
      await helper.load((callback) => callback());
      expect(helper.items.length, 30);
    });

    test('should not load while already loading', () async {
      var loadCount = 0;
      
      final testHelper = PaginationHelper<int>(
        fetchData: (page, pageSize) async {
          loadCount++;
          await Future.delayed(const Duration(milliseconds: 100));
          return [1, 2, 3];
        },
      );

      // 同时发起两个加载请求
      await Future.wait([
        testHelper.load((callback) => callback()),
        testHelper.load((callback) => callback()),
      ]);

      // 应该只加载一次
      expect(loadCount, 1);
    });

    test('should stop loading when no more data', () async {
      // 加载所有页面
      for (int i = 0; i < 10; i++) {
        if (!helper.hasMore) break;
        await helper.load((callback) => callback());
      }

      expect(helper.items.length, 50);
      expect(helper.hasMore, false);
    });

    test('should refresh and reset state', () async {
      // 加载一些数据
      await helper.load((callback) => callback());
      await helper.load((callback) => callback());
      expect(helper.items.length, 20);
      expect(helper.currentPage, 2);

      // 刷新
      await helper.refresh((callback) => callback());
      
      expect(helper.items.length, 10);
      expect(helper.currentPage, 1);
      expect(helper.hasMore, true);
    });

    test('should handle errors', () async {
      final errorHelper = PaginationHelper<int>(
        fetchData: (page, pageSize) async {
          throw Exception('Network error');
        },
      );

      await errorHelper.load((callback) => callback());

      expect(errorHelper.isLoading, false);
      expect(errorHelper.errorMessage, isNotNull);
      expect(errorHelper.errorMessage, contains('Network error'));
    });

    test('should retry after error', () async {
      var shouldFail = true;
      
      final retryHelper = PaginationHelper<int>(
        fetchData: (page, pageSize) async {
          if (shouldFail) {
            throw Exception('Network error');
          }
          return [1, 2, 3];
        },
      );

      // 第一次失败
      await retryHelper.load((callback) => callback());
      expect(retryHelper.errorMessage, isNotNull);

      // 修复问题后重试
      shouldFail = false;
      await retryHelper.retry((callback) => callback());
      
      expect(retryHelper.errorMessage, isNull);
      expect(retryHelper.items.length, 3);
    });

    test('should respect page size', () async {
      final smallHelper = PaginationHelper<int>(
        fetchData: (page, pageSize) async {
          return List.generate(5, (i) => i);
        },
        pageSize: 5,
      );

      await smallHelper.load((callback) => callback());
      
      expect(smallHelper.items.length, 5);
      expect(smallHelper.pageSize, 5);
    });

    test('should detect end of data', () async {
      final limitedHelper = PaginationHelper<int>(
        fetchData: (page, pageSize) async {
          // 只有一页数据
          if (page == 0) {
            return [1, 2, 3, 4, 5];
          }
          return [];
        },
        pageSize: 10,
      );

      await limitedHelper.load((callback) => callback());

      // 返回数据少于页大小，应该标记为没有更多数据
      expect(limitedHelper.hasMore, false);
    });

    // ===== 以下为本次新增 =====

    test('reset 应清空 items/error 并复位 currentPage/hasMore', () async {
      await helper.load((callback) => callback());
      await helper.load((callback) => callback());
      expect(helper.items.length, 20);
      expect(helper.currentPage, 2);

      helper.reset();
      expect(helper.items, isEmpty);
      expect(helper.currentPage, 0);
      expect(helper.hasMore, true);
      expect(helper.errorMessage, isNull);
      expect(helper.isLoading, false);
    });

    test('hasMore=false 时再次 load 应被直接短路（不再请求）', () async {
      var fetchCalls = 0;
      final h = PaginationHelper<int>(
        fetchData: (page, pageSize) async {
          fetchCalls++;
          return []; // 空列表 -> 立即 hasMore=false
        },
        pageSize: 10,
      );

      await h.load((callback) => callback());
      expect(h.hasMore, false);
      expect(fetchCalls, 1);

      // 再来一次：hasMore 已为 false，应直接 return，fetchData 不再被调用
      await h.load((callback) => callback());
      expect(fetchCalls, 1);
    });

    test('fetchData 应收到正确的 (page, pageSize) 入参', () async {
      final seen = <List<int>>[];
      final h = PaginationHelper<int>(
        fetchData: (page, pageSize) async {
          seen.add([page, pageSize]);
          // 第一页返回整页，第二页返回空，便于停止
          return page == 0 ? List.generate(pageSize, (i) => i) : [];
        },
        pageSize: 7,
      );

      await h.load((callback) => callback());
      expect(seen.first, [0, 7]);

      await h.load((callback) => callback());
      expect(seen.last, [1, 7]);
    });

    test('恰好返回 pageSize 条时 hasMore 仍为 true（需再探一页）', () async {
      var calls = 0;
      final h = PaginationHelper<int>(
        fetchData: (page, pageSize) async {
          calls++;
          // 第一页整页，第二页空
          return page == 0 ? List.generate(10, (i) => i) : [];
        },
        pageSize: 10,
      );

      await h.load((callback) => callback());
      // 刚好 10 条 == pageSize，不触发 hasMore=false，currentPage 自增到 1
      expect(h.hasMore, true);
      expect(h.currentPage, 1);
      expect(h.items.length, 10);

      // 再加载一页（空）-> 这一页返回 0 < 10 -> hasMore=false
      await h.load((callback) => callback());
      expect(h.hasMore, false);
      expect(calls, 2);
    });

    test('errorMessage 在成功 load 后应被清空', () async {
      var fail = true;
      final h = PaginationHelper<int>(
        fetchData: (page, pageSize) async {
          if (fail) throw Exception('boom');
          return [1, 2];
        },
      );

      await h.load((callback) => callback());
      expect(h.errorMessage, isNotNull);

      fail = false;
      await h.load((callback) => callback());
      // 注意：load 在 error 后 currentPage 未自增，重试仍从当前页开始，成功后清空 error
      expect(h.errorMessage, isNull);
      expect(h.isLoading, false);
    });
  });
}
