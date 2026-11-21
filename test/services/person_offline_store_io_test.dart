import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/services/person_offline_store.dart';

import '../test_helpers.dart';

void main() {
  ensureTestBinding();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('person_offline_test_');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return tempDir.path;
        }
        return null;
      },
    );
  });

  tearDownAll(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('下载全部人员→落盘→断网查询→清除，全链路可用', () async {
    resetApiClientState();
    final persons = List.generate(500, (i) {
      return <String, dynamic>{
        'id_card': '5201001990${(i % 12 + 1).toString().padLeft(2, '0')}'
            '${(i % 28 + 1).toString().padLeft(2, '0')}${i.toString().padLeft(4, '0')}',
        'name': '离线村民$i',
        'hu_hao': 'H${(i ~/ 4).toString().padLeft(4, '0')}',
        'phone': '138${i.toString().padLeft(8, '0')}',
        'address': '测试村${i % 6 + 1}组',
        'group_name': '${i % 6 + 1}组',
        'relation': i % 4 == 0 ? '户主' : '配偶',
        'age': '${20 + i % 60}',
        'is_dead': '否',
        'remark': '离线体积测试',
        'updated_at': '2026-11-21 23:00:00',
      };
    });
    installMockAdapter((options) async {
      if (options.path == '/api/persons/lookup-all') {
        return jsonResponse({'persons': persons, 'total': persons.length});
      }
      return jsonResponse({'error': 'not found'}, statusCode: 404);
    });

    final sw = Stopwatch()..start();
    final info = await PersonOfflineStore.instance.downloadAll();
    sw.stop();

    expect(info.count, 500);
    expect(info.bytes, greaterThan(10 * 1024));
    expect(info.savedAt, isNotNull);
    // 500 人小样本落盘应在 5 秒内（真机 3000+ 人另算网络耗时）
    expect(sw.elapsed.inSeconds, lessThan(5));

    final file = File('${tempDir.path}/offline/persons_all.json');
    expect(await file.exists(), isTrue);
    final head = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(head['count'], 500);
    expect(head['persons'], isA<List>());

    // 重新读头，不依赖内存
    final info2 = await PersonOfflineStore.instance.info();
    expect(info2.count, 500);

    final byId = await PersonOfflineStore.instance.search(
      persons.first['id_card'] as String,
    );
    expect(byId.length, 1);
    expect(byId.first.name, persons.first['name']);

    final byPhone = await PersonOfflineStore.instance.search(
      persons.last['phone'] as String,
    );
    expect(byPhone.length, 1);
    expect(byPhone.first.name, persons.last['name']);

    final byName = await PersonOfflineStore.instance.search('离线村民49');
    expect(byName.map((p) => p.name), contains('离线村民49'));

    final byHuHao = await PersonOfflineStore.instance.search('H0001');
    expect(byHuHao.length, greaterThanOrEqualTo(4));

    await PersonOfflineStore.instance.clear();
    expect((await PersonOfflineStore.instance.info()).isEmpty, isTrue);
    expect(await file.exists(), isFalse);
  });
}
