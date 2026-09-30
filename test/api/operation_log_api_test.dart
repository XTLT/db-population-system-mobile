// OperationLogApi 单元测试（传输层 mock）
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/api/operation_log_api.dart';
import 'package:population_mobile/models/operation_log.dart';

import '../test_helpers.dart';

Map<String, dynamic> _logJson(String id) => {
      'id': id,
      'username': 'admin',
      'operation_type': 'create',
      'operation_target': 'person:110',
      'ip_address': '127.0.0.1',
      'client_type': 'web',
      'created_at': '2024-01-01 10:00:00',
      'is_high_risk': '否',
    };

void main() {
  ensureTestBinding();

  group('OperationLogApi.getOperationLogs', () {
    late RequestRecorder rec;
    setUp(() => resetApiClientState());

    test('GET /api/logs 携带全部过滤条件，响应为顶层数组', () async {
      rec = installMockAdapter((options) async =>
          jsonResponse([_logJson('1'), _logJson('2')]));
      final list = await OperationLogApi.getOperationLogs(
        limit: 50,
        username: 'admin',
        operationType: 'create',
        startDate: '2024-01-01',
        endDate: '2024-12-31',
      );
      final req = rec.last()!;
      expect(req.method, 'GET');
      expect(req.path, '/api/logs');
      expect(req.queryParameters['limit'], 50);
      expect(req.queryParameters['username'], 'admin');
      expect(req.queryParameters['operation_type'], 'create');
      expect(req.queryParameters['start_date'], '2024-01-01');
      expect(req.queryParameters['end_date'], '2024-12-31');
      expect(list, hasLength(2));
      expect(list[0], isA<OperationLog>());
      expect(list[0].operationType, 'create');
    });

    test('仅 limit 时其余条件不入 query', () async {
      rec = installMockAdapter((options) async => jsonResponse([]));
      await OperationLogApi.getOperationLogs(limit: 200);
      final q = rec.last()!.queryParameters;
      expect(q['limit'], 200);
      expect(q.containsKey('username'), isFalse);
      expect(q.containsKey('operation_type'), isFalse);
      expect(q.containsKey('start_date'), isFalse);
      expect(q.containsKey('end_date'), isFalse);
    });

    test('空串过滤条件不入 query', () async {
      rec = installMockAdapter((options) async => jsonResponse([]));
      await OperationLogApi.getOperationLogs(username: '', operationType: '');
      final q = rec.last()!.queryParameters;
      expect(q.containsKey('username'), isFalse);
      expect(q.containsKey('operation_type'), isFalse);
    });

    // 非 200（201 仍被 dio 放行进入 else 分支）时，错误消息应真实插值状态码。
    test('非 200（201）错误文本包含真实状态码', () async {
      installMockAdapter((options) async =>
          jsonResponse([], statusCode: 201));
      expect(
        OperationLogApi.getOperationLogs(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg',
            contains('获取操作日志失败: 201'))),
      );
    });

    test('500 网络错误时抛异常', () async {
      installMockAdapter(
          (options) async => jsonResponse([], statusCode: 500));
      expect(
        OperationLogApi.getOperationLogs(),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('获取操作日志失败'))),
      );
    });
  });

  group('OperationLogApi.getOperationTypes', () {
    late RequestRecorder rec;
    setUp(() => resetApiClientState());

    test('GET /api/logs/types 返回 types 列表', () async {
      rec = installMockAdapter(
          (options) async => jsonResponse({'types': ['create', 'update', 'delete']}));
      final types = await OperationLogApi.getOperationTypes();
      expect(rec.last()!.method, 'GET');
      expect(rec.last()!.path, '/api/logs/types');
      expect(types, ['create', 'update', 'delete']);
    });

    test('types 缺省返回空列表', () async {
      installMockAdapter((options) async => jsonResponse({}));
      expect(await OperationLogApi.getOperationTypes(), isEmpty);
    });

    test('非 200（201）静默返回空列表而非抛异常', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 201));
      expect(await OperationLogApi.getOperationTypes(), isEmpty);
    });

    test('500 异常时静默返回空列表', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(await OperationLogApi.getOperationTypes(), isEmpty);
    });
  });

  group('OperationLogApi.getOperationLogStats', () {
    late RequestRecorder rec;
    setUp(() => resetApiClientState());

    test('GET /api/logs/stats 透传 data', () async {
      rec = installMockAdapter((options) async =>
          jsonResponse({'total': 100, 'high_risk': 3}));
      final s = await OperationLogApi.getOperationLogStats();
      expect(rec.last()!.method, 'GET');
      expect(rec.last()!.path, '/api/logs/stats');
      expect(s['total'], 100);
      expect(s['high_risk'], 3);
    });

    // 第 60 行修复后同样插值真实状态码。
    test('非 200（201）错误文本包含真实状态码', () async {
      installMockAdapter((options) async =>
          jsonResponse({}, statusCode: 201));
      expect(
        OperationLogApi.getOperationLogStats(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg',
            contains('获取统计失败: 201'))),
      );
    });
  });
}
