import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/services/search_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SearchHistoryService.formatSearchParams Tests（纯静态，无 prefs）', () {
    test('空参数应返回 无条件', () {
      expect(SearchHistoryService.formatSearchParams({}), '无条件');
    });

    test('仅姓名', () {
      expect(SearchHistoryService.formatSearchParams({'name': '张三'}), '姓名: 张三');
    });

    test('多条件应按固定顺序用逗号拼接', () {
      final s = SearchHistoryService.formatSearchParams({
        'name': '张三',
        'idCard': '110101',
        'huHao': 'H1',
        'address': '北京',
      });
      expect(s, '姓名: 张三, 身份证: 110101, 户号: H1, 地址: 北京');
    });

    test('年龄区间（min/max 都有）', () {
      expect(
        SearchHistoryService.formatSearchParams({'ageMin': 20, 'ageMax': 60}),
        '年龄: 20-60',
      );
    });

    test('仅 ageMin 时 max 为空串', () {
      expect(
        SearchHistoryService.formatSearchParams({'ageMin': 18}),
        '年龄: 18-',
      );
    });

    test('残疾/低保/去世条件', () {
      final s = SearchHistoryService.formatSearchParams({
        'disability': '是',
        'dibao': '否',
        'isDead': '否',
      });
      expect(s, '残疾: 是, 低保: 否, 去世: 否');
    });

    test('空字符串值应被忽略', () {
      expect(SearchHistoryService.formatSearchParams({'name': ''}), '无条件');
    });
  });

  group('SearchHistoryService 存取（prefs mock）', () {
    test('初始历史为空', () async {
      expect(await SearchHistoryService.getHistory(), isEmpty);
    });

    test('saveSearch 应插入到头部', () async {
      await SearchHistoryService.saveSearch({'name': 'A'});
      await SearchHistoryService.saveSearch({'name': 'B'});

      final h = await SearchHistoryService.getHistory();
      expect(h.length, 2);
      // 后插入的在最前
      expect(h[0]['params']['name'], 'B');
      expect(h[1]['params']['name'], 'A');
    });

    test('历史上限为 10 条', () async {
      for (var i = 0; i < 15; i++) {
        await SearchHistoryService.saveSearch({'name': 'p$i'});
      }
      final h = await SearchHistoryService.getHistory();
      expect(h.length, 10);
      // 最新的应保留（p14 在最前）
      expect(h[0]['params']['name'], 'p14');
    });

    test('deleteHistoryItem 应删除指定下标', () async {
      await SearchHistoryService.saveSearch({'name': 'A'});
      await SearchHistoryService.saveSearch({'name': 'B'});
      await SearchHistoryService.deleteHistoryItem(0);

      final h = await SearchHistoryService.getHistory();
      expect(h.length, 1);
      expect(h[0]['params']['name'], 'A');
    });

    test('越界下标删除不应崩溃也不改变列表', () async {
      await SearchHistoryService.saveSearch({'name': 'A'});
      await SearchHistoryService.deleteHistoryItem(99);
      final h = await SearchHistoryService.getHistory();
      expect(h.length, 1);
    });

    test('clearHistory 应清空', () async {
      await SearchHistoryService.saveSearch({'name': 'A'});
      await SearchHistoryService.clearHistory();
      expect(await SearchHistoryService.getHistory(), isEmpty);
    });
  });
}
