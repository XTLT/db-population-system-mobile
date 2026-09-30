// BatchOperationApi 单元测试（传输层 mock）
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/api/batch_operation_api.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  group('BatchOperationApi.batchDeletePersons', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async {
        if (options.path == '/api/persons/batch-delete') {
          return jsonResponse({'deleted': 2, 'success': true});
        }
        return jsonResponse({}, statusCode: 404);
      });
    });

    test('POST /api/persons/batch-delete 携带 ids 并透传 data', () async {
      final r = await BatchOperationApi.batchDeletePersons(['1', '2']);
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/persons/batch-delete');
      expect(req.data['ids'], ['1', '2']);
      expect(r['deleted'], 2);
    });

    test('服务端 500 且带 error 时抛出 error 文本', () async {
      installMockAdapter((options) async =>
          jsonResponse({'error': '部分人员已被引用'}, statusCode: 500));
      expect(
        BatchOperationApi.batchDeletePersons(['1']),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('部分人员已被引用'))),
      );
    });

    test('500 且无 error 字段时给出通用批量删除失败提示', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        BatchOperationApi.batchDeletePersons(['1']),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('批量删除失败'))),
      );
    });
  });

  group('BatchOperationApi.batchUpdatePersons', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async =>
          jsonResponse({'updated': 1, 'success': true}));
    });

    test('POST /api/persons/batch-update 携带 ids 与 updates', () async {
      final updates = {'dibao': '是'};
      final r = await BatchOperationApi.batchUpdatePersons(['1', '3'], updates);
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/persons/batch-update');
      expect(req.data['ids'], ['1', '3']);
      expect(req.data['updates'], updates);
      expect(r['updated'], 1);
    });

    test('500 带 error 时抛出 error 文本', () async {
      installMockAdapter((options) async =>
          jsonResponse({'error': '字段不允许批量修改'}, statusCode: 500));
      expect(
        BatchOperationApi.batchUpdatePersons(['1'], {}),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('字段不允许批量修改'))),
      );
    });
  });

  group('BatchOperationApi.batchDeleteStudents', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async =>
          jsonResponse({'deleted': 1, 'success': true}));
    });

    test('POST /api/students/batch-delete 携带 ids', () async {
      final r = await BatchOperationApi.batchDeleteStudents(['s1']);
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/students/batch-delete');
      expect(req.data['ids'], ['s1']);
      expect(r['deleted'], 1);
    });

    test('500 无 error 时给出学生删除失败提示', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        BatchOperationApi.batchDeleteStudents(['s1']),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('批量删除学生失败'))),
      );
    });
  });

  group('BatchOperationApi.batchUpdateStudents', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async =>
          jsonResponse({'updated': 2, 'success': true}));
    });

    test('POST /api/students/batch-update 携带 ids 与 updates', () async {
      final updates = {'grade': 'G6'};
      final r =
          await BatchOperationApi.batchUpdateStudents(['s1', 's2'], updates);
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/students/batch-update');
      expect(req.data['ids'], ['s1', 's2']);
      expect(req.data['updates'], updates);
      expect(r['updated'], 2);
    });

    test('500 带 error 时抛出 error 文本', () async {
      installMockAdapter((options) async =>
          jsonResponse({'error': '权限不足'}, statusCode: 500));
      expect(
        BatchOperationApi.batchUpdateStudents(['s1'], {}),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('权限不足'))),
      );
    });
  });

  group('BatchOperationApi.batchDeletePhotos', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async =>
          jsonResponse({'deleted': 1, 'success': true}));
    });

    test('POST /api/photos/batch-delete 携带 photos 列表', () async {
      final photos = [
        {'id_card': '110', 'type': 'id_card_front'},
      ];
      final r = await BatchOperationApi.batchDeletePhotos(photos);
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/photos/batch-delete');
      expect(req.data['photos'], photos);
      expect(r['deleted'], 1);
    });

    test('500 无 error 时给出照片删除失败提示', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        BatchOperationApi.batchDeletePhotos(const []),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('批量删除照片失败'))),
      );
    });
  });
}
