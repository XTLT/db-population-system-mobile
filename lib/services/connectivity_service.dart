
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();

  
  Future<bool> isConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return !results.contains(ConnectivityResult.none);
    } catch (e) {
      debugPrint('检查网络连接失败: $e');
      return false;
    }
  }

  
  Future<List<ConnectivityResult>> getConnectivityType() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('获取连接类型失败: $e');
      return [ConnectivityResult.none];
    }
  }

  
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
