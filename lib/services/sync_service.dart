
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/offline_operation.dart';
import '../models/student.dart';
import '../api/person_api.dart';
import '../api/student_api.dart';
import 'offline_data_service.dart';
import 'photo_service.dart';

/// 同步层依赖的远端接口集合。
///
/// 抽成接口的目的：SyncService 不再直接绑静态 PersonApi/StudentApi，
/// 单测可以注入假实现，覆盖"冲突/失败/退避/出队"这些分支。
abstract class SyncApi {
  Future<Map<String, dynamic>> getPerson(String idCard);
  Future<bool> addPerson(Map<String, dynamic> data);
  Future<bool> updatePerson(String idCard, Map<String, dynamic> data);
  Future<bool> deletePerson(String idCard);
  Future<bool> updateEducation(String personId, Map<String, dynamic> data);

  Future<bool> addStudent(Map<String, dynamic> data);
  Future<bool> updateStudent(String idCard, Map<String, dynamic> data);
  Future<bool> deleteStudent(String idCard);

  Future<Map<String, dynamic>> uploadPhoto({
    required String idCard,
    required String photoType,
    required File file,
  });
  Future<bool> deletePhoto(String idCard, String photoType);
}

/// 生产实现：全部转调现有静态 API，行为与改造前一致。
class DefaultSyncApi implements SyncApi {
  const DefaultSyncApi();

  @override
  Future<Map<String, dynamic>> getPerson(String idCard) =>
      PersonApi.getPerson(idCard);

  @override
  Future<bool> addPerson(Map<String, dynamic> data) =>
      PersonApi.addPerson(data);

  @override
  Future<bool> updatePerson(String idCard, Map<String, dynamic> data) =>
      PersonApi.updatePerson(idCard, data);

  @override
  Future<bool> deletePerson(String idCard) => PersonApi.deletePerson(idCard);

  @override
  Future<bool> updateEducation(String personId, Map<String, dynamic> data) =>
      PersonApi.updateEducation(personId, data);

  @override
  Future<bool> addStudent(Map<String, dynamic> data) =>
      StudentApi.addStudent(data);

  @override
  Future<bool> updateStudent(String idCard, Map<String, dynamic> data) =>
      StudentApi.updateStudent(idCard, data);

  @override
  Future<bool> deleteStudent(String idCard) =>
      StudentApi.deleteStudent(idCard);

  @override
  Future<Map<String, dynamic>> uploadPhoto({
    required String idCard,
    required String photoType,
    required File file,
  }) =>
      PhotoService.uploadPhoto(
        idCard: idCard,
        photoType: photoType,
        photoFile: file,
      );

  @override
  Future<bool> deletePhoto(String idCard, String photoType) =>
      PhotoService.deletePhoto(idCard, photoType);
}

class SyncService {
  /// 生产调用保持 `SyncService()` 不变；测试用 `SyncService(api: fake)` 注入。
  SyncService({SyncApi? api, OfflineDataService? store})
      : _api = api ?? const DefaultSyncApi(),
        _store = store ?? OfflineDataService();

  static const int maxRetries = 3;
  static const Duration baseBackoff = Duration(seconds: 30);
  static const Duration maxBackoff = Duration(minutes: 30);

  final SyncApi _api;
  final OfflineDataService _store;

