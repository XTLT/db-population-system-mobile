// 人员详情页 widget 测试
// 覆盖：基本信息字段渲染、加载失败重试、家庭成员 Tab
// 网络：PersonApi.getPersonDetail -> GET /api/person/:idCard
//       PersonApi.getFamilyMembers  -> GET /api/family/:huHao
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/pages/person/person_detail_page.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
  });

  const idCard = '110101199001011234';

  testWidgets('加载中先显示进度，完成后渲染基本信息字段', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/person/$idCard') {
        return jsonResponse({
          'person': {
            'id_card': idCard,
            'name': '张三',
            'age': '35',
            'is_dead': '否',
            'hu_hao': 'H001',
            'relation': '户主',
            'phone': '13800138000',
            'address': 'XX村1号',
            'poor_type': '脱贫户',
            'disability': '是',
            'disability_type': '肢体',
            'dis_level': '三级',
            'dibao': '否',
            'tekun': '否',
          },
        });
      }
      if (options.path == '/api/family/H001') {
        return jsonResponse({'members': []});
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(
      home: PersonDetailPage(idCard: idCard),
    ));

    // 首帧应处于加载态
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 姓名同时出现在 AppBar 标题与基本信息大标题，共 2 处
    expect(find.text('张三'), findsNWidgets(2));
    expect(find.textContaining(idCard), findsWidgets);
    expect(find.text('13800138000'), findsOneWidget);
    expect(find.text('XX村1号'), findsOneWidget);
    expect(find.text('脱贫户'), findsOneWidget);
    // disability == '是' 时应展开残疾类型/等级
    expect(find.text('肢体'), findsOneWidget);
    expect(find.text('三级'), findsOneWidget);
    expect(find.text('身份信息'), findsOneWidget);
    expect(find.text('社会保障'), findsOneWidget);
  });

  testWidgets('详情接口失败时显示错误提示与重试按钮', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/person/$idCard') {
        return jsonResponse({'error': '未找到该人员'}, statusCode: 404);
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(
      home: PersonDetailPage(idCard: idCard),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });

  testWidgets('切换到家庭成员 Tab 渲染成员列表', (tester) async {
    installMockAdapter((options) async {
      if (options.path == '/api/person/$idCard') {
        return jsonResponse({
          'person': {
            'id_card': idCard,
            'name': '张三',
            'age': '35',
            'is_dead': '否',
            'hu_hao': 'H001',
            'relation': '户主',
          },
        });
      }
      if (options.path == '/api/family/H001') {
        return jsonResponse({
          'members': [
            {
              'id_card': '110101199001011235',
              'name': '李四',
              'relation': '配偶',
              'is_dead': '否',
            },
          ],
        });
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    await tester.pumpWidget(const MaterialApp(
      home: PersonDetailPage(idCard: idCard),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('家庭成员'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('李四'), findsOneWidget);
    expect(find.textContaining('配偶'), findsOneWidget);
  });
}
