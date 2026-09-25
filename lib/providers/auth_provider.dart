import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../api/auth_api.dart';
import '../api/api_client.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _token;
  User? _user;
  bool _isLoading = false;
  
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAdmin => _user?.role == 'admin';
  
  
  Future<void> init() async {
    
    _token = await _secureStorage.read(key: 'auth_token');
    
    
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    
    if (_token != null && userJson != null) {
      try {
        _user = User.fromJson(
          Map<String, dynamic>.from(
            Map<String, dynamic>.from(
              prefs.getString('user_data') as Map
            )
          )
        );
        
        
        final isValid = await AuthApi.checkToken(_token!);
        if (isValid) {
          _isLoggedIn = true;
          ApiClient().setToken(_token!);
        } else {
          
          await logout();
        }
      } catch (e) {
        
        await logout();
      }
    }
    
    notifyListeners();
  }
  
  
  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final result = await AuthApi.login(username, password);
      
      if (result['success'] == true) {
        _isLoggedIn = true;
        _token = result['token'];
        _user = result['user'];
        
        
        await _secureStorage.write(key: 'auth_token', value: _token!);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', _user!.toJson().toString());
        
        
        ApiClient().setToken(_token!);
        
        notifyListeners();
        return {
          'success': true,
          'require_password_change': result['require_password_change'] ?? false,
        };
      } else {
        return {'success': false, 'error': result['error']};
      }
    } catch (e) {
      return {'success': false, 'error': '登录失败: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  
  Future<void> logout() async {
    _isLoggedIn = false;
    _token = null;
    _user = null;
    
    
    await _secureStorage.delete(key: 'auth_token');
    
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    
    
    ApiClient().clearToken();
    
    notifyListeners();
  }
  
  
  Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final result = await AuthApi.changePassword(oldPassword, newPassword);
      return result;
    } catch (e) {
      return {'success': false, 'message': '修改密码失败: $e'};
    }
  }
  
  
  Future<Map<String, dynamic>> forceChangePassword(String newPassword) async {
    try {
      final result = await AuthApi.forceChangePassword(newPassword);
      return result;
    } catch (e) {
      return {'success': false, 'message': '修改密码失败: $e'};
    }
  }
}