  Future<SyncResult> syncAll() async {
    final result = SyncResult();
    final operations = await _store.getPendingOperations();

    // syncing 是上次同步中途退出（进程被杀/断网）的残留，按待同步重试，
    // 否则这类操作会永远停在"同步中"。
    final pendingOps = operations
        .where((op) =>
            op.status == SyncStatus.pending ||
            op.status == SyncStatus.failed ||
            op.status == SyncStatus.syncing)
        .toList();

    result.totalOperations = pendingOps.length;

    final now = DateTime.now();
    for (final op in pendingOps) {
      // 未到退避时间：本轮直接跳过，避免每次联网把同一批失败项重打一遍
      if (op.nextRetryAt != null && op.nextRetryAt!.isAfter(now)) {
        result.skippedCount++;
        continue;
      }

      if (op.retryCount >= maxRetries) {
        await _store.updateOperationStatus(
          op.id,
          SyncStatus.failed,
          conflictReason: '超过最大重试次数',
        );
        result.failedCount++;
        continue;
      }

      try {
        await _store.updateOperationStatus(op.id, SyncStatus.syncing);

        await _syncOperation(op);

        // 同步成功即出队。旧实现只标 synced 不出队，单 key 里的 JSON 会无限增长。
        await _store.removeOperation(op.id);
        result.successCount++;
      } on SyncConflictException catch (e) {
        await _store.updateOperationStatus(
          op.id,
          SyncStatus.conflict,
          conflictReason: e.message,
        );
        result.conflictCount++;
      } catch (e) {
        final reason = _shortReason(e);
        final retry = op.retryCount + 1;
        final delay = backoffFor(retry);
        await _store.incrementRetryCount(
          op.id,
          nextRetryAt: DateTime.now().add(delay),
        );
        // 把真实原因写回队列，村里能看到"到底卡在哪"，而不是笼统的失败
        await _store.updateOperationStatus(
          op.id,
          SyncStatus.failed,
          conflictReason: reason,
        );
        result.failedCount++;
        debugPrint('同步操作失败 [${op.type}] ${op.entityId}: $e');
      }
    }

    await PhotoService.cleanSyncedOfflinePhotos();

    return result;
  }

  /// 指数退避：30s、1m、2m、4m……封顶 30 分钟。
  static Duration backoffFor(int retryCount) {
    final shift = (retryCount - 1).clamp(0, 10).toInt();
    final seconds = math.min(
      baseBackoff.inSeconds * (1 << shift),
      maxBackoff.inSeconds,
    );
    return Duration(seconds: seconds);
  }

  Future<void> _syncOperation(OfflineOperation op) async {
    if (op.entityType == 'person' && op.entityId.isEmpty) {
      throw Exception('人员草稿缺少身份证号，无法同步');
    }
    if (op.entityType == 'student' && op.entityId.isEmpty) {
      throw Exception('学生草稿缺少身份证号，无法同步');
    }
    switch (op.type) {
      case OperationType.create:
        await _syncCreate(op);
        break;
      case OperationType.update:
        await _syncUpdate(op);
        break;
      case OperationType.delete:
        await _syncDelete(op);
        break;
      case OperationType.addPhoto:
        await _syncAddPhoto(op);
        break;
      case OperationType.deletePhoto:
        await _syncDeletePhoto(op);
        break;
    }
  }

  /// 离线 payload 里的 `__education` 是本地附加的就读信息，不能发给人员接口。
  Map<String, dynamic> _personPayload(OfflineOperation op) {
    final payload = Map<String, dynamic>.from(op.data);
    payload.remove('__education');
    return payload;
  }

  /// 人员提交成功后，单独提交离线时暂存的就读信息。
  Future<void> _syncEducationIfAny(OfflineOperation op) async {
    final raw = op.data['__education'];
    if (raw is! Map || raw.isEmpty) return;
    await _api.updateEducation(
      op.entityId,
      Map<String, dynamic>.from(raw),
    );
  }

  Future<void> _syncCreate(OfflineOperation op) async {
    if (op.entityType == 'person') {
      // 直接提交离线时保存的原始 payload：经 Person 模型往返会丢掉
      // 表单里的补贴/林地/变更原因等字段。
      await _api.addPerson(_personPayload(op));
      await _syncEducationIfAny(op);
    } else if (op.entityType == 'student') {
      final student = Student.fromJson(op.data);
      await _api.addStudent(student.toJson());
    }
  }

