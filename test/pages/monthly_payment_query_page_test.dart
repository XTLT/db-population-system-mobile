import 'dart:async';

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/pages/subsidy/monthly_payment_query_page.dart';

import '../test_helpers.dart';

/// 月补贴发放查询页（文件内实际标题为“养老保险查询”）widget 测试。
///
/// 页面源码（monthly_payment_query_page.dart）实际调用：
/// - GET /api/pension_insurance/periods  -> {"periods": ["202501", ...]}
/// - GET /api/pension_insurance         -> {"records": [{...}]}
/// 该页比低保/特困多渲染一个 subsidy_type（救助类型）字段。
void main() {
  ensureTestBinding();

  const periodsPath = '/api/pension_insurance/periods';
  const queryPath = '/api/pension_insurance';

  final sampleRecords = [
    {
      'period': '202501',
      'name': '孙七',
      'id_card': '110101196203034567',
      'bank_account': '6217000111122223333',
      'amount': '148.00',
      'payment_status': '支付成功',
      'subsidy_type': '城乡居民养老保险',
    },
    {
      'period': '202501',
      'name': '周八',
      'id_card': '110101196505056789',
      'bank_account': '6217000555566667777',
      'amount': '148.00',
      'payment_status': '发放中',
    },
  ];

  Widget buildHome() => const MaterialApp(home: MonthlyPaymentQueryPage());

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
  });

  testWidgets('初始加载期数后渲染筛选表单与默认提示', (tester) async {
    final rec = installMockAdapter((options) {
      if (options.path == periodsPath) {
        return jsonResponse({
          'periods': ['202501', '202502'],
        });
      }
      return jsonResponse({'records': []});
    });

    await tester.pumpWidget(buildHome());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('养老保险查询'), findsOneWidget);
    expect(find.text('费款所属期'), findsOneWidget);
    expect(find.text('身份证号'), findsOneWidget);
    expect(find.text('姓名'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '查询'), findsOneWidget);
    expect(find.text('输入条件后点击查询'), findsOneWidget);
    expect(rec.wherePath(periodsPath), isNotEmpty);
  });

  testWidgets('期数未返回时空条件点击查询弹出提示 SnackBar', (tester) async {
    final periodsGate = Completer<ResponseBody>();
    installMockAdapter((options) {
      if (options.path == periodsPath) return periodsGate.future;
      return jsonResponse({'records': []});
    });

    await tester.pumpWidget(buildHome());
    await tester.pump();

    await tester.tap(find.text('查询'));
    await tester.pump();
    expect(find.text('请输入身份证号/姓名或选择月份'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump();

    periodsGate.complete(jsonResponse({
      'periods': ['202501'],
    }));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('输入姓名查询后渲染打款结果卡片与救助类型', (tester) async {
    final rec = installMockAdapter((options) {
      if (options.path == periodsPath) {
        return jsonResponse({
          'periods': ['202501', '202502'],
        });
      }
      if (options.path == queryPath) {
        return jsonResponse({'records': sampleRecords});
      }
      return jsonResponse({'records': []});
    });

    await tester.pumpWidget(buildHome());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).at(1), '孙七');
    await tester.tap(find.text('查询'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 姓名既出现在结果卡片，也残留在上方姓名输入框里，故限定到结果 ListView 内断言
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('孙七')),
      findsOneWidget,
    );
    expect(find.text('周八'), findsOneWidget);
    expect(find.textContaining('身份证号：110101196203034567'), findsOneWidget);
    expect(find.textContaining('银行账号：6217000111122223333'), findsOneWidget);
    expect(find.text('金额：148.00 元'), findsNWidgets(2));
    expect(find.text('2025年01月'), findsNWidgets(2));
    expect(find.text('支付成功'), findsOneWidget);
    expect(find.text('发放中'), findsOneWidget);
    // 仅第一条带 subsidy_type
    expect(find.textContaining('救助类型：城乡居民养老保险'), findsOneWidget);

    final queryCalls = rec.requests.where((r) => r.path == queryPath).toList();
    expect(queryCalls, isNotEmpty);
    expect(queryCalls.last.queryParameters['name'], '孙七');
    expect(queryCalls.last.queryParameters.containsKey('period'), isFalse);
  });

  testWidgets('选择期数后查询请求携带 period 参数', (tester) async {
    final rec = installMockAdapter((options) {
      if (options.path == periodsPath) {
        return jsonResponse({
          'periods': ['202501', '202502'],
        });
      }
      if (options.path == queryPath) {
        return jsonResponse({'records': [sampleRecords[0]]});
      }
      return jsonResponse({'records': []});
    });

    await tester.pumpWidget(buildHome());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pump();
    await tester.tap(find.text('2025年01月'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('查询'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final queryCalls = rec.requests.where((r) => r.path == queryPath).toList();
    expect(queryCalls, isNotEmpty);
    expect(queryCalls.last.queryParameters['period'], '202501');
    expect(find.text('孙七'), findsOneWidget);
  });

  testWidgets('查询无结果显示空态文案', (tester) async {
    installMockAdapter((options) {
      if (options.path == periodsPath) {
        return jsonResponse({
          'periods': ['202501'],
        });
      }
      if (options.path == queryPath) return jsonResponse({'records': []});
      return jsonResponse({'records': []});
    });

    await tester.pumpWidget(buildHome());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).at(0), '999');
    await tester.tap(find.text('查询'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('未找到打款记录'), findsOneWidget);
  });

  testWidgets('查询接口500时弹出查询失败SnackBar并落空态', (tester) async {
    installMockAdapter((options) {
      if (options.path == periodsPath) {
        return jsonResponse({
          'periods': ['202501'],
        });
      }
      if (options.path == queryPath) {
        return jsonResponse({}, statusCode: 500);
      }
      return jsonResponse({'records': []});
    });

    await tester.pumpWidget(buildHome());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField).at(1), '孙七');
    await tester.tap(find.text('查询'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // queryPensionInsurance 已上抛异常（BUG-07），页面 catch 生效：
    // 弹“查询失败”SnackBar，同时 _results 置空 → 结果区仍显示空态文案。
    expect(find.textContaining('查询失败'), findsOneWidget);
    expect(find.text('未找到打款记录'), findsOneWidget);

    // 让 SnackBar 定时器走完，避免测试结束时残留 pending timer。
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });
}
