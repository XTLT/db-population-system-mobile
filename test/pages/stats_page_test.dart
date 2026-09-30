// 统计页 widget 测试
//
// ⚠️ 当前编译阻塞（lib/ 既有错误，不在测试可改范围内）：
//   stats_page.dart 顶部 import 了 ../subsidy/elderly_allowance_query_page.dart
//   与 ../subsidy/disability_care_query_page.dart，这两个文件的 createState()
//   返回类型误写为 State<DibaoQueryPage> 且未 import dibao_query_page.dart，
//   属于未定义类型编译错误。修复这两处后本文件即可编译运行。
//
// 本文件按页面公开行为编写，覆盖：
//   人口统计汇总/社会保障/残疾等级卡片、学生统计 Tab、补贴 Tab（林地 num.tryParse 兜底、
//   地力补贴卡片数值）、Tab 切换、接口失败“暂无数据”。
//
// 网络：
//   StatisticsApi.getPersonStatistics        -> GET /api/statistics
//   StatisticsApi.getStudentStatistics       -> GET /api/students/statistics
//   StatisticsApi.getLandSubsidyStatistics   -> GET /api/land_subsidy/statistics
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/pages/home/stats_page.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
  });

  // 人员统计：林地面积用字符串值，覆盖 _SubsidyStatsTab 中 num.tryParse 兜底路径。
  Map<String, dynamic> personStats() => {
        'total': 120,
        'alive': 110,
        'dead': 8,
        'migrated': 2,
        'disability': 5,
        'dibao': 10,
        'tekun': 3,
        'tekun_type_distribution': {'集中供养': 2, '散居特困': 1},
        'poor_type_distribution': {'脱贫户': 50, '监测户': 5},
        'poor_type_person_count': {'脱贫户': 120, '监测户': 15},
        'dis_level_distribution': {'一级': 1, '二级': 2, '三级': 3, '四级': 4},
        // 土地面积用数值（_buildLandAreaStats 直接 toStringAsFixed）
        'total_land_area': 123.45,
        'avg_land_area': 1.23,
        // 林地面积用字符串（_buildForestAreaStats 走 num.tryParse 兜底）
        'total_local_welfare_forest_area': '12.5',
        'avg_local_welfare_forest_area': '1.25',
        'total_national_welfare_forest_area': '8',
        'avg_national_welfare_forest_area': '0.8',
        'total_commercial_forest_area': '5.5',
        'avg_commercial_forest_area': '0.55',
      };

  Map<String, dynamic> studentStats() => {
        'total': 30,
        'studying': 25,
        'left_behind': 4,
        'graduated': 5,
        'grade_distribution': {'G3': 10, 'G8': 8, 'GRADUATED': 5},
        'status_distribution': {'在读': 25, '已毕业': 5},
      };

  Map<String, dynamic> landSubsidyStats() => {
        'total_count': 50,
        'total_certified_area': 100,
        'total_subsidy_area': 90,
        'total_amount': 4500,
        'avg_subsidy_amount': 90,
      };

  installAllOk() {
    installMockAdapter((options) async {
      switch (options.path) {
        case '/api/statistics':
          return jsonResponse(personStats());
        case '/api/students/statistics':
          return jsonResponse(studentStats());
        case '/api/land_subsidy/statistics':
          return jsonResponse(landSubsidyStats());
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });
  }

  testWidgets('人口统计 Tab 渲染汇总卡与社会保障/残疾等级数值', (tester) async {
    installAllOk();

    await tester.pumpWidget(const MaterialApp(home: StatsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('总人数'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('110'), findsOneWidget); // 在世
    expect(find.text('8'), findsOneWidget); // 已死亡
    expect(find.text('社会保障'), findsOneWidget);
    expect(find.text('残疾人员'), findsOneWidget);
    expect(find.text('脱贫户/监测户'), findsOneWidget);
    expect(find.text('残疾等级分布'), findsOneWidget);
  });

  testWidgets('切换到学生统计 Tab 渲染学生总数与状态', (tester) async {
    installAllOk();

    await tester.pumpWidget(const MaterialApp(home: StatsPage()));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('学生统计'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('学生总数'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('在读学生'), findsOneWidget);
    expect(find.text('年级分布'), findsOneWidget);
  });

  testWidgets('补贴 Tab 渲染林地面积（字符串经 num.tryParse 兜底）与地力补贴卡片',
      (tester) async {
    installAllOk();

    await tester.pumpWidget(const MaterialApp(home: StatsPage()));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('补贴统计'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 林地：字符串 '12.5' -> num.tryParse -> 12.50
    expect(find.text('林地面积统计'), findsOneWidget);
    expect(find.text('地方公益林'), findsOneWidget);
    expect(find.text('12.50'), findsOneWidget);
    // 地力补贴卡片
    expect(find.text('地力补贴统计'), findsOneWidget);
    expect(find.text('记录数'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('补贴总额(元)'), findsOneWidget);
  });

  testWidgets('三组统计接口均失败时人口 Tab 显示暂无数据且不崩溃', (tester) async {
    installMockAdapter((options) async =>
        jsonResponse({'error': 'boom'}, statusCode: 500));

    await tester.pumpWidget(const MaterialApp(home: StatsPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('暂无数据'), findsWidgets);
  });
}