  Future<void> _syncUpdate(OfflineOperation op) async {
    if (op.entityType == 'person') {
      final payload = _personPayload(op);
      // 基线非空才带 updated_at：服务端只会在这两个值都非空时做 409 判定，
      // 老草稿（无基线）行为不变，不会突然开始报冲突。
      final base = op.baseUpdatedAt;
      if (base != null && base.isNotEmpty) {
        payload['updated_at'] = base;
      }

      try {
        await _api.updatePerson(op.entityId, payload);
      } on PersonConflictException catch (e) {
        await _recordConflict(op, e.message);
      }

      await _syncEducationIfAny(op);
    } else if (op.entityType == 'student') {
      await _api.updateStudent(op.entityId, op.data);
    }
  }

  /// 冲突落库：拉一次服务端最新数据给"处理冲突"页展示，然后抛出，
  /// 由外层标记 conflict（不重试）。
  Future<void> _recordConflict(OfflineOperation op, String message) async {
    Map<String, dynamic> serverData = <String, dynamic>{};
    try {
      serverData = await _api.getPerson(op.entityId);
    } catch (e) {
      debugPrint('冲突时获取服务端数据失败: $e');
    }
    await _store.saveConflict(op, serverData);
    throw SyncConflictException(message);
  }

  Future<void> _syncDelete(OfflineOperation op) async {
    if (op.entityType == 'person') {
      await _api.deletePerson(op.entityId);
    } else if (op.entityType == 'student') {
      await _api.deleteStudent(op.entityId);
    }
  }

  Future<void> _syncAddPhoto(OfflineOperation op) async {
    final localPath = op.data['local_path'] as String?;
    final photoType = op.data['photo_type'] as String?;

    if (localPath == null || photoType == null) {
      throw Exception('缺少照片路径或类型');
    }

    final photoFile = File(localPath);
    if (!await photoFile.exists()) {
      throw Exception('照片文件不存在: $localPath');
    }

    final result = await _api.uploadPhoto(
      idCard: op.entityId,
      photoType: photoType,
      file: photoFile,
    );

    if (result['success'] != true) {
      throw Exception(result['message'] ?? '上传照片失败');
    }
  }

  Future<void> _syncDeletePhoto(OfflineOperation op) async {
    final photoType = op.data['photo_type'] as String?;

    if (photoType == null) {
      throw Exception('缺少照片类型');
    }

    final success = await _api.deletePhoto(op.entityId, photoType);

    if (!success) {
      throw Exception('删除照片失败');
    }
  }

  /// 把异常压成一行短文案，写进队列给用户看。
  String _shortReason(Object e) {
    var text = e
        .toString()
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length > 80) text = '${text.substring(0, 80)}…';
    return text.isEmpty ? '同步失败' : text;
  }

  Future<int> getPendingCount() async {
    final operations = await _store.getPendingOperations();
    return operations
        .where((op) =>
            op.status == SyncStatus.pending || op.status == SyncStatus.failed)
        .length;
  }

  Future<int> getConflictCount() async {
    final conflicts = await _store.getConflicts();
    return conflicts.length;
  }
}


class SyncResult {
  int totalOperations = 0;
  int successCount = 0;
  int failedCount = 0;
  int conflictCount = 0;

  /// 因退避未到期而本轮跳过的条数
  int skippedCount = 0;

  bool get isSuccess => failedCount == 0 && conflictCount == 0;
  String get summary {
    final skipped =
        skippedCount > 0 ? '，退避中: $skippedCount' : '';
    return conflictCount > 0
        ? '成功: $successCount, 失败: $failedCount, 冲突: $conflictCount$skipped, 总计: $totalOperations'
        : '成功: $successCount, 失败: $failedCount$skipped, 总计: $totalOperations';
  }
}

/// 同步时发现服务器记录已被他人改动，需要人工确认；
/// 与普通失败区分开，避免被直接标记成"已同步"。
class SyncConflictException implements Exception {
  final String message;
  const SyncConflictException(
      [this.message = '服务器记录已被修改，请人工核对']);

  @override
  String toString() => message;
}
