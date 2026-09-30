import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/backup_info.dart';

void main() {
  group('BackupInfo Model Tests', () {
    test('fromJson 应字段级解析（注意 path 取自 JSON 的 name）', () {
      final json = {
        'timestamp': '20260930_120000',
        'time': '2026-09-30 12:00:00',
        'name': '/backups/person_20260930.db',
        'size': 2048,
        'encrypted': true,
        'manual': true,
      };

      final b = BackupInfo.fromJson(json);

      expect(b.timestamp, '20260930_120000');
      expect(b.time, '2026-09-30 12:00:00');
      // 源码 fromJson 第 23 行：path: json['name']
      expect(b.path, '/backups/person_20260930.db');
      expect(b.size, 2048);
      expect(b.encrypted, true);
      expect(b.manual, true);
    });

    test('fromJson 缺省值应正确（path/size/encrypted/manual 默认）', () {
      final b = BackupInfo.fromJson(<String, dynamic>{});
      expect(b.timestamp, '');
      expect(b.time, '');
      expect(b.path, ''); // name 缺省 -> ''
      expect(b.size, 0);
      expect(b.encrypted, false);
      expect(b.manual, false);
    });

    test('fromJson 同时提供 path 与 name 时优先取 path（BUG-14）', () {
      final b = BackupInfo.fromJson({
        'timestamp': 't',
        'time': 'tm',
        'path': '/backups/real.db',
        'name': '/backups/legacy.db',
        'size': 10,
      });
      // toJson 用 path key，fromJson 优先 path，二者对称
      expect(b.path, '/backups/real.db');
    });

    test('toJson 应输出全部字段', () {
      final b = BackupInfo(
        timestamp: 'ts1',
        time: 't1',
        path: '/x/y.db',
        size: 4096,
        encrypted: false,
        manual: false,
      );

      final json = b.toJson();
      expect(json['timestamp'], 'ts1');
      expect(json['time'], 't1');
      // toJson 用的是 path key（注意：与 fromJson 的 name key 不对称）
      expect(json['path'], '/x/y.db');
      expect(json['size'], 4096);
      expect(json['encrypted'], false);
      expect(json['manual'], false);
    });

    test('formattedSize 应按 B/KB/MB/GB 自适应', () {
      String fmt(int size) =>
          BackupInfo(timestamp: '', time: '', path: '', size: size, encrypted: false, manual: false)
              .formattedSize;

      expect(fmt(0), '0 B');
      expect(fmt(512), '512 B');
      expect(fmt(1023), '1023 B');
      // 1 KB 边界（源码保留 2 位小数）
      expect(fmt(1024), '1.00 KB');
      expect(fmt(1536), '1.50 KB');
      expect(fmt(1024 * 1024 - 1), '1024.00 KB');
      // 1 MB 边界
      expect(fmt(1024 * 1024), '1.00 MB');
      expect(fmt(10 * 1024 * 1024), '10.00 MB');
      // 1 GB 边界
      expect(fmt(1024 * 1024 * 1024), '1.00 GB');
      expect(fmt(3 * 1024 * 1024 * 1024), '3.00 GB');
    });
  });
}
