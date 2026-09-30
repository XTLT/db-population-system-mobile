
import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthApi {
  static final _dio = ApiClient().dio;
  
  
  
  
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // 发送原始密码以支持 Argon2id 验证（HTTPS 加密传输）
      final response = await _dio.post('/api/login', data: {
        'username': username,
        'password': password,
        'password_hashed': false,
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return {
            'success': true,
            'token': data['token'],
            'user': User(
              username: username,
              role: data['user']?['role'],
              token: data['token'],
            ),
            'require_password_change': data['require_password_change'] ?? false,
          };
        } else {
          return {
            'success': false,
            'error': data['error'] ?? '登录失败',
          };
        }
      } else {
        return {
          'success': false,
          'error': '服务器错误: ${response.statusCode}',
        };
      }
    } on DioException catch (e) {
      String errorMessage = '网络错误';
      
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = '连接超时，请检查网络';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '无法连接服务器，请检查域名配置';
      } else {
        final errorData = e.response?.data;
        if (errorData != null && errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'error': '登录失败: $e',
      };
    }
  }
  
  
  static Future<bool> checkToken(String token) async {
    try {
      // 显式把入参 token 放进 Authorization 头，不依赖已登录态拦截器。
      final response = await _dio.get(
        '/api/check_token',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 && response.data['valid'] == true;
    } catch (e) {
      return false;
    }
  }
  
  
  
  static Future<Map<String, dynamic>> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    try {
      // 发送原始密码以支持 Argon2id 验证
      final response = await _dio.post('/api/change_password', data: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'password_hashed': false,
      });

      final data = response.data;
      if (data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? '修改密码失败',
        };
      }
      // HTTP 200 但业务 success==false：失败即抛异常，消息透传服务端 message。
      throw Exception(data['message'] ?? '修改密码失败');
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('修改密码失败: $e');
    } catch (e) {
      throw Exception('修改密码失败: $e');
    }
  }


  static Future<Map<String, dynamic>> forceChangePassword(
    String newPassword,
  ) async {
    try {
      final response = await _dio.post('/api/users/me/change-password', data: {
        'password': newPassword,
      });

      final data = response.data;
      if (data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? '修改密码失败',
        };
      }
      // HTTP 200 但业务 success==false：失败即抛异常，消息透传服务端 message。
      throw Exception(data['message'] ?? '修改密码失败');
    } on DioException catch (e) {
      final errorData = e.response?.data;
      if (errorData != null && errorData['error'] != null) {
        throw Exception(errorData['error']);
      }
      throw Exception('修改密码失败');
    } catch (e) {
      throw Exception('修改密码失败: $e');
    }
  }
}
