// 学生详情页 widget 测试
// 覆盖：字段渲染、加载失败重试
// 网络：StudentApi.getStudent -> GET /api/student/:idCard
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/pages/student/student_detail_page.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
  });

  const idCard = 'S001';

  testWidgets('加载并渲染学生详情各分组字段', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/student/$idCard') {
        return jsonResponse({
          'student': {
            'id_card': idCard,
            'name': '王小明',
            'school_name': '第一小学',
            'grade': 'G3',
            'class_name': '三年二班',
            'guardian': '王大',
            'guardian_phone': '13900000000',
            'is_left_behind': '否',
            'student_status': '在读',
          },
        });
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(
      home: StudentDetailPage(idCard: idCard),
    ));

    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('王小明'), findsWidgets);
    expect(find.text('第一小学'), findsOneWidget);
    expect(find.text('三年二班'), findsOneWidget);
    expect(find.text('王大'), findsOneWidget);
    expect(find.text('学校信息'), findsOneWidget);
    expect(find.text('监护人信息'), findsOneWidget);
    expect(find.text('个人信息'), findsOneWidget);
  });

  testWidgets('详情接口失败时显示错误与重试按钮', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/student/$idCard') {
        return jsonResponse({'error': '未找到该学生'}, statusCode: 404);
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(
      home: StudentDetailPage(idCard: idCard),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
