import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/pages/onboarding/onboarding_page.dart';

import '../test_helpers.dart';

/// 引导页 widget 测试。
/// 纯前端 + SharedPreferences；兜底装一个 catch-all adapter 拦截
/// 跳转 LoginPage 后 postFrame 触发的更新检查请求，避免真实网络。
void main() {
  ensureTestBinding();

  Widget buildHome() => const MaterialApp(home: OnboardingPage());

  Future<void> gotoNext(WidgetTester tester) async {
    await tester.tap(find.text('下一步'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
    installMockAdapter((options) => jsonResponse({}));
  });

  testWidgets('初始展示欢迎页与跳过/下一步按钮', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pump();

    expect(find.text('欢迎使用人口通'), findsOneWidget);
    expect(find.text('高效管理人口信息，随时随地查询和编辑'), findsOneWidget);
    expect(find.byIcon(Icons.people), findsOneWidget);
    expect(find.text('跳过'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);
    expect(find.text('开始使用'), findsNothing);
  });

  testWidgets('逐页翻到最后一页按钮文案变为开始使用', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pump();

    await gotoNext(tester);
    expect(find.text('搜索人员'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);

    await gotoNext(tester);
    expect(find.text('离线使用'), findsOneWidget);

    await gotoNext(tester);
    expect(find.text('数据统计'), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    expect(find.text('开始使用'), findsOneWidget);
    expect(find.text('下一步'), findsNothing);
  });

  testWidgets('最后一页点击开始使用写入完成标记', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pump();
    await gotoNext(tester);
    await gotoNext(tester);
    await gotoNext(tester);

    await tester.tap(find.text('开始使用'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_completed'), true);
  });

  testWidgets('点击跳过立即写入完成标记', (tester) async {
    await tester.pumpWidget(buildHome());
    await tester.pump();

    await tester.tap(find.text('跳过'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_completed'), true);
  });
}
