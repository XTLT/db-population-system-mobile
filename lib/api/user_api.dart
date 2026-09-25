
import 'api_client.dart';
import '../models/user_info.dart';

class UserApi {
  static final _dio = ApiClient().dio;

  
  static Future<List<UserInfo>> getUserList() async {
    try {
      final response = await _dio.get('/api/users/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['users'] ?? [];
        return data.map((json) => UserInfo.fromJson(json)).toList();
      } else {
        throw Exception('获取用户列表失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取用户列表失败: $e');
    }
  }

  
  static Future<Map<String, dynamic>> createUser({
    required String username,
    required String password,
    String realName = '',
    String role = 'user',
  }) async {
    try {
      final response = await _dio.post('/api/users/', data: {
        'username': username,
        'password': password,
        'real_name': realName,
        'role': role,
      });

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('创建用户失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('创建用户失败: $e');
    }
  }

  
  static Future<UserInfo> updateUser(
    String userId, {
    String? realName,
    String? role,
    String? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (realName != null) data['real_name'] = realName;
      if (role != null) data['role'] = role;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _dio.put('/api/users/$userId', data: data);

      if (response.statusCode == 200) {
        return UserInfo.fromJson(response.data);
      } else {
        throw Exception('更新用户失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('更新用户失败: $e');
    }
  }

  
  static Future<bool> deleteUser(String userId) async {
    try {
      final response = await _dio.delete('/api/users/$userId');

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('删除用户失败: $e');
    }
  }

  
  static Future<bool> resetPassword(String userId, String newPassword) async {
    try {
      final response = await _dio.post(
        '/api/users/$userId/reset-password',
        data: {'password': newPassword},
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('重置密码失败: $e');
    }
  }
}
