import 'package:flutter/foundation.dart';
import '../api/operation_log_api.dart';
import '../models/operation_log.dart';


class OperationLogProvider extends ChangeNotifier {
  List<OperationLog> _logs = [];
  List<String> _operationTypes = [];
  Map<String, dynamic> _stats = {};
  
  bool _isLoading = false;
  String? _errorMessage;
  
  
  String? _filterUsername;
  String? _filterOperationType;
  String? _filterStartDate;
  String? _filterEndDate;
  
  
  List<OperationLog> get logs => _logs;
  List<String> get operationTypes => _operationTypes;
  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  
  Future<void> loadLogs({bool refresh = false}) async {
    if (_isLoading) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _logs = await OperationLogApi.getOperationLogs(
        limit: 100,
        username: _filterUsername,
        operationType: _filterOperationType,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
      );
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  
  Future<void> loadOperationTypes() async {
    try {
      _operationTypes = await OperationLogApi.getOperationTypes();
      notifyListeners();
    } catch (e) {
      debugPrint('加载操作类型失败: $e');
    }
  }
  
  
  Future<void> loadStats() async {
    try {
      _stats = await OperationLogApi.getOperationLogStats();
      notifyListeners();
    } catch (e) {
      debugPrint('加载统计信息失败: $e');
    }
  }
  
  
  Future<void> setFilters({
    String? username,
    String? operationType,
    String? startDate,
    String? endDate,
  }) async {
    _filterUsername = username;
    _filterOperationType = operationType;
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    
    await loadLogs(refresh: true);
  }
  
  
  Future<void> clearFilters() async {
    _filterUsername = null;
    _filterOperationType = null;
    _filterStartDate = null;
    _filterEndDate = null;
    
    await loadLogs(refresh: true);
  }
  
  
  Map<String, String?> get currentFilters => {
    'username': _filterUsername,
    'operationType': _filterOperationType,
    'startDate': _filterStartDate,
    'endDate': _filterEndDate,
  };
}
