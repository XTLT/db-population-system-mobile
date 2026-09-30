// BackupApi 单元测试（传输层 mock）
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/api/backup_api.dart';
import 'package:population_mobile/models/backup_info.dart';

import '../test_helpers.dart';

Map<String, dynamic> _backupJson(String name) => {
      'timestamp': '20240101_100000',
      'time': '2024-01-01 10:00:00',
      'name': name,
      'size': 2048,
      'encrypted': true,
      'manual': true,
    };

void main() {
  ensureTestBinding();

  group('BackupApi.createBackup', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async {
        if (options.path == '/api/backup' && options.method == 'POST') {
          return jsonResponse({'success': true, 'filename': 'bk_1.zip'});
        }
        return jsonResponse({}, statusCode: 404);
      });
    });

    test('POST /api/backup 透传响应 data', () async {
      final r = await BackupApi.createBackup();
      expect(rec.last()!.method, 'POST');
      expect(rec.last()!.path, '/api/backup');
      expect(r['filename'], 'bk_1.zip');
    });

    test('500 时抛异常', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        BackupApi.createBackup(),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('创建备份失败'))),
      );
    });
  });

  group('BackupApi.getBackupList', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async {
        if (options.path == '/api/backup/list') {
          return jsonResponse({
            'backups': [_backupJson('a.zip'), _backupJson('b.zip')],
          });
        }
        return jsonResponse({}, statusCode: 404);
      });
    });

    test('GET /api/backup/list 解析 BackupInfo，path 取自 name', () async {
      final list = await BackupApi.getBackupList();
      expect(rec.last()!.method, 'GET');
      expect(rec.last()!.path, '/api/backup/list');
      expect(list, hasLength(2));
      expect(list[0], isA<BackupInfo>());
      expect(list[0].path, 'a.zip'); // path 来自 JSON 的 name
      expect(list[0].size, 2048);
      expect(list[0].encrypted, isTrue);
    });

    test('backups 缺省返回空列表', () async {
      installMockAdapter((options) async => jsonResponse({}));
      expect(await BackupApi.getBackupList(), isEmpty);
    });
  });

  group('BackupApi.restoreBackup', () {
    late RequestRecorder rec;
    setUp(() => resetApiClientState());

    test('带密码时 body 含 name 与 password', () async {
      rec = installMockAdapter((options) async =>
          jsonResponse({'success': true, 'restored': true}));
      final r = await BackupApi.restoreBackup('a.zip', password: 'secret');
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/backup/restore');
      expect(req.data['name'], 'a.zip');
      expect(req.data['password'], 'secret');
      expect(r['restored'], isTrue);
    });

    test('密码为空串时不发送 password 字段', () async {
      rec = installMockAdapter((options) async => jsonResponse({}));
      await BackupApi.restoreBackup('a.zip', password: '');
      final data = rec.last()!.data as Map;
      expect(data['name'], 'a.zip');
      expect(data.containsKey('password'), isFalse);
    });

    test('不传密码时不发送 password 字段', () async {
      rec = installMockAdapter((options) async => jsonResponse({}));
      await BackupApi.restoreBackup('a.zip');
      expect((rec.last()!.data as Map).containsKey('password'), isFalse);
    });

    test('500 时抛异常', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        BackupApi.restoreBackup('a.zip'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('恢复备份失败'))),
      );
    });
  });

  group('BackupApi.getBackupStatus', () {
    late RequestRecorder rec;
    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async =>
          jsonResponse({'status': 'idle', 'last_backup': '2024-01-01'}));
    });

    test('GET /api/backup/status 透传 data', () async {
      final r = await BackupApi.getBackupStatus();
      expect(rec.last()!.method, 'GET');
      expect(rec.last()!.path, '/api/backup/status');
      expect(r['status'], 'idle');
    });
  });

  group('BackupApi.deleteBackup', () {
    late RequestRecorder rec;
    setUp(() => resetApiClientState());

    test('POST /api/backup/delete 携带 name，成功透传 data', () async {
      rec = installMockAdapter(
          (options) async => jsonResponse({'success': true}));
      final r = await BackupApi.deleteBackup('a.zip');
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/backup/delete');
      expect(req.data['name'], 'a.zip');
      expect(r['success'], isTrue);
    });

    test('非 200（201）时抛出服务端 error 文本', () async {
      installMockAdapter((options) async =>
          jsonResponse({'error': '备份文件不存在'}, statusCode: 201));
      expect(
        BackupApi.deleteBackup('ghost.zip'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('备份文件不存在'))),
      );
    });
  });
}
