// 首页骨架 widget 测试
//
// ⚠️ 当前编译阻塞（lib/ 既有错误，不在测试可改范围内）：
//   home_page.dart import 了 settings/settings_page.dart，后者断链导入了
//   不存在的 ../logs/operation_log_list_page.dart 与 ../data/data_management_page.dart。
//   修复该断链导入后本文件即可编译运行。
//
// 本文件按页面公开行为编写，覆盖：
//   AppBar 标题 + 底部三个导航入口、未读通知角标渲染、切到数据统计 Tab 渲染统计卡片。
//
// 网络：NotificationApi.getUnreadCount -> GET /api/notifications/unread-count
//       StatisticsApi.*               -> GET /api/statistics 等（切 Tab 后触发）
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/pages/home/home_page.dart';
import 'package:population_mobile/providers/auth_provider.dart';
import 'package:population_mobile/providers/notification_provider.dart';
import 'package:population_mobile/providers/sync_provider.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  Widget buildApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: AuthProvider()),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: NotificationProvider()),
        ChangeNotifierProvider<SyncProvider>.value(value: SyncProvider()),
      ],
      child: const MaterialApp(home: HomePage()),
    );
  }

  testWidgets('渲染 AppBar 标题与底部三个导航入口', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/notifications/unread-count') {
        return jsonResponse({'count': 0});
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('人口通'), findsOneWidget);
    expect(find.text('人员查询'), findsOneWidget);
    expect(find.text('学生管理'), findsOneWidget);
    expect(find.text('数据统计'), findsOneWidget);
  });

  testWidgets('未读通知角标按接口数值渲染', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/notifications/unread-count') {
        return jsonResponse({'count': 3});
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('3'), findsWidgets);
  });

  testWidgets('切换到数据统计 Tab 渲染人口统计卡片', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/notifications/unread-count') {
        return jsonResponse({'count': 0});
      }
      if (options.path == '/api/statistics') {
        return jsonResponse({
          'total': 120,
          'alive': 110,
          'dead': 8,
          'migrated': 2,
        });
      }
      if (options.path == '/api/students/statistics') {
        return jsonResponse({'total': 5});
      }
      if (options.path == '/api/land_subsidy/statistics') {
        return jsonResponse({'total_count': 10});
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(buildApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('数据统计'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('总人数'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
  });
}
