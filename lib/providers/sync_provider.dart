
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_data_service.dart';

enum SyncState {
  idle,
  syncing,
  success,
  error,
}

class SyncProvider with ChangeNotifier {
  SyncState _state = SyncState.idle;
  int _pendingCount = 0;
  int _conflictCount = 0;
  String? _errorMessage;
  String? _lastSyncTime;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  SyncState get state => _state;
  int get pendingCount => _pendingCount;
  int get conflictCount => _conflictCount;
  String? get errorMessage => _errorMessage;
  String? get lastSyncTime => _lastSyncTime;
  bool get hasPendingOperations => _pendingCount > 0;
  bool get hasConflicts => _conflictCount > 0;
  bool get isSyncing => _state == SyncState.syncing;

  
  Future<void> init() async {
    await loadStatus();
    _listenToConnectivity();
  }

  
  void _listenToConnectivity() {
    _connectivitySubscription = ConnectivityService()
        .onConnectivityChanged
        .listen((results) async {
      
      if (!results.contains(ConnectivityResult.none)) {
        await autoSync();
      }
    });
  }

  
  Future<void> loadStatus() async {
    _pendingCount = await SyncService().getPendingCount();
    _conflictCount = await SyncService().getConflictCount();
    notifyListeners();
  }

  
  Future<void> autoSync() async {
    if (isSyncing) return;

    await syncAll();
  }

  
  Future<void> syncAll() async {
    if (isSyncing) return;

    _state = SyncState.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await SyncService().syncAll();

      _state = result.isSuccess ? SyncState.success : SyncState.error;
      _lastSyncTime = DateTime.now().toIso8601String();

      // 持久化最后同步时间，供设置页"数据同步 / 最后同步时间"展示。
      // （此前只写内存，OfflineDataService.getLastSyncTime() 永远读不到，
      //  导致手动/自动同步后设置页时间不更新，看起来像"数据同步没生效"。）
      await OfflineDataService().updateLastSyncTime();

      if (!result.isSuccess) {
        _errorMessage = '同步失败: ${result.summary}';
      }

      await loadStatus();
    } catch (e) {
      _state = SyncState.error;
      _errorMessage = '同步失败: $e';
      // 即使整轮同步抛异常，也记录本次同步尝试时间，避免用户误以为从未同步。
      await OfflineDataService().updateLastSyncTime();
      notifyListeners();
    }
  }

  
  Future<void> resolveConflict(String operationId, String resolution) async {
    await OfflineDataService().resolveConflict(operationId, resolution);
    await loadStatus();
  }

  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
