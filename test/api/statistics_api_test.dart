import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/api/statistics_api.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
  });

  // ------------------------------------------------------------------
  // 1-2. 两个整体统计（透传 Map，错误时抛异常）
  // ------------------------------------------------------------------
  group('getPersonStatistics / getStudentStatistics', () {
    test('getPersonStatistics: GET /api/statistics，透传 data', () async {
      final rec = installMockAdapter((o) => jsonResponse({'total': 1200}));
      final m = await StatisticsApi.getPersonStatistics();
      expect(rec.last()!.path, '/api/statistics');
      expect(rec.last()!.method, 'GET');
      expect(m['total'], 1200);
    });

    test('getPersonStatistics: HTTP 500 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getPersonStatistics(), throwsA(isA<Exception>()));
    });

    test('getStudentStatistics: GET /api/students/statistics，透传 data', () async {
      final rec = installMockAdapter((o) => jsonResponse({'count': 33}));
      final m = await StatisticsApi.getStudentStatistics();
      expect(rec.last()!.path, '/api/students/statistics');
      expect(m['count'], 33);
    });

    test('getStudentStatistics: HTTP 500 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getStudentStatistics(), throwsA(isA<Exception>()));
    });
  });

  // ------------------------------------------------------------------
  // 3-4. 年龄/村分布（List<Map>，非 200/异常抛 Exception）
  // ------------------------------------------------------------------
  group('getAgeDistribution / getVillageStatistics', () {
    test('getAgeDistribution: GET /api/statistics/age_distribution，解析 data.distribution', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'distribution': [
              {'range': '0-18', 'count': 100},
              {'range': '19-35', 'count': 200},
            ],
          }));
      final list = await StatisticsApi.getAgeDistribution();
      expect(rec.last()!.path, '/api/statistics/age_distribution');
      expect(list.length, 2);
      expect(list[0]['range'], '0-18');
    });

    test('getAgeDistribution: 非 200 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getAgeDistribution(), throwsA(isA<Exception>()));
    });

    test('getVillageStatistics: GET /api/statistics/by_village，解析 data.villages', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'villages': [{'name': '一村', 'count': 10}],
          }));
      final list = await StatisticsApi.getVillageStatistics();
      expect(rec.last()!.path, '/api/statistics/by_village');
      expect(list.length, 1);
      expect(list[0]['name'], '一村');
    });

    test('getVillageStatistics: 异常抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getVillageStatistics(), throwsA(isA<Exception>()));
    });
  });

  // ------------------------------------------------------------------
  // 5-7. 趋势/分布/对比（透传 Map，错误抛异常）
  // ------------------------------------------------------------------
  group('getTrendData / getDistribution / getComparison', () {
    test('getTrendData: GET /api/statistics/trend，默认 group_by=month', () async {
      final rec = installMockAdapter((o) => jsonResponse({'points': []}));
      await StatisticsApi.getTrendData();
      final q = rec.last()!.queryParameters;
      expect(rec.last()!.path, '/api/statistics/trend');
      expect(q['group_by'], 'month');
      expect(q.containsKey('start_date'), false);
      expect(q.containsKey('end_date'), false);
    });

    test('getTrendData: 传起止日期时拼装 start_date/end_date/group_by', () async {
      final rec = installMockAdapter((o) => jsonResponse({}));
      await StatisticsApi.getTrendData(
        startDate: '2024-01-01',
        endDate: '2024-12-31',
        groupBy: 'year',
      );
      final q = rec.last()!.queryParameters;
      expect(q['start_date'], '2024-01-01');
      expect(q['end_date'], '2024-12-31');
      expect(q['group_by'], 'year');
    });

    test('getTrendData: 非 200 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getTrendData(), throwsA(isA<Exception>()));
    });

    test('getDistribution: GET /api/statistics/distribution?field=gender，解析为 Map<String,int>', () async {
      final rec = installMockAdapter((o) => jsonResponse({'male': 60, 'female': 40}));
      final m = await StatisticsApi.getDistribution('gender');
      expect(rec.last()!.path, '/api/statistics/distribution');
      expect(rec.last()!.queryParameters['field'], 'gender');
      expect(m['male'], 60);
      expect(m['female'], 40);
    });

    test('getDistribution: 非 200 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getDistribution('x'), throwsA(isA<Exception>()));
    });

    test('getComparison: 无 dimensions 时不发送该参数', () async {
      final rec = installMockAdapter((o) => jsonResponse({}));
      await StatisticsApi.getComparison();
      expect(rec.last()!.path, '/api/statistics/comparison');
      expect(rec.last()!.queryParameters.containsKey('dimensions'), false);
    });

    test('getComparison: 传 dimensions 时进入 query', () async {
      final rec = installMockAdapter((o) => jsonResponse({}));
      await StatisticsApi.getComparison(dimensions: ['village', 'age']);
      expect(rec.last()!.queryParameters['dimensions'], ['village', 'age']);
    });

    test('getComparison: 非 200 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getComparison(), throwsA(isA<Exception>()));
    });
  });

  // ------------------------------------------------------------------
  // 8. 地力补贴统计
  // ------------------------------------------------------------------
  group('getLandSubsidyStatistics', () {
    test('不传 year：query 为空，GET /api/land_subsidy/statistics', () async {
      final rec = installMockAdapter((o) => jsonResponse({'total': 1}));
      await StatisticsApi.getLandSubsidyStatistics();
      expect(rec.last()!.path, '/api/land_subsidy/statistics');
      expect(rec.last()!.queryParameters.isEmpty, true);
    });

    test('传 year：拼装 year', () async {
      final rec = installMockAdapter((o) => jsonResponse({}));
      await StatisticsApi.getLandSubsidyStatistics(year: '2024');
      expect(rec.last()!.queryParameters['year'], '2024');
    });

    test('非 200 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getLandSubsidyStatistics(), throwsA(isA<Exception>()));
    });
  });

  // ------------------------------------------------------------------
  // 9-10. 年份列表（List<String>，错误抛 Exception —— 已与全文件错误策略统一）
  // ------------------------------------------------------------------
  group('getTreatmentPaymentYears / getPensionInsuranceYears', () {
    test('getTreatmentPaymentYears: GET /api/treatment_payment/years，解析 data.years', () async {
      final rec = installMockAdapter((o) => jsonResponse({'years': ['2022', '2023', '2024']}));
      final list = await StatisticsApi.getTreatmentPaymentYears();
      expect(rec.last()!.path, '/api/treatment_payment/years');
      expect(list, ['2022', '2023', '2024']);
    });

    test('getTreatmentPaymentYears: years 缺省返回空 List<String>', () async {
      installMockAdapter((o) => jsonResponse({}));
      expect(await StatisticsApi.getTreatmentPaymentYears(), isEmpty);
    });

    test('getTreatmentPaymentYears: 非 200 抛 Exception（单层干净消息，不再双重包装）', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getTreatmentPaymentYears(), throwsA(isA<Exception>()));
    });

    test('getPensionInsuranceYears: GET /api/pension_insurance/years，解析 data.years', () async {
      final rec = installMockAdapter((o) => jsonResponse({'years': ['2024']}));
      final list = await StatisticsApi.getPensionInsuranceYears();
      expect(rec.last()!.path, '/api/pension_insurance/years');
      expect(list, ['2024']);
    });

    test('getPensionInsuranceYears: 非 200 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getPensionInsuranceYears(), throwsA(isA<Exception>()));
    });
  });

  // ------------------------------------------------------------------
  // 11-12. 待遇/养老 periods（List<String>，错误抛 Exception）
  // ------------------------------------------------------------------
  group('getTreatmentPaymentPeriods / getPensionInsurancePeriods', () {
    test('getTreatmentPaymentPeriods: GET .../periods，解析 data.periods', () async {
      final rec = installMockAdapter((o) => jsonResponse({'periods': ['2024-01', '2024-02']}));
      final list = await StatisticsApi.getTreatmentPaymentPeriods();
      expect(rec.last()!.path, '/api/treatment_payment/periods');
      expect(list, ['2024-01', '2024-02']);
    });

    test('getTreatmentPaymentPeriods: 非 200 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getTreatmentPaymentPeriods(), throwsA(isA<Exception>()));
    });

    test('getPensionInsurancePeriods: GET .../periods，解析 data.periods', () async {
      final rec = installMockAdapter((o) => jsonResponse({'periods': ['2024-03']}));
      final list = await StatisticsApi.getPensionInsurancePeriods();
      expect(rec.last()!.path, '/api/pension_insurance/periods');
      expect(list, ['2024-03']);
    });

    test('getPensionInsurancePeriods: 异常抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getPensionInsurancePeriods(), throwsA(isA<Exception>()));
    });
  });

  // ------------------------------------------------------------------
  // 13-14. 待遇/养老查询（List<Map>，period=全部 时不带 period）
  // ------------------------------------------------------------------
  group('queryTreatmentPayments / queryPensionInsurance', () {
    test('queryTreatmentPayments: GET /api/treatment_payment，拼装 period/id_card/name，解析 data.payments', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'payments': [{'id_card': '110', 'amount': 120.5}],
          }));
      final list = await StatisticsApi.queryTreatmentPayments(
        period: '2024-01',
        idCard: '110',
        name: '张三',
      );
      final q = rec.last()!.queryParameters;
      expect(rec.last()!.path, '/api/treatment_payment');
      expect(q['period'], '2024-01');
      expect(q['id_card'], '110');
      expect(q['name'], '张三');
      expect(list.length, 1);
      expect(list[0]['amount'], 120.5);
    });

    test('queryTreatmentPayments: period=「全部」时不发送 period 字段', () async {
      final rec = installMockAdapter((o) => jsonResponse({'payments': []}));
      await StatisticsApi.queryTreatmentPayments(period: '全部', name: '张三');
      final q = rec.last()!.queryParameters;
      expect(q.containsKey('period'), false);
      expect(q['name'], '张三');
    });

    test('queryTreatmentPayments: 非 200 抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.queryTreatmentPayments(), throwsA(isA<Exception>()));
    });

    test('queryPensionInsurance: GET /api/pension_insurance，解析 data.records', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'records': [{'id_card': 'X', 'months': 12}],
          }));
      final list = await StatisticsApi.queryPensionInsurance(period: '2024-01');
      expect(rec.last()!.path, '/api/pension_insurance');
      expect(rec.last()!.queryParameters['period'], '2024-01');
      expect(list.length, 1);
      expect(list[0]['months'], 12);
    });

    test('queryPensionInsurance: period=「全部」不带 period；异常抛 Exception', () async {
      final rec = installMockAdapter((o) => jsonResponse({'records': []}));
      await StatisticsApi.queryPensionInsurance(period: '全部');
      expect(rec.last()!.queryParameters.containsKey('period'), false);

      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.queryPensionInsurance(), throwsA(isA<Exception>()));
    });
  });

  // ------------------------------------------------------------------
  // 15-18. 低保 / 特困 periods + 查询
  // ------------------------------------------------------------------
  group('dibao / tekun periods & queries', () {
    test('getDibaoPaymentPeriods: GET /api/dibao_payment/periods', () async {
      final rec = installMockAdapter((o) => jsonResponse({'periods': ['2024-01']}));
      expect(await StatisticsApi.getDibaoPaymentPeriods(), ['2024-01']);
      expect(rec.last()!.path, '/api/dibao_payment/periods');
    });

    test('getTekunPaymentPeriods: GET /api/tekun_payment/periods', () async {
      final rec = installMockAdapter((o) => jsonResponse({'periods': ['2024-02']}));
      expect(await StatisticsApi.getTekunPaymentPeriods(), ['2024-02']);
      expect(rec.last()!.path, '/api/tekun_payment/periods');
    });

    test('periods 类方法异常均抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getDibaoPaymentPeriods(), throwsA(isA<Exception>()));
      expect(() => StatisticsApi.getTekunPaymentPeriods(), throwsA(isA<Exception>()));
    });

    test('queryDibaoPayments: GET /api/dibao_payment，解析 data.records', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'records': [{'name': '低保户'}],
          }));
      final list = await StatisticsApi.queryDibaoPayments(period: '2024-01', name: '低保户');
      expect(rec.last()!.path, '/api/dibao_payment');
      expect(rec.last()!.queryParameters['period'], '2024-01');
      expect(rec.last()!.queryParameters['name'], '低保户');
      expect(list.length, 1);
    });

    test('queryTekunPayments: GET /api/tekun_payment，解析 data.records', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'records': [{'name': '特困户'}],
          }));
      final list = await StatisticsApi.queryTekunPayments(idCard: 'X');
      expect(rec.last()!.path, '/api/tekun_payment');
      expect(rec.last()!.queryParameters['id_card'], 'X');
      expect(list.length, 1);
    });

    test('queryDibao/Tekun: period=全部 不带 period；异常抛 Exception', () async {
      final rec = installMockAdapter((o) => jsonResponse({'records': []}));
      await StatisticsApi.queryDibaoPayments(period: '全部');
      expect(rec.last()!.queryParameters.containsKey('period'), false);

      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.queryDibaoPayments(), throwsA(isA<Exception>()));
      expect(() => StatisticsApi.queryTekunPayments(), throwsA(isA<Exception>()));
    });
  });

  // ------------------------------------------------------------------
  // 19-20. 残疾人护理补贴 periods + 查询
  // ------------------------------------------------------------------
  group('disability care periods & query', () {
    test('getDisabilityCarePaymentPeriods: GET /api/disability_care_payment/periods', () async {
      final rec = installMockAdapter((o) => jsonResponse({'periods': ['2024-01']}));
      expect(await StatisticsApi.getDisabilityCarePaymentPeriods(), ['2024-01']);
      expect(rec.last()!.path, '/api/disability_care_payment/periods');
    });

    test('getDisabilityCarePaymentPeriods: 异常抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getDisabilityCarePaymentPeriods(), throwsA(isA<Exception>()));
    });

    test('queryDisabilityCarePayments: GET /api/disability_care_payment，records 为 List 才解析', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'records': [{'name': '残疾人'}],
          }));
      final list = await StatisticsApi.queryDisabilityCarePayments(name: '残疾人');
      expect(rec.last()!.path, '/api/disability_care_payment');
      expect(rec.last()!.queryParameters['name'], '残疾人');
      expect(list.length, 1);
    });

    test('queryDisabilityCarePayments: records 缺省/非 List 返回 []；异常抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({})); // records 为 null（200 成功但空结果）
      expect(await StatisticsApi.queryDisabilityCarePayments(), isEmpty);

      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.queryDisabilityCarePayments(), throwsA(isA<Exception>()));
    });
  });

  // ------------------------------------------------------------------
  // 21-22. 高龄补贴 periods + 查询
  // ------------------------------------------------------------------
  group('elderly allowance periods & query', () {
    test('getElderlyAllowancePeriods: GET /api/elderly_allowance/periods', () async {
      final rec = installMockAdapter((o) => jsonResponse({'periods': ['2024-01']}));
      expect(await StatisticsApi.getElderlyAllowancePeriods(), ['2024-01']);
      expect(rec.last()!.path, '/api/elderly_allowance/periods');
    });

    test('getElderlyAllowancePeriods: 异常抛 Exception', () async {
      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.getElderlyAllowancePeriods(), throwsA(isA<Exception>()));
    });

    test('queryElderlyAllowances: GET /api/elderly_allowance，records 为 List 才解析', () async {
      final rec = installMockAdapter((o) => jsonResponse({
            'records': [{'name': '老人'}],
          }));
      final list = await StatisticsApi.queryElderlyAllowances(idCard: 'E1');
      expect(rec.last()!.path, '/api/elderly_allowance');
      expect(rec.last()!.queryParameters['id_card'], 'E1');
      expect(list.length, 1);
    });

    test('queryElderlyAllowances: period=全部 不带 period；records 缺省返回 []，异常抛 Exception', () async {
      final rec = installMockAdapter((o) => jsonResponse({'records': []}));
      await StatisticsApi.queryElderlyAllowances(period: '全部');
      expect(rec.last()!.queryParameters.containsKey('period'), false);

      installMockAdapter((o) => jsonResponse({}, statusCode: 500));
      expect(() => StatisticsApi.queryElderlyAllowances(), throwsA(isA<Exception>()));
    });
  });
}
