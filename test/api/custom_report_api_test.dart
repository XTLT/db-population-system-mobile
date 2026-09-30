// CustomReportApi 单元测试（传输层 mock）
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/api/custom_report_api.dart';
import 'package:population_mobile/models/custom_report.dart';

import '../test_helpers.dart';

Map<String, dynamic> _reportJson(String id) => {
      'id': id,
      'title': '人口报表$id',
      'user_id': 'u1',
      'report_type': 'person',
      'dimensions': ['age'],
      'date_range': {'start': '2024-01-01', 'end': '2024-12-31'},
      'chart_type': 'bar',
      'filters': {'village': '甲村'},
      'created_at': '2024-01-01 10:00:00',
    };

void main() {
  ensureTestBinding();

  group('CustomReportApi.createReport', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async {
        if (options.path == '/api/reports/custom' && options.method == 'POST') {
          return jsonResponse({'success': true, 'report': _reportJson('r1')});
        }
        return jsonResponse({}, statusCode: 404);
      });
    });

    test('POST /api/reports/custom 携带全部字段，返回 CustomReport', () async {
      final r = await CustomReportApi.createReport(
        title: '人口报表r1',
        reportType: 'person',
        dimensions: const ['age'],
        dateRange: const {'start': '2024-01-01'},
        chartType: 'bar',
        filters: const {'village': '甲村'},
      );
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/reports/custom');
      expect(req.data['title'], '人口报表r1');
      expect(req.data['report_type'], 'person');
      expect(req.data['dimensions'], ['age']);
      expect(req.data['chart_type'], 'bar');
      expect(r, isA<CustomReport>());
      expect(r.id, 'r1');
      expect(r.reportTypeDisplayName, '人口统计');
    });

    test('success 非 true 时抛异常', () async {
      installMockAdapter((options) async =>
          jsonResponse({'success': false, 'report': null}));
      expect(
        CustomReportApi.createReport(title: 't', reportType: 'person'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('创建报表失败'))),
      );
    });

    test('500 带 error 时抛出 error 文本', () async {
      installMockAdapter((options) async =>
          jsonResponse({'error': '无报表权限'}, statusCode: 500));
      expect(
        CustomReportApi.createReport(title: 't', reportType: 'person'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('无报表权限'))),
      );
    });
  });

  group('CustomReportApi.getReports', () {
    late RequestRecorder rec;
    setUp(() => resetApiClientState());

    test('带 reportType 时 query 含 report_type 与 limit', () async {
      rec = installMockAdapter((options) async => jsonResponse({
            'reports': [_reportJson('r1'), _reportJson('r2')],
          }));
      final list = await CustomReportApi.getReports(
          reportType: 'person', limit: 20);
      final req = rec.last()!;
      expect(req.method, 'GET');
      expect(req.path, '/api/reports/custom');
      expect(req.queryParameters['report_type'], 'person');
      expect(req.queryParameters['limit'], 20);
      expect(list, hasLength(2));
      expect(list[0].id, 'r1');
    });

    test('reportType 为空串时不发送 report_type', () async {
      rec = installMockAdapter((options) async => jsonResponse({'reports': []}));
      await CustomReportApi.getReports(reportType: '', limit: 50);
      expect(rec.last()!.queryParameters.containsKey('report_type'), isFalse);
      expect(rec.last()!.queryParameters['limit'], 50);
    });

    test('reports 缺省返回空列表', () async {
      installMockAdapter((options) async => jsonResponse({}));
      expect(await CustomReportApi.getReports(), isEmpty);
    });
  });

  group('CustomReportApi.getReport', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async =>
          jsonResponse({'report': _reportJson('r9')}));
    });

    test('GET /api/reports/custom/r9 解析 report', () async {
      final r = await CustomReportApi.getReport('r9');
      expect(rec.last()!.method, 'GET');
      expect(rec.last()!.path, '/api/reports/custom/r9');
      expect(r.id, 'r9');
    });

    test('500 且错误体无 error 字段时抛出网络错误提示', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      // 源码 on DioException：errorData['error'] 为 null → 抛 '网络错误，请检查网络连接'
      expect(
        () => CustomReportApi.getReport('r9'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('网络错误'))),
      );
    });

    test('500 且错误体带 error 字段时抛出服务端 error 文案', () async {
      installMockAdapter((options) async =>
          jsonResponse({'error': '无报表权限'}, statusCode: 500));
      expect(
        () => CustomReportApi.getReport('r9'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('无报表权限'))),
      );
    });
  });

  group('CustomReportApi.updateReport', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async =>
          jsonResponse({'success': true, 'report': _reportJson('r1')}));
    });

    test('PUT /api/reports/custom/r1 仅发送非空字段', () async {
      final r = await CustomReportApi.updateReport('r1', title: '新标题');
      final req = rec.last()!;
      expect(req.method, 'PUT');
      expect(req.path, '/api/reports/custom/r1');
      final data = req.data as Map;
      expect(data['title'], '新标题');
      expect(data.containsKey('report_type'), isFalse);
      expect(data.containsKey('filters'), isFalse);
      expect(r.id, 'r1');
    });

    test('success 非 true 时抛异常', () async {
      installMockAdapter((options) async =>
          jsonResponse({'success': false}));
      expect(
        CustomReportApi.updateReport('r1', title: 'x'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('更新报表失败'))),
      );
    });
  });

  group('CustomReportApi.deleteReport', () {
    late RequestRecorder rec;
    setUp(() => resetApiClientState());

    test('DELETE 且 success=true 返回 true', () async {
      rec = installMockAdapter(
          (options) async => jsonResponse({'success': true}));
      expect(await CustomReportApi.deleteReport('r1'), isTrue);
      expect(rec.last()!.method, 'DELETE');
      expect(rec.last()!.path, '/api/reports/custom/r1');
    });

    test('success=false 返回 false', () async {
      installMockAdapter(
          (options) async => jsonResponse({'success': false}));
      expect(await CustomReportApi.deleteReport('r1'), isFalse);
    });
  });

  group('CustomReportApi.generateReport', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async =>
          jsonResponse({'rows': 100, 'columns': ['age', 'count']}));
    });

    test('POST /api/reports/generate 携带参数并透传 data', () async {
      final r = await CustomReportApi.generateReport(
        reportType: 'person',
        dimensions: const ['age'],
        dateRange: const {'start': '2024-01-01'},
        filters: const {'village': '甲村'},
      );
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/reports/generate');
      expect(req.data['report_type'], 'person');
      expect(req.data['dimensions'], ['age']);
      expect(req.data['date_range'], {'start': '2024-01-01'});
      expect(r['rows'], 100);
    });
  });
}
