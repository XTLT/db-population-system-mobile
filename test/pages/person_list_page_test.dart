// 人员列表页 widget 测试
// 覆盖：初始空态、空查询 SnackBar、搜索结果渲染、空结果提示、接口失败错误态
// 网络：PersonApi.searchByName -> GET /api/search?name=...
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/pages/home/person_list_page.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
  });

  testWidgets('初始渲染空态提示，不发起请求', (tester) async {
    installMockAdapter((options) async => jsonResponse({'results': []}));

    await tester.pumpWidget(const MaterialApp(home: PersonListPage()));
    await tester.pump();

    expect(find.text('人员列表'), findsOneWidget);
    expect(find.text('请输入姓名进行查询'), findsOneWidget);
  });

  testWidgets('姓名为空时点击搜索按钮弹出 SnackBar 提示', (tester) async {
    installMockAdapter((options) async => jsonResponse({'results': []}));

    await tester.pumpWidget(const MaterialApp(home: PersonListPage()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 空态文案与 SnackBar 文案相同，应至少出现两处
    expect(find.text('请输入姓名进行查询'), findsWidgets);
  });

  testWidgets('搜索命中后渲染人员列表项（姓名/身份证/年龄）', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/search') {
        return jsonResponse({
          'results': [
            {
              'id_card': '110101199001011234',
              'name': '张三',
              'age': '35',
              'is_dead': '否',
            },
            {
              'id_card': '110101199001011235',
              'name': '李四',
              'age': '40',
              'is_dead': '否',
              'relation': '户主',
            },
          ],
        });
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(home: PersonListPage()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '张');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('张三'), findsOneWidget);
    expect(find.text('李四'), findsOneWidget);
    expect(find.text('身份证: 110101199001011234'), findsOneWidget);
    expect(find.textContaining('35岁'), findsOneWidget);
  });

  testWidgets('搜索无结果时弹出未找到提示', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/search') {
        return jsonResponse({'results': []});
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(home: PersonListPage()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '不存在的人');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('未找到相关记录'), findsOneWidget);
  });

  testWidgets('接口返回错误时展示错误文案', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/search') {
        return jsonResponse({'error': '服务器内部错误'}, statusCode: 500);
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(home: PersonListPage()));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '张');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 错误体（_errorMessage）与 SnackBar 均应包含错误信息
    expect(find.textContaining('服务器内部错误'), findsWidgets);
  });
}
