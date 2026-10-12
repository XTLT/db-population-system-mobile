import 'package:dio/dio.dart';
import '../models/user.dart';
import 'api_client.dart';

/// checkToken 校验结果。
///
/// 切后台回来 / 冷启动时本地存有 token，需要向服务器确认是否仍有效。
/// 关键：必须区分「服务器明确判定 token 无效」与「网络/服务层异常」——
/// 后者不能据此登出，否则瞬时网络抖动会把用户踢回登录页。
enum CheckTokenResult {
  /// 服务器明确判定 token 有效（HTTP 200 且 valid=true）。
  valid,

  /// 服务器明确判定 token 无效（HTTP 401/403，或响应 valid=false）→ 应登出。
  invalid,

  /// 网络/服务层异常（连接超时、连接失败、5xx、证书错误、取消等）→
  /// 无法判定 token 是否有效，应保留登录态，待网络恢复后再校验。
  unavailable,
}

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
  

  /// 校验本地 token 是否仍然有效。
  ///
  /// 三态返回，严禁把网络异常当作「token 无效」：
  /// - 服务器返回 200 且 valid=true            → [CheckTokenResult.valid]
  /// - 服务器返回 401/403，或 200 但 valid=false → [CheckTokenResult.invalid]（应登出）
  /// - 超时/连接失败/5xx/证书错误/解析异常等     → [CheckTokenResult.unavailable]（保留登录态）
  static Future<CheckTokenResult> checkToken(String token) async {
    try {
      // 显式把入参 token 放进 Authorization 头，不依赖已登录态拦截器。
      final response = await _dio.get(
        '/api/check_token',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200 && response.data['valid'] == true) {
        return CheckTokenResult.valid;
      }
      // 有响应但未确认有效（如 valid=false）：服务器明确判定无效
      return CheckTokenResult.invalid;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        // 服务器明确拒绝该 token → 真正失效，应登出
        return CheckTokenResult.invalid;
      }
      // 其余均为网络/服务层异常（连接超时、连接失败、5xx、证书错误、取消等）：
      // 不能据此判定 token 失效，保留登录态
      return CheckTokenResult.unavailable;
    } catch (_) {
      // 响应解析等未知异常：保守视为不可用，不误判 token 失效
      return CheckTokenResult.unavailable;
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
      // 发送原始密码以支持 Argon2id 验证
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
      throw Exception(errorData['error']);
    } catch (e) {
      throw Exception('修改密码失败');
    }
  }
}