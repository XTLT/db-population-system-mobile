import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/offline_operation.dart';

void main() {
  group('OfflineOperation Model Tests', () {
    final createdAt = DateTime.utc(2026, 9, 30, 10);
    final syncedAt = DateTime.utc(2026, 9, 30, 10, 5);

    OfflineOperation buildOp({
      OperationType type = OperationType.create,
      SyncStatus status = SyncStatus.pending,
      int retryCount = 0,
    }) {
      return OfflineOperation(
        id: 'op-1',
        type: type,
        entityType: 'person',
        entityId: '110101199001011234',
        data: {'name': '张三'},
        status: status,
        createdAt: createdAt,
        syncedAt: syncedAt,
        conflictReason: '冲突原因',
        retryCount: retryCount,
      );
    }

    test('toJson 应使用 enum.name 并序列化全部字段', () {
      final op = buildOp(
          type: OperationType.update, status: SyncStatus.conflict, retryCount: 2);
      final json = op.toJson();

      expect(json['id'], 'op-1');
      expect(json['type'], 'update');
      expect(json['entity_type'], 'person');
      expect(json['entity_id'], '110101199001011234');
      expect(json['data'], {'name': '张三'});
      expect(json['status'], 'conflict');
      expect(json['created_at'], createdAt.toIso8601String());
      expect(json['synced_at'], syncedAt.toIso8601String());
      expect(json['conflict_reason'], '冲突原因');
      expect(json['retry_count'], 2);
    });

    test('fromJson 应字段级反序列化（枚举按 name 匹配）', () {
      final json = {
        'id': 'op-2',
        'type': 'delete',
        'entity_type': 'student',
        'entity_id': 'S-1',
        'data': {'grade': 'G7'},
        'status': 'synced',
        'created_at': createdAt.toIso8601String(),
        'synced_at': syncedAt.toIso8601String(),
        'conflict_reason': null,
        'retry_count': 5,
      };

      final op = OfflineOperation.fromJson(json);

      expect(op.id, 'op-2');
      expect(op.type, OperationType.delete);
      expect(op.entityType, 'student');
      expect(op.entityId, 'S-1');
      expect(op.data, {'grade': 'G7'});
      expect(op.status, SyncStatus.synced);
      expect(op.createdAt, createdAt);
      expect(op.syncedAt, syncedAt);
      expect(op.conflictReason, isNull);
      expect(op.retryCount, 5);
    });

    test('fromJson 缺省 retryCount/syncedAt/conflictReason 时回落到默认值', () {
      // BUG-05 已修复：status 缺省也会回落 pending（见下方用例）；其余可缺省
      final json = {
        'id': 'op-3',
        'type': 'addPhoto',
        'entity_type': 'person',
        'entity_id': 'P-1',
        'data': {},
        'status': 'pending',
        'created_at': createdAt.toIso8601String(),
      };
      final op = OfflineOperation.fromJson(json);
      expect(op.status, SyncStatus.pending);
      expect(op.retryCount, 0); // json['retry_count'] ?? 0
      expect(op.syncedAt, isNull);
      expect(op.conflictReason, isNull);
    });

    // BUG-05 已修复：fromJson 对 status/type 用 firstWhere + orElse 兜底。
    // 缺省 status 时回落到 SyncStatus.pending（与构造器默认一致），不再抛 StateError。
    test('fromJson 缺省 status 时回落到 SyncStatus.pending', () {
      final json = {
        'id': 'op-3b',
        'type': 'addPhoto',
        'entity_type': 'person',
        'entity_id': 'P-1',
        'data': {},
        'created_at': createdAt.toIso8601String(),
        // 故意不提供 status
      };
      final op = OfflineOperation.fromJson(json);
      expect(op.status, SyncStatus.pending);
      expect(op.type, OperationType.addPhoto);
    });

    test('toJson -> fromJson 往返一致', () {
      final op = buildOp(type: OperationType.addPhoto, status: SyncStatus.failed);
      final back = OfflineOperation.fromJson(op.toJson());
      expect(back.id, op.id);
      expect(back.type, op.type);
      expect(back.entityType, op.entityType);
      expect(back.entityId, op.entityId);
      expect(back.status, op.status);
      expect(back.retryCount, op.retryCount);
      expect(back.conflictReason, op.conflictReason);
      expect(back.syncedAt, op.syncedAt);
    });

    test('copyWith 应仅覆盖指定字段，其余保持', () {
      final op = buildOp(status: SyncStatus.pending, retryCount: 0);
      final updated = op.copyWith(status: SyncStatus.synced, retryCount: 1);

      expect(updated.id, op.id); // 未覆盖保持
      expect(updated.type, op.type);
      expect(updated.status, SyncStatus.synced);
      expect(updated.retryCount, 1);
    });

    test('枚举全部取值应可往返', () {
      for (final t in OperationType.values) {
        final json = buildOp(type: t).toJson();
        expect(OfflineOperation.fromJson(json).type, t);
      }
      for (final s in SyncStatus.values) {
        final json = buildOp(status: s).toJson();
        expect(OfflineOperation.fromJson(json).status, s);
      }
    });

    // BUG-05 已修复：type 未知/缺省时 orElse 回落到 OperationType.update（非破坏性默认），
    // status 缺省回落到 pending；fromJson 不再因未知枚举值抛 StateError。
    test('fromJson 未知 type/缺省 status 时回落到默认值（不再抛 StateError）', () {
      final json = {
        'id': 'op-x',
        'type': 'not_a_real_type',
        'entity_type': 'person',
        'entity_id': 'P-1',
        'data': {},
        'created_at': createdAt.toIso8601String(),
        // 故意不提供 status
      };
      final op = OfflineOperation.fromJson(json);
      expect(op.type, OperationType.update); // 未知 type → update
      expect(op.status, SyncStatus.pending); // 缺省 status → pending
    });
  });
}
