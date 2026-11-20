
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/offline_operation.dart';
import '../models/person.dart';
import '../models/student.dart';
import '../api/person_api.dart';
import '../api/student_api.dart';
import 'offline_data_service.dart';
import 'photo_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const int maxRetries = 3;

  
  Future<SyncResult> syncAll() async {
    final result = SyncResult();
    final operations = await OfflineDataService().getPendingOperations();

    
    // syncing 是上次同步中途退出（进程被杀/断网）的残留，按待同步重试，
    // 否则这类操作会永远停在"同步中"。
    final pendingOps = operations
        .where((op) =>
            op.status == SyncStatus.pending ||
            op.status == SyncStatus.failed ||
            op.status == SyncStatus.syncing)
        .toList();

    result.totalOperations = pendingOps.length;

    for (final op in pendingOps) {
      if (op.retryCount >= maxRetries) {
        await OfflineDataService().updateOperationStatus(
          op.id,
          SyncStatus.failed,
          conflictReason: '超过最大重试次数',
        );
        result.failedCount++;
        continue;
      }

      try {
        
        await OfflineDataService().updateOperationStatus(op.id, SyncStatus.syncing);

        
        await _syncOperation(op);

        
        await OfflineDataService().updateOperationStatus(op.id, SyncStatus.synced);
        result.successCount++;
      } on SyncConflictException {
        await OfflineDataService().updateOperationStatus(
          op.id,
          SyncStatus.conflict,
          conflictReason: '服务器记录已被修改，请人工核对',
        );
        result.conflictCount++;
      } catch (e) {
        final reason = _shortReason(e);
        await OfflineDataService().incrementRetryCount(op.id);
        // 把真实原因写回队列，村里能看到"到底卡在哪"，而不是笼统的失败
        await OfflineDataService().updateOperationStatus(
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

  
  Future<void> _syncOperation(OfflineOperation op) async {
    if (op.entityType == 'person' && op.entityId.isEmpty) {
      throw Exception('人员草稿缺少身份证号，无法同步');
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
    await PersonApi.updateEducation(
      op.entityId,
      Map<String, dynamic>.from(raw),
    );
  }

  Future<void> _syncCreate(OfflineOperation op) async {
    if (op.entityType == 'person') {
      // 直接提交离线时保存的原始 payload：经 Person 模型往返会丢掉
      // 表单里的补贴/林地/变更原因等字段。
      await PersonApi.addPerson(_personPayload(op));
      await _syncEducationIfAny(op);
    } else if (op.entityType == 'student') {
      final student = Student.fromJson(op.data);
      await StudentApi.addStudent(student.toJson());
    }
  }

  
  Future<void> _syncUpdate(OfflineOperation op) async {
    if (op.entityType == 'person') {
      
      try {
        final serverData = await PersonApi.getPerson(op.entityId);
        final serverPerson = Person.fromJson(serverData);

        
        if (_hasConflict(op, serverPerson)) {
          await OfflineDataService().saveConflict(op, serverData);
          throw const SyncConflictException();
        }
      } catch (e) {
        
        debugPrint('获取服务器数据失败，继续同步: $e');
      }

      
      await PersonApi.updatePerson(op.entityId, _personPayload(op));
      await _syncEducationIfAny(op);
    } else if (op.entityType == 'student') {
      await StudentApi.updateStudent(op.entityId, op.data);
    }
  }

  
  Future<void> _syncDelete(OfflineOperation op) async {
    if (op.entityType == 'person') {
      await PersonApi.deletePerson(op.entityId);
    } else if (op.entityType == 'student') {
      await StudentApi.deleteStudent(op.entityId);
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

    final result = await PhotoService.uploadPhoto(
      idCard: op.entityId,
      photoType: photoType,
      photoFile: photoFile,
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

    final success = await PhotoService.deletePhoto(op.entityId, photoType);

    if (!success) {
      throw Exception('删除照片失败');
    }
  }

  
  
  // 6b：桩实现（stub），恒返回 false。
  // 结论：基于现有数据字段无法做真实的三方冲突检测——Person/OfflineOperation 均未携带
  //   ① 离线编辑所基于的基线快照(base)，或 ② Person 上的 updated_at/version 向量时钟字段；
  //   op.data 存的是本地“新值”而非旧值，因此无法判断“服务器记录是否在离线期间被他人改过”。
  //   要实现真实冲突检测需先扩展 schema（保存 base 快照或加版本字段），不在本次最小改动范围内。
  // TODO(stub): 待 Person 增加 updated_at/version 或 OfflineOperation.data 记录基线后，
  //   改为比较 serverPerson 与 op.data 的基线差异，命中则返回 true 触发 saveConflict。
  bool _hasConflict(OfflineOperation op, Person serverPerson) {
    return false;
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
    final operations = await OfflineDataService().getPendingOperations();
    return operations
        .where((op) =>
            op.status == SyncStatus.pending || op.status == SyncStatus.failed)
        .length;
  }

  
  Future<int> getConflictCount() async {
    final conflicts = await OfflineDataService().getConflicts();
    return conflicts.length;
  }
}


class SyncResult {
  int totalOperations = 0;
  int successCount = 0;
  int failedCount = 0;
  int conflictCount = 0;

  bool get isSuccess => failedCount == 0 && conflictCount == 0;
  String get summary => conflictCount > 0
      ? '成功: $successCount, 失败: $failedCount, 冲突: $conflictCount, 总计: $totalOperations'
      : '成功: $successCount, 失败: $failedCount, 总计: $totalOperations';
}

/// 同步时发现服务器记录已被他人改动，需要人工确认；
/// 与普通失败区分开，避免被直接标记成"已同步"。
class SyncConflictException implements Exception {
  const SyncConflictException();
}
