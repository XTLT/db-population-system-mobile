import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/services/offline_data_service.dart';
import 'package:population_mobile/models/offline_operation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // BUG-04 已修复：saveStudentOffline 现以 studentData['id_card'] 判断分支
  // （Student 模型只有 id_card，无 id）。下方补回原本跳过的离线保存用例。
  group('OfflineDataService.isDataExpired Tests', () {
    final svc = OfflineDataService();

    test('超过默认 24 小时应判定过期', () {
      final old = DateTime.now().subtract(const Duration(hours: 25));
      expect(svc.isDataExpired(old), true);
    });

    test('不足 24 小时应判定未过期', () {
      final recent = DateTime.now().subtract(const Duration(hours: 10));
      expect(svc.isDataExpired(recent), false);
    });

    test('正好 24 小时不算过期（严格大于）', () {
      final exactly = DateTime.now().subtract(const Duration(hours: 24));
      expect(svc.isDataExpired(exactly), false);
    });

    test('自定义 maxAgeInHours 应生效', () {
      final threeHoursAgo = DateTime.now().subtract(const Duration(hours: 3));
      // 3 小时 < 2 小时阈值？不——阈值 2 小时，则 3 小时应过期
      expect(svc.isDataExpired(threeHoursAgo, maxAgeInHours: 2), true);
      // 阈值 5 小时，则 3 小时未过期
      expect(svc.isDataExpired(threeHoursAgo, maxAgeInHours: 5), false);
    });

    test('未来时间（difference 为负）应判定未过期', () {
      final future = DateTime.now().add(const Duration(hours: 5));
      expect(svc.isDataExpired(future), false);
    });
  });

  group('OfflineDataService.generateId Tests', () {
    final svc = OfflineDataService();

    test('应返回非空字符串且含分隔符', () {
      final id = svc.generateId();
      expect(id, isNotEmpty);
      expect(id.contains('_'), true);
    });

    test('连续调用应产生不同 id', () async {
      final a = svc.generateId();
      // 微小等待以确保时间戳/微秒不同
      await Future.delayed(const Duration(milliseconds: 5));
      final b = svc.generateId();
      expect(a, isNot(b));
    });
  });

  group('OfflineDataService.saveData/getData 往返（prefs mock）', () {
    test('应能存取并删除数据', () async {
      final svc = OfflineDataService();
      await svc.saveData('person_list', [
        {'name': '张三'},
        {'name': '李四'},
      ]);

      final data = await svc.getData('person_list');
      expect(data, isNotNull);
      expect(data.length, 2);
      expect(data[0]['name'], '张三');

      // 不存在的 key
      expect(await svc.getData('no_such_key'), isNull);

      // removeData
      await svc.removeData('person_list');
      expect(await svc.getData('person_list'), isNull);
    });
  });

  group('OfflineDataService.saveStudentOffline Tests（BUG-04）', () {
    final svc = OfflineDataService();

    test('有 id_card 应走 update 分支，entityId 与缓存 key 均用 id_card', () async {
      await svc.saveStudentOffline({
        'id_card': 'S110101201001011234',
        'name': '学生甲',
        'grade': 'G5',
      });

      final ops = await svc.getPendingOperations();
      expect(ops.length, 1);
      final op = ops.first;
      expect(op.type, OperationType.update); // 有 id_card → update
      expect(op.entityType, 'student');
      expect(op.entityId, 'S110101201001011234');

      // 本地数据缓存 key 应为 student_<id_card>
      final cached = await svc.getData('student_S110101201001011234');
      expect(cached, isNotNull);
      expect(cached['name'], '学生甲');
    });

    test('无 id_card 应走 create 分支，entityId 为空串', () async {
      await svc.saveStudentOffline({
        'name': '新生乙',
        'grade': 'G1',
      });

      final ops = await svc.getPendingOperations();
      expect(ops.length, 1);
      final op = ops.first;
      expect(op.type, OperationType.create); // 无 id_card → create
      expect(op.entityType, 'student');
      expect(op.entityId, '');
    });
  });
}
