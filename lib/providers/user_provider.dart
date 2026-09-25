import 'package:flutter/foundation.dart';
import '../api/user_api.dart';
import '../models/user_info.dart';


class UserProvider extends ChangeNotifier {
  List<UserInfo> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  
  List<UserInfo> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  
  Future<void> loadUsers() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await UserApi.getUserList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  
  Future<bool> createUser({
    required String username,
    required String password,
    String realName = '',
    String role = 'user',
  }) async {
    try {
      await UserApi.createUser(
        username: username,
        password: password,
        realName: realName,
        role: role,
      );
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  
  Future<bool> updateUser(
    String userId, {
    String? realName,
    String? role,
    String? isActive,
  }) async {
    try {
      await UserApi.updateUser(
        userId,
        realName: realName,
        role: role,
        isActive: isActive,
      );
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  
  Future<bool> deleteUser(String userId) async {
    try {
      await UserApi.deleteUser(userId);
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  
  Future<bool> resetPassword(String userId, String newPassword) async {
    try {
      await UserApi.resetPassword(userId, newPassword);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
