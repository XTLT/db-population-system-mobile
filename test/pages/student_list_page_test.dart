// 学生列表页 widget 测试
// 覆盖：首屏分页渲染、空态、姓名搜索
// 网络：StudentApi.getAllStudents -> GET /api/students?limit=20&offset=0
//       StudentApi.searchStudents -> GET /api/students/search?name=...
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/pages/student/student_list_page.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
  });

  testWidgets('首屏加载学生列表并渲染卡片', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/students') {
        return jsonResponse({
          'students': [
            {
              'id_card': 'S001',
              'name': '王小明',
              'school_name': '第一小学',
              'grade': 'G3',
              'student_status': '在读',
            },
            {
              'id_card': 'S002',
              'name': '小红',
              'school_name': '第一小学',
              'grade': 'G5',
            },
          ],
        });
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StudentListPage()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('王小明'), findsOneWidget);
    expect(find.text('小红'), findsOneWidget);
    expect(find.text('学校: 第一小学'), findsWidgets);
  });

  testWidgets('无学生数据时显示空态文案', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/students') {
        return jsonResponse({'students': []});
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StudentListPage()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('暂无学生数据'), findsOneWidget);
  });

  testWidgets('按姓名搜索学生并渲染命中结果', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/students') {
        return jsonResponse({'students': []});
      }
      if (options.path == '/api/students/search') {
        return jsonResponse({
          'results': [
            {
              'id_card': 'S009',
              'name': '王小明',
              'school_name': '第二中学',
              'grade': 'G8',
            },
          ],
        });
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StudentListPage()),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField), '王小明');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('王小明'), findsWidgets);
    expect(find.text('学校: 第二中学'), findsOneWidget);
  });
}
