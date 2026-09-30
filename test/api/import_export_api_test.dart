// ImportExportApi 单元测试（传输层 mock + path_provider 通道 mock）
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/api/import_export_api.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  late Directory tmpDir;

  setUp(() async {
    resetApiClientState();
    tmpDir = await Directory.systemTemp.createTemp('ie_api_test');
    // mock path_provider：getTemporaryDirectory 返回本用例专用临时目录
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        if (call.method == 'getTemporaryDirectory') return tmpDir.path;
        return null;
      },
    );
  });

  group('ImportExportApi.importPersonExcel', () {
    late File uploadFile;
    setUp(() async {
      uploadFile = File('${tmpDir.path}/person.xlsx');
      await uploadFile.writeAsBytes([1, 2, 3, 4]);
    });

    test('POST /api/import/excel 以 FormData 携带 file 与 mode，返回解析后的 map',
        () async {
      final rec = installMockAdapter((options) async {
        if (options.path == '/api/import/excel') {
          return jsonResponse({'imported': 5, 'failed': 0});
        }
        return jsonResponse({}, statusCode: 404);
      });

      final r = await ImportExportApi.importPersonExcel(uploadFile,
          mode: 'overwrite');
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/import/excel');
      expect(req.data, isA<FormData>());
      final form = req.data as FormData;
      expect(form.fields.any((e) => e.key == 'mode' && e.value == 'overwrite'),
          isTrue);
      expect(form.files.any((e) => e.key == 'file'), isTrue);
      expect(r['imported'], 5);
    });

    test('默认 mode 为 incremental', () async {
      final rec = installMockAdapter(
          (options) async => jsonResponse({'imported': 1}));
      await ImportExportApi.importPersonExcel(uploadFile);
      final form = rec.last()!.data as FormData;
      expect(
          form.fields.any((e) => e.key == 'mode' && e.value == 'incremental'),
          isTrue);
    });

    test('500 带 error 时抛出导入失败信息', () async {
      installMockAdapter((options) async =>
          jsonResponse({'error': '文件格式不支持'}, statusCode: 500));
      expect(
        ImportExportApi.importPersonExcel(uploadFile),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('文件格式不支持'))),
      );
    });
  });

  group('ImportExportApi.exportPersonExcel', () {
    test('POST /api/export/excel 携带 password，bytes 写入临时文件并返回路径',
        () async {
      final rec = installMockAdapter((options) async {
        if (options.path == '/api/export/excel') {
          return ResponseBody.fromString('PK\x03\x04binary', 200, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          });
        }
        return jsonResponse({}, statusCode: 404);
      });

      final path = await ImportExportApi.exportPersonExcel(password: 'pwd');
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/export/excel');
      expect(req.data['password'], 'pwd');
      expect(req.data.containsKey('filters'), isFalse);
      expect(path, contains('person_export_'));
      expect(path, endsWith('.xlsx'));
      expect(File(path).existsSync(), isTrue);
    });

    test('传入 filters 时 body 包含 filters', () async {
      final rec = installMockAdapter((options) async =>
          ResponseBody.fromString('x', 200, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          }));
      await ImportExportApi.exportPersonExcel(
          password: 'pwd', filters: {'village': '甲村'});
      expect(rec.last()!.data['filters'], {'village': '甲村'});
    });

    test('500 时 responseType.bytes 错误体被 utf8 解码后取出服务端 error',
        () async {
      installMockAdapter((options) async =>
          jsonResponse({'error': '密码错误'}, statusCode: 500));
      // responseType.bytes 下 e.response.data 是 Uint8List（List<int>），
      // 修复后先 utf8.decode + jsonDecode，从中取出服务端 JSON 的 error 字段。
      expect(
        () => ImportExportApi.exportPersonExcel(password: 'wrong'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('密码错误'))),
      );
    });
  });

  group('ImportExportApi.exportStudentExcel', () {
    test('POST /api/students/export 写 student_export 文件', () async {
      final rec = installMockAdapter((options) async =>
          ResponseBody.fromString('bytes', 200, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          }));
      final path =
          await ImportExportApi.exportStudentExcel(password: 'spwd');
      expect(rec.last()!.method, 'POST');
      expect(rec.last()!.path, '/api/students/export');
      expect(rec.last()!.data['password'], 'spwd');
      expect(path, contains('student_export_'));
      expect(File(path).existsSync(), isTrue);
    });
  });

  group('ImportExportApi.importStudentExcel', () {
    late File uploadFile;
    setUp(() async {
      uploadFile = File('${tmpDir.path}/student.xlsx');
      await uploadFile.writeAsBytes([9, 9, 9]);
    });

    test('POST /api/students/import 以 FormData 携带 file', () async {
      final rec = installMockAdapter(
          (options) async => jsonResponse({'imported': 2}));
      final r = await ImportExportApi.importStudentExcel(uploadFile);
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/students/import');
      expect((req.data as FormData).files.any((e) => e.key == 'file'), isTrue);
      expect(r['imported'], 2);
    });

    test('500 带 error 时抛出导入失败信息', () async {
      installMockAdapter((options) async =>
          jsonResponse({'error': '表头缺失'}, statusCode: 500));
      expect(
        ImportExportApi.importStudentExcel(uploadFile),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('表头缺失'))),
      );
    });
  });

  group('ImportExportApi.downloadPersonTemplate', () {
    test('GET /api/template/excel 写 person_import_template.xlsx', () async {
      final rec = installMockAdapter((options) async =>
          ResponseBody.fromString('tpl', 200, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          }));
      final path = await ImportExportApi.downloadPersonTemplate();
      expect(rec.last()!.method, 'GET');
      expect(rec.last()!.path, '/api/template/excel');
      expect(path, endsWith('person_import_template.xlsx'));
      expect(File(path).existsSync(), isTrue);
    });
  });

  group('ImportExportApi.downloadStudentTemplate', () {
    test('GET /api/template/student 写 student_import_template.xlsx', () async {
      final rec = installMockAdapter((options) async =>
          ResponseBody.fromString('tpl', 200, headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          }));
      final path = await ImportExportApi.downloadStudentTemplate();
      expect(rec.last()!.method, 'GET');
      expect(rec.last()!.path, '/api/template/student');
      expect(path, endsWith('student_import_template.xlsx'));
      expect(File(path).existsSync(), isTrue);
    });
  });
}
