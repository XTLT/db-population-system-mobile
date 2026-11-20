import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/offline_operation.dart';

class OfflineDataService {
  static final OfflineDataService _instance = OfflineDataService._internal();
  factory OfflineDataService() => _instance;

  OfflineDataService._internal();

  static const String _offlineDataPrefix = 'offline_data_';
  static const String _lastSyncTimeKey = 'last_sync_time';
  static const String _operationsKey = 'offline_operations';
  static const String _conflictsKey = 'offline_conflicts';

  /// 队列内容变化通知。每次入队/删除/状态变更都会自增，
  /// SyncProvider 订阅它来刷新首页角标，不再依赖"谁碰巧调了 loadStatus"。
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void _notifyChanged() {
    revision.value = revision.value + 1;
  }
  
  
  Future<void> saveData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataKey = _offlineDataPrefix + key;
      
      final offlineData = {
        'data': data,
        'saved_at': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(dataKey, jsonEncode(offlineData));
    } catch (e) {
      debugPrint('OfflineDataService.saveData error: $e');
    }
  }
  
  
  Future<dynamic> getData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataKey = _offlineDataPrefix + key;
      final dataString = prefs.getString(dataKey);
      
      if (dataString == null) return null;
      
      final offlineData = jsonDecode(dataString);
      return offlineData['data'];
    } catch (e) {
      return null;
    }
  }
  
  
  Future<void> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataKey = _offlineDataPrefix + key;
      await prefs.remove(dataKey);
    } catch (e) {
      debugPrint('OfflineDataService.removeData error: $e');
    }
  }
  
  
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_offlineDataPrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('OfflineDataService.clearAllData error: $e');
    }
  }
  
  
  Future<void> updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastSyncTimeKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('OfflineDataService.updateLastSyncTime error: $e');
    }
  }
  
  
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeString = prefs.getString(_lastSyncTimeKey);
      
      if (timeString == null) return null;
      
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }
  
  
  bool isDataExpired(DateTime savedTime, {int maxAgeInHours = 24}) {
    final now = DateTime.now();
    final difference = now.difference(savedTime);
    return difference.inHours > maxAgeInHours;
  }
  
  
  Future<int> getDataSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      int totalSize = 0;
      
      for (final key in keys) {
        if (key.startsWith(_offlineDataPrefix)) {
          final value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length * 2;
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  
  Future<void> cachePersonList(List<dynamic> persons) async {
    await saveData('person_list', persons);
    await updateLastSyncTime();
  }
  
  
  Future<List<dynamic>?> getCachedPersonList() async {
    return await getData('person_list');
  }
  
  
  Future<void> cacheStudentList(List<dynamic> students) async {
    await saveData('student_list', students);
    await updateLastSyncTime();
  }
  
  
  Future<List<dynamic>?> getCachedStudentList() async {
    return await getData('student_list');
  }
  
  
  Future<void> cacheStatistics(Map<String, dynamic> stats) async {
    await saveData('statistics', stats);
    await updateLastSyncTime();
  }
  
  
  Future<Map<String, dynamic>?> getCachedStatistics() async {
    return await getData('statistics');
  }

  

  
  Future<void> queueOperation(OfflineOperation operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operations = await getPendingOperations();
      operations.add(operation);
      await prefs.setString(
        _operationsKey,
        jsonEncode(operations.map((op) => op.toJson()).toList()),
      );
      _notifyChanged();
    } catch (e) {
      debugPrint('OfflineDataService.queueOperation error: $e');
    }
  }

  
  Future<List<OfflineOperation>> getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsString = prefs.getString(_operationsKey);

      if (operationsString == null) return [];

      final List<dynamic> operationsJson = jsonDecode(operationsString);
      return operationsJson
          .map((json) => OfflineOperation.fromJson(json))
          .toList();
    } catch (e) {
      return [];
    }
  }

  
  Future<void> updateOperationStatus(
    String operationId,
    SyncStatus status, {
    String? conflictReason,
  }) async {
    try {
      final operations = await getPendingOperations();
      final index = operations.indexWhere((op) => op.id == operationId);

      if (index != -1) {
        operations[index] = operations[index].copyWith(
          status: status,
          conflictReason: conflictReason,
          syncedAt: status == SyncStatus.synced ? DateTime.now() : null,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _operationsKey,
          jsonEncode(operations.map((op) => op.toJson()).toList()),
        );
        _notifyChanged();
      }
    } catch (e) {
      debugPrint('OfflineDataService.updateOperationStatus error: $e');
    }
  }

  
  Future<void> incrementRetryCount(
    String operationId, {
    DateTime? nextRetryAt,
  }) async {
    try {
      final operations = await getPendingOperations();
      final index = operations.indexWhere((op) => op.id == operationId);

      if (index != -1) {
        operations[index] = operations[index].copyWith(
          retryCount: operations[index].retryCount + 1,
          status: SyncStatus.pending,
          nextRetryAt: nextRetryAt,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _operationsKey,
          jsonEncode(operations.map((op) => op.toJson()).toList()),
        );
        _notifyChanged();
      }
    } catch (e) {
      debugPrint('OfflineDataService.incrementRetryCount error: $e');
    }
  }

  
  /// 删除队列项；若同一人员已无其他待同步操作，顺手清掉其离线缓存，
  /// 避免设置页的"离线数据"一直占空间。
  Future<void> removeOperation(String operationId) async {
    try {
      final operations = await getPendingOperations();
      final index = operations.indexWhere((op) => op.id == operationId);
      if (index == -1) return;

      final removed = operations[index];
      operations.removeAt(index);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _operationsKey,
        jsonEncode(operations.map((op) => op.toJson()).toList()),
      );

      final stillCached = operations.any((op) =>
          op.entityType == removed.entityType &&
          op.entityId == removed.entityId);
      if (!stillCached && removed.entityId.isNotEmpty) {
        await removeData('${removed.entityType}_${removed.entityId}');
      }
      _notifyChanged();
    } catch (e) {
      debugPrint('OfflineDataService.removeOperation error: $e');
    }
  }

  /// 清理历史遗留的已同步项。
  ///
  /// 旧版本同步成功后只改状态、从不出队，单 key 里的 JSON 会越滚越大；
  /// 新版同步成功即出队，此方法用于一次性收敛老数据。
  Future<int> pruneSyncedOperations() async {
    try {
      final operations = await getPendingOperations();
      final before = operations.length;
      operations.removeWhere((op) => op.status == SyncStatus.synced);
      if (operations.length == before) return 0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _operationsKey,
        jsonEncode(operations.map((op) => op.toJson()).toList()),
      );
      _notifyChanged();
      return before - operations.length;
    } catch (e) {
      debugPrint('OfflineDataService.pruneSyncedOperations error: $e');
      return 0;
    }
  }

  

  
  Future<void> saveConflict(
    OfflineOperation operation,
    Map<String, dynamic> serverData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conflicts = await getConflicts();

      conflicts.add({
        'operation': operation.toJson(),
        'server_data': serverData,
        'detected_at': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_conflictsKey, jsonEncode(conflicts));

      
      await updateOperationStatus(
        operation.id,
        SyncStatus.conflict,
        conflictReason: '数据冲突：服务器数据已更新',
      );
      _notifyChanged();
    } catch (e) {
      debugPrint('OfflineDataService.saveConflict error: $e');
    }
  }

  
  Future<List<Map<String, dynamic>>> getConflicts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final conflictsString = prefs.getString(_conflictsKey);

      if (conflictsString == null) return [];

      final List<dynamic> conflictsJson = jsonDecode(conflictsString);
      return conflictsJson.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  
  Future<void> resolveConflict(
    String operationId,
    String resolution,
  ) async {
    try {
      
      final conflicts = await getConflicts();
      conflicts.removeWhere((conflict) {
        final operation = OfflineOperation.fromJson(conflict['operation']);
        return operation.id == operationId;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_conflictsKey, jsonEncode(conflicts));

      
      if (resolution == 'use_server') {
        
        await removeOperation(operationId);
      } else if (resolution == 'use_local') {
        
        await updateOperationStatus(operationId, SyncStatus.pending);
      }
      _notifyChanged();
    } catch (e) {
      debugPrint('OfflineDataService.resolveConflict error: $e');
    }
  }

  
  Future<void> clearAllConflicts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_conflictsKey);
    } catch (e) {
      debugPrint('OfflineDataService.clearAllConflicts error: $e');
    }
  }

  

  
  /// 人员操作入离线队列。
  ///
  /// 必须显式传入 [isCreate]：data 里始终带 id_card，若用 id_card 是否为空判断，
  /// 新增人员会被误记为 update，同步时 PUT 到不存在的人，重试 3 次后永久失败。
  ///
  /// [baseUpdatedAt] 是进入编辑页时服务端记录的 `updated_at`。同步时回传，
  /// 服务端据此判断"离线期间有没有别人改过这条记录"。
  Future<void> savePersonOffline(
    Map<String, dynamic> personData, {
    required bool isCreate,
    String? baseUpdatedAt,
  }) async {
    final operation = OfflineOperation(
      id: generateId(),
      type: isCreate ? OperationType.create : OperationType.update,
      entityType: 'person',
      entityId: personData['id_card'] ?? '',
      data: personData,
      createdAt: DateTime.now(),
      baseUpdatedAt: baseUpdatedAt,
    );

    await queueOperation(operation);
    await saveData('person_${personData['id_card']}', personData);
  }

  /// 手动重试：把失败项复位为待同步，清零重试次数与退避时间。
  Future<void> resetOperationForRetry(String operationId) async {
    try {
      final operations = await getPendingOperations();
      final index = operations.indexWhere((op) => op.id == operationId);
      if (index == -1) return;

      operations[index] = operations[index].copyWith(
        status: SyncStatus.pending,
        retryCount: 0,
        // 清掉上一次的失败原因，避免重试成功后仍显示旧错误
        conflictReason: '',
        clearNextRetryAt: true,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _operationsKey,
        jsonEncode(operations.map((op) => op.toJson()).toList()),
      );
      _notifyChanged();
    } catch (e) {
      debugPrint('OfflineDataService.resetOperationForRetry error: $e');
    }
  }

  
  Future<void> saveStudentOffline(
    Map<String, dynamic> studentData, {
    required bool isCreate,
    String? baseUpdatedAt,
  }) async {
    final operation = OfflineOperation(
      id: generateId(),
      type: isCreate ? OperationType.create : OperationType.update,
      entityType: 'student',
      entityId: studentData['id_card'] ?? '',
      data: studentData,
      createdAt: DateTime.now(),
      baseUpdatedAt: baseUpdatedAt,
    );

    await queueOperation(operation);
    await saveData('student_${studentData['id_card']}', studentData);
  }

  
  String generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
