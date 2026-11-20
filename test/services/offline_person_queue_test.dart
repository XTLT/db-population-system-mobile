import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/offline_operation.dart';
import 'package:population_mobile/services/offline_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = OfflineDataService();
  const idCard = '520325199001011234';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('新增人员入队为 create，修改入队为 update', () async {
    final data = <String, dynamic>{
      'id_card': idCard,
      'name': '张三',
      'hu_hao': 'H001',
    };

    await service.savePersonOffline(data, isCreate: true);
    await service.savePersonOffline(data, isCreate: false);

    final ops = await service.getPendingOperations();
    expect(ops.length, 2);
    expect(ops[0].type, OperationType.create);
    expect(ops[1].type, OperationType.update);
    expect(ops[0].entityId, idCard);
    expect(ops[0].entityType, 'person');
    // 重试前两条都应是待同步
    expect(ops.every((op) => op.status == SyncStatus.pending), isTrue);
  });

  test('失败项手动重试后复位为 pending 且重试次数清零', () async {
    await service.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: true,
    );
    final op = (await service.getPendingOperations()).single;

    await service.incrementRetryCount(op.id);
    await service.incrementRetryCount(op.id);
    await service.updateOperationStatus(
      op.id,
      SyncStatus.failed,
      conflictReason: '超过最大重试次数',
    );

    await service.resetOperationForRetry(op.id);

    final after = (await service.getPendingOperations()).single;
    expect(after.status, SyncStatus.pending);
    expect(after.retryCount, 0);
    // 上一次的失败原因要清掉，否则重试成功后仍显示红字
    expect(after.conflictReason, isEmpty);
  });

  test('删除草稿会从队列移除', () async {
    await service.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: true,
    );
    final op = (await service.getPendingOperations()).single;

    await service.removeOperation(op.id);

    expect(await service.getPendingOperations(), isEmpty);
  });

  test('删除最后一条草稿时顺带清掉人员缓存', () async {
    final cacheKey = 'person_$idCard';
    await service.saveData(cacheKey, <String, dynamic>{'name': '张三'});
    await service.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: true,
    );
    final op = (await service.getPendingOperations()).single;

    await service.removeOperation(op.id);

    expect(await service.getData(cacheKey), isNull);
  });

  test('同一人员还有其它草稿时保留缓存', () async {
    final cacheKey = 'person_$idCard';
    await service.saveData(cacheKey, <String, dynamic>{'name': '张三'});
    await service.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: true,
    );
    await service.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三', 'phone': '13800000000'},
      isCreate: false,
    );

    final ops = await service.getPendingOperations();
    expect(ops.length, 2);

    await service.removeOperation(ops.first.id);

    expect(await service.getData(cacheKey), isNotNull);
    expect((await service.getPendingOperations()).length, 1);
  });
}
