import 'dart:convert';
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
  /// token 是否已被服务器明确确认有效。
  /// false 表示当前为乐观登录态：本地有 token 但尚未与服务器确认
  /// （常见于切后台回来时网络尚未恢复），UI 可据此提示「离线/待验证」。
  bool _tokenVerified = false;


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
  bool get tokenVerified => _tokenVerified;
  bool get isAdmin => _user?.role == 'admin';


  /// 应用启动 / 切后台回来时恢复登录态。
  ///
  /// 修复要点：
  /// 1. 本地存在 token 即先乐观置为已登录（避免闪登录页），再异步向服务器校验；
  /// 2. 只有服务器「明确判定 token 无效」（401/403 或 valid=false）才 logout；
  /// 3. 网络/服务层异常（超时、连接失败、5xx 等）一律保留登录态，
  ///    不再因瞬时网络抖动把用户踢回登录页。
  Future<void> init() async {
    _token = await _secureStorage.read(key: 'auth_token');


    final prefs = await SharedPreferences.getInstance();
    final userRaw = prefs.getString('user_data');

    Map<String, dynamic>? userMap;
    if (userRaw != null) {
      try {
        userMap = Map<String, dynamic>.from(jsonDecode(userRaw) as Map);
      } catch (_) {
        // 历史脏数据（旧版本曾存入 Dart Map.toString() 而非 JSON）：
        // 解析失败时 user 置空，但不影响 token 登录态恢复
        userMap = null;
      }
    }

    if (_token != null) {
      // 1) 乐观恢复：本地 token/user 仍在，先按已登录处理
      if (userMap != null) {
        _user = User.fromJson(userMap);
      }
      _isLoggedIn = true;
      ApiClient().setToken(_token!);

      // 2) 再向服务器校验 token；网络异常不登出
      try {
        final result = await AuthApi.checkToken(_token!);
        if (result == CheckTokenResult.invalid) {
          // 服务器明确判定 token 失效 → 登出
          await logout();
        } else if (result == CheckTokenResult.valid) {
          _tokenVerified = true;
        }
        // unavailable：保持登录态，_tokenVerified 维持 false
      } catch (_) {
        // checkToken 自身异常：保守保留登录态，不误判登出
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
        _tokenVerified = true;
        _token = result['token'];
        _user = result['user'];


        await _secureStorage.write(key: 'auth_token', value: _token!);

        final prefs = await SharedPreferences.getInstance();
        // 以标准 JSON 持久化 user 信息，供下次启动恢复
        await prefs.setString('user_data', jsonEncode(_user!.toJson()));


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
    _tokenVerified = false;
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
