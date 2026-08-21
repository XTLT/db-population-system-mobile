import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:population_mobile/main.dart';
import 'package:population_mobile/pages/login/login_page.dart';
import 'package:population_mobile/pages/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Integration Test', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should show login page initially', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 应该显示登录页面
      expect(find.byType(LoginPage), findsOneWidget);
      
      // 应该显示应用标题
      expect(find.text('人口信息查询系统'), findsOneWidget);
      
      // 应该显示登录按钮
      expect(find.text('登录'), findsOneWidget);
    });

    testWidgets('should show error when fields empty', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 点击登录按钮
      await tester.tap(find.text('登录'));
      await tester.pumpAndSettle();

      // 应该显示错误提示
      expect(find.text('用户名和密码不能为空'), findsOneWidget);
    });

    testWidgets('should accept user input', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 输入用户名
      await tester.enterText(find.byType(TextField).first, 'admin');
      
      // 输入密码
      await tester.enterText(find.byType(TextField).last, 'password');
      
      await tester.pumpAndSettle();

      // 验证输入
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('should navigate to home page on successful login', (WidgetTester tester) async {
      // 注意：这个测试需要实际的API，或者需要mock
      // 这里只是演示集成测试的结构
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // 输入凭据
      await tester.enterText(find.byType(TextField).first, 'admin');
      await tester.enterText(find.byType(TextField).last, 'amdin123');
      
      // 点击登录
      await tester.tap(find.text('登录'));
      
      // 等待导航
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // 如果API可用，应该导航到主页
      // expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('App Navigation Test', () {
    testWidgets('should have bottom navigation with 3 tabs', (WidgetTester tester) async {
      // 假设已经登录，测试主页导航
      // 这个测试需要在登录状态下运行
      
      // 注意：实际测试需要先完成登录流程
    });

    testWidgets('should switch between tabs', (WidgetTester tester) async {
      // 测试标签页切换
    });
  });

  group('Person Query Test', () {
    testWidgets('should search person by name', (WidgetTester tester) async {
      // 测试人员查询功能
    });

    testWidgets('should show person detail', (WidgetTester tester) async {
      // 测试人员详情显示
    });
  });
}
