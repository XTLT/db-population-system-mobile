import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/pages/settings/theme_customize_page.dart';
import 'package:population_mobile/providers/theme_provider.dart';

import '../test_helpers.dart';

/// 主题定制页 widget 测试（纯前端：ThemeProvider + SharedPreferences，无网络）。
void main() {
  ensureTestBinding();

  late ThemeProvider provider;

  Widget buildApp() => MaterialApp(
        home: ChangeNotifierProvider<ThemeProvider>.value(
          value: provider,
          child: const ThemeCustomizePage(),
        ),
      );

  // 预设红色色块（AppTheme.presetColors 中的 Colors.red == 0xFFF44336）
  Finder presetColor(Color color) => find.byWidgetPredicate((w) =>
      w is Container &&
      w.decoration is BoxDecoration &&
      (w.decoration as BoxDecoration).color == color);

  // “应用设置”按钮在 ListView 最底部，默认视口下尚未构建，需先滚动到可见。
  Future<void> scrollToApply(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('应用设置'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = ThemeProvider();
  });

  testWidgets('渲染主题色/字体大小/预览分区与默认蓝色100%', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('主题色'), findsWidgets);
    expect(find.text('字体大小'), findsWidgets);
    expect(find.text('预览'), findsOneWidget);
    await scrollToApply(tester);
    expect(find.text('应用设置'), findsOneWidget);
    expect(find.text('重置'), findsOneWidget);
    expect(find.text('自定义颜色'), findsOneWidget);
    // Colors.blue = 0xFF2196F3
    expect(find.text('当前: #FF2196F3'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('点击预设红色后应用设置写入 provider 与持久化', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(presetColor(Colors.red), findsOneWidget);
    await tester.tap(presetColor(Colors.red));
    await tester.pump();
    // 副标题同步更新（Colors.red = 0xFFF44336）
    expect(find.text('当前: #FFF44336'), findsOneWidget);

    await scrollToApply(tester);
    await tester.tap(find.text('应用设置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('主题设置已应用'), findsOneWidget);
    expect(provider.seedColor, Colors.red);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('seed_color'), Colors.red.value);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });

  testWidgets('拖动字体大小滑块后应用设置生效并持久化', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    final slider = find.byType(Slider);
    expect(tester.widget<Slider>(slider).value, 1.0);

    final gesture = await tester.startGesture(tester.getCenter(slider));
    await gesture.moveBy(const Offset(150, 0));
    await gesture.up();
    await tester.pump();

    final newValue = tester.widget<Slider>(slider).value;
    expect(newValue, greaterThan(1.0));

    await scrollToApply(tester);
    await tester.tap(find.text('应用设置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('主题设置已应用'), findsOneWidget);
    expect(provider.textScaleFactor, newValue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('text_scale_factor'), newValue);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });

  testWidgets('重置按钮恢复默认并清空持久化', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    // 先改成红色
    await tester.tap(presetColor(Colors.red));
    await tester.pump();

    await tester.tap(find.text('重置'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('已重置为默认设置'), findsOneWidget);
    expect(provider.seedColor, Colors.blue);
    expect(provider.textScaleFactor, 1.0);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('seed_color'), isNull);
    expect(prefs.getDouble('text_scale_factor'), isNull);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });

  testWidgets('自定义颜色对话框可打开并通过取消关闭', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.text('自定义颜色'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('选择颜色'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('选择颜色'), findsNothing);
  });
}
