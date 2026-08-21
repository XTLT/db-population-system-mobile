
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/offline_operation.dart';
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

      if (!result.isSuccess) {
        _errorMessage = '同步失败: ${result.summary}';
      }

      await loadStatus();
    } catch (e) {
      _state = SyncState.error;
      _errorMessage = '同步失败: $e';
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
