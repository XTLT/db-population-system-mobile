// 登录页 widget 测试
//
// ⚠️ 当前编译阻塞（lib/ 既有错误，不在测试可改范围内）：
//   login_page.dart import 了 home/home_page.dart（登录成功后 pushReplacement 到 HomePage），
//   home_page.dart 又 import 了 settings/settings_page.dart，而 settings_page.dart 断链导入了
//   不存在的 ../logs/operation_log_list_page.dart 与 ../data/data_management_page.dart。
//   修复该断链导入后本文件即可编译运行。
//
// 本文件按页面公开行为编写，覆盖：
//   空表单前端校验、登录失败错误文案、登录成功跳转首页。
//
// 网络：AuthApi.login -> POST /api/login
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/pages/login/login_page.dart';
import 'package:population_mobile/providers/auth_provider.dart';
import 'package:population_mobile/providers/notification_provider.dart';
import 'package:population_mobile/providers/sync_provider.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
    // flutter_secure_storage 平台通道兜底，避免 MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async => null,
    );
  });

  Widget buildApp(AuthProvider auth) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<NotificationProvider>.value(
          value: NotificationProvider()),
        ChangeNotifierProvider<SyncProvider>.value(value: SyncProvider()),
      ],
      child: const MaterialApp(home: LoginPage()),
    );
  }

  Finder userNameField() => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == '用户名');
  Finder passwordField() => find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == '密码');

  // 登录页内容在默认 800x600 测试面会纵向溢出 24px，抬高可视面以贴近真机竖屏。
  void setTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('用户名/密码为空时点击登录显示前端校验提示', (tester) async {
    setTallSurface(tester);
    installMockAdapter((options) async =>
        jsonResponse({'success': false, 'error': 'x'}));

    await tester.pumpWidget(buildApp(AuthProvider()));
    await tester.pump();

    await tester.tap(find.text('登录'));
    await tester.pump();

    expect(find.text('用户名和密码不能为空'), findsOneWidget);
  });

  testWidgets('登录接口返回失败时展示服务端错误文案', (tester) async {
    setTallSurface(tester);
    installMockAdapter((options) async {
      if (options.path == '/api/login') {
        return jsonResponse({
          'success': false,
          'error': '用户名或密码错误',
        });
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(buildApp(AuthProvider()));
    await tester.pump();

    await tester.enterText(userNameField(), 'admin');
    await tester.enterText(passwordField(), 'wrongpass');
    await tester.tap(find.text('登录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('用户名或密码错误'), findsOneWidget);
  });

  testWidgets('登录成功后 pushReplacement 到首页', (tester) async {
    setTallSurface(tester);
    installMockAdapter((options) async {
      if (options.path == '/api/login') {
        return jsonResponse({
          'success': true,
          'token': 'test-token',
          'user': {'username': 'admin', 'role': 'admin'},
        });
      }
      if (options.path == '/api/notifications/unread-count') {
        return jsonResponse({'count': 0});
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(buildApp(AuthProvider()));
    await tester.pump();

    await tester.enterText(userNameField(), 'admin');
    await tester.enterText(passwordField(), 'admin123');
    await tester.tap(find.text('登录'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // pushReplacement 转场结束后旧登录页才会从树中移除
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 跳转后 HomePage 的 AppBar 标题与底部导航
    expect(find.text('人口通'), findsOneWidget);
    expect(find.text('人员查询'), findsOneWidget);
  });
}
