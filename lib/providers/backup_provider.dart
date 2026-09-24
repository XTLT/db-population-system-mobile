import 'package:flutter/foundation.dart';
import '../api/backup_api.dart';
import '../models/backup_info.dart';


class BackupProvider extends ChangeNotifier {
  List<BackupInfo> _backups = [];
  Map<String, dynamic>? _status;
  bool _isLoading = false;
  String? _errorMessage;

  
  List<BackupInfo> get backups => _backups;
  Map<String, dynamic>? get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  
  Future<void> loadBackups() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _backups = await BackupApi.getBackupList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  
  Future<void> loadStatus() async {
    try {
      _status = await BackupApi.getBackupStatus();
      notifyListeners();
    } catch (e) {
      debugPrint('加载备份状态失败: $e');
    }
  }

  
  Future<bool> createBackup() async {
    try {
      final result = await BackupApi.createBackup();
      if (result['success'] == true) {
        await loadBackups();
        await loadStatus();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  
  Future<bool> restoreBackup(String backupPath, {String? password}) async {
    try {
      final result = await BackupApi.restoreBackup(backupPath, password: password);
      return result['success'] == true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBackup(String name) async {
    try {
      final result = await BackupApi.deleteBackup(name);
      if (result['success'] == true) {
        _backups.removeWhere((b) => b.path == name);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
