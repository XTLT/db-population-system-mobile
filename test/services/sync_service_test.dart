import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/api/person_api.dart';
import 'package:population_mobile/models/offline_operation.dart';
import 'package:population_mobile/services/offline_data_service.dart';
import 'package:population_mobile/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 可控的远端假实现：记录调用、按需制造冲突/失败。
class FakeSyncApi implements SyncApi {
  final List<Map<String, dynamic>> updatePersonCalls = [];
  final List<Map<String, dynamic>> addPersonCalls = [];
  final List<Map<String, dynamic>> updateEducationCalls = [];
  final List<Map<String, dynamic>> updateStudentCalls = [];

  bool conflictOnUpdate = false;
  bool failOnUpdate = false;

  @override
  Future<Map<String, dynamic>> getPerson(String idCard) async {
    return <String, dynamic>{
      'id_card': idCard,
      'name': '服务端最新',
      'updated_at': '2026-11-20 10:00:00',
    };
  }

  @override
  Future<bool> addPerson(Map<String, dynamic> data) async {
    addPersonCalls.add(data);
    return true;
  }

  @override
  Future<bool> updatePerson(String idCard, Map<String, dynamic> data) async {
    updatePersonCalls.add(data);
    if (failOnUpdate) throw Exception('连接超时');
    if (conflictOnUpdate) {
      throw PersonConflictException('服务器记录已被其他人修改');
    }
    return true;
  }

  @override
  Future<bool> updateEducation(String personId, Map<String, dynamic> data) async {
    updateEducationCalls.add(data);
    return true;
  }

  @override
  Future<bool> deletePerson(String idCard) async => true;

  @override
  Future<bool> addStudent(Map<String, dynamic> data) async => true;

  @override
  Future<bool> updateStudent(String idCard, Map<String, dynamic> data) async {
    updateStudentCalls.add(data);
    return true;
  }

  @override
  Future<bool> deleteStudent(String idCard) async => true;

  @override
  Future<Map<String, dynamic>> uploadPhoto({
    required String idCard,
    required String photoType,
    required File file,
  }) async =>
      <String, dynamic>{'success': true};

  @override
  Future<bool> deletePhoto(String idCard, String photoType) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final store = OfflineDataService();
  const idCard = '520325199001011234';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('同步成功后操作直接出队，不再累积 synced 项', () async {
    await store.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: true,
    );
    final api = FakeSyncApi();

    final result = await SyncService(api: api).syncAll();

    expect(result.successCount, 1);
    expect(await store.getPendingOperations(), isEmpty);
    expect(api.addPersonCalls.single['name'], '张三');
  });

  test('服务端 409 标为冲突并留有记录，不重试', () async {
    await store.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: false,
      baseUpdatedAt: '2026-11-20 09:00:00',
    );
    final api = FakeSyncApi()..conflictOnUpdate = true;

    final result = await SyncService(api: api).syncAll();

    expect(result.conflictCount, 1);
    expect(result.failedCount, 0);

    final op = (await store.getPendingOperations()).single;
    expect(op.status, SyncStatus.conflict);
    expect(op.retryCount, 0, reason: '冲突不是可重试失败');
    expect(await store.getConflicts(), hasLength(1));
  });

  test('离线编辑回传打开页面时的 updated_at 基线', () async {
    await store.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: false,
      baseUpdatedAt: '2026-11-20 09:00:00',
    );
    final api = FakeSyncApi();

    await SyncService(api: api).syncAll();

    expect(
      api.updatePersonCalls.single['updated_at'],
      '2026-11-20 09:00:00',
    );
  });

  test('没有基线的老草稿不传 updated_at，避免凭空报冲突', () async {
    await store.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: false,
    );
    final api = FakeSyncApi();

    await SyncService(api: api).syncAll();

    expect(api.updatePersonCalls.single.containsKey('updated_at'), isFalse);
  });

  test('同步失败写回失败原因并设置退避时间', () async {
    await store.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: false,
    );
    final api = FakeSyncApi()..failOnUpdate = true;

    final result = await SyncService(api: api).syncAll();

    expect(result.failedCount, 1);
    final op = (await store.getPendingOperations()).single;
    expect(op.status, SyncStatus.failed);
    expect(op.retryCount, 1);
    expect(op.conflictReason, contains('连接超时'));
    expect(op.nextRetryAt, isNotNull);
  });

  test('退避未到期的操作本轮跳过，不再请求服务器', () async {
    await store.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: false,
    );
    final op = (await store.getPendingOperations()).single;
    await store.incrementRetryCount(
      op.id,
      nextRetryAt: DateTime.now().add(const Duration(minutes: 5)),
    );
    final api = FakeSyncApi();

    final result = await SyncService(api: api).syncAll();

    expect(result.skippedCount, 1);
    expect(api.updatePersonCalls, isEmpty);
  });

  test('重试次数用尽后不再发请求', () async {
    await store.savePersonOffline(
      <String, dynamic>{'id_card': idCard, 'name': '张三'},
      isCreate: false,
    );
    final op = (await store.getPendingOperations()).single;
    for (var i = 0; i < SyncService.maxRetries; i++) {
      await store.incrementRetryCount(op.id);
    }
    final api = FakeSyncApi();

    final result = await SyncService(api: api).syncAll();

    expect(result.failedCount, 1);
    expect(api.updatePersonCalls, isEmpty);
    final after = (await store.getPendingOperations()).single;
    expect(after.conflictReason, contains('最大重试次数'));
  });

  test('新增人员时 __education 不混进人员接口，单独提交就读信息', () async {
    await store.savePersonOffline(
      <String, dynamic>{
        'id_card': idCard,
        'name': '张三',
        '__education': {'school_name': '希望小学', 'grade': 'G3'},
      },
      isCreate: true,
    );
    final api = FakeSyncApi();

    await SyncService(api: api).syncAll();

    expect(api.addPersonCalls.single.containsKey('__education'), isFalse);
    expect(api.updateEducationCalls.single['school_name'], '希望小学');
  });

  test('学生草稿走学生接口，不误调人员接口', () async {
    await store.saveStudentOffline(
      <String, dynamic>{
        'id_card': idCard,
        'school_name': '希望小学',
        'grade': 'G3',
      },
      isCreate: false,
    );
    final api = FakeSyncApi();

    final result = await SyncService(api: api).syncAll();

    expect(result.successCount, 1);
    expect(api.updateStudentCalls.single['grade'], 'G3');
    expect(api.updatePersonCalls, isEmpty);
  });

  test('退避按指数增长并封顶 30 分钟', () {
    expect(SyncService.backoffFor(1).inSeconds, 30);
    expect(SyncService.backoffFor(2).inSeconds, 60);
    expect(SyncService.backoffFor(3).inSeconds, 120);
    expect(SyncService.backoffFor(20), SyncService.maxBackoff);
  });

  test('清理历史遗留的已同步项', () async {
    final op = OfflineOperation(
      id: 'old-synced',
      type: OperationType.update,
      entityType: 'person',
      entityId: idCard,
      data: <String, dynamic>{'id_card': idCard},
      status: SyncStatus.pending,
      createdAt: DateTime.now(),
    );
    await store.queueOperation(op);
    await store.updateOperationStatus(op.id, SyncStatus.synced);

    final removed = await store.pruneSyncedOperations();

    expect(removed, 1);
    expect(await store.getPendingOperations(), isEmpty);
  });
}
