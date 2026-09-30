import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:population_mobile/api/api_client.dart';
import 'package:population_mobile/api/auth_api.dart';
import 'package:population_mobile/models/user.dart';

import '../test_helpers.dart';

/// 从 RequestOptions 中取请求体（兼容 options.data 为 Map 或已被 transformer
/// 序列化为 JSON String 两种情况）。
Map<String, dynamic> bodyOf(RequestOptions options) {
  final data = options.data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String && data.isNotEmpty) {
    return jsonDecode(data) as Map<String, dynamic>;
  }
  return {};
}

void main() {
  ensureTestBinding();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetApiClientState();
  });

  group('AuthApi.login', () {
    test('成功：POST /api/login，body 含 username/password/password_hashed，解析 token/user', () async {
      final rec = installMockAdapter((options) {
        return jsonResponse({
          'success': true,
          'token': 'tok_xyz_123',
          'user': {'role': 'admin'},
          'require_password_change': true,
        });
      });

      final result = await AuthApi.login('alice', 'secret123');

      final req = rec.last()!;
      expect(req.path, '/api/login');
      expect(req.method, 'POST');
      final body = bodyOf(req);
      expect(body['username'], 'alice');
      expect(body['password'], 'secret123');
      expect(body['password_hashed'], false);

      expect(result['success'], true);
      expect(result['token'], 'tok_xyz_123');
      expect(result['require_password_change'], true);
      final user = result['user'] as User;
      expect(user.username, 'alice');
      expect(user.role, 'admin');
      expect(user.token, 'tok_xyz_123');
    });

    test('成功缺省 require_password_change：默认为 false', () async {
      installMockAdapter((options) => jsonResponse({
            'success': true,
            'token': 't',
            'user': {'role': 'user'},
          }));
      final r = await AuthApi.login('bob', 'pw');
      expect(r['require_password_change'], false);
    });

    test('业务失败（HTTP 200 但 success=false）：返回 error 字段', () async {
      installMockAdapter((options) => jsonResponse({
            'success': false,
            'error': '用户名或密码错误',
          }));
      final r = await AuthApi.login('alice', 'wrong');
      expect(r['success'], false);
      expect(r['error'], '用户名或密码错误');
    });

    test('业务失败缺省 error：回退为「登录失败」', () async {
      installMockAdapter((options) => jsonResponse({'success': false}));
      final r = await AuthApi.login('alice', 'wrong');
      expect(r['success'], false);
      expect(r['error'], '登录失败');
    });

    test('HTTP 401（badResponse）：走 DioException 分支，读取 response.data.error', () async {
      installMockAdapter((options) => jsonResponse({'error': '未授权'}, statusCode: 401));
      final r = await AuthApi.login('alice', 'x');
      expect(r['success'], false);
      expect(r['error'], '未授权');
    });

    test('HTTP 500 且无 error 字段：errorMessage 回退为「网络错误」', () async {
      installMockAdapter((options) => jsonResponse({'detail': 'boom'}, statusCode: 500));
      final r = await AuthApi.login('alice', 'x');
      expect(r['success'], false);
      expect(r['error'], '网络错误');
    });
  });

  group('AuthApi.checkToken', () {
    test('valid=true 时返回 true，GET /api/check_token', () async {
      final rec = installMockAdapter((options) => jsonResponse({'valid': true}));
      expect(await AuthApi.checkToken('any-token'), true);
      final req = rec.last()!;
      expect(req.path, '/api/check_token');
      expect(req.method, 'GET');
    });

    test('valid=false 时返回 false', () async {
      installMockAdapter((options) => jsonResponse({'valid': false}));
      expect(await AuthApi.checkToken('any-token'), false);
    });

    test('响应缺省 valid 字段：视为 false', () async {
      installMockAdapter((options) => jsonResponse({}));
      expect(await AuthApi.checkToken('any-token'), false);
    });

    test('HTTP 500：任何异常吞掉并返回 false', () async {
      installMockAdapter((options) => jsonResponse({}, statusCode: 500));
      expect(await AuthApi.checkToken('any-token'), false);
    });

    test('注意：入参 token 不会放入 query/body，而是进入 Authorization 头', () async {
      final rec = installMockAdapter((options) => jsonResponse({'valid': true}));
      await AuthApi.checkToken('passed-in-token');
      final req = rec.last()!;
      expect(req.queryParameters.containsKey('token'), false);
      expect(req.data == null || (req.data as Map).isEmpty, true);
    });

    test('入参 token 显式进入 Authorization: Bearer <token> 头（不依赖已登录态）', () async {
      // setUp 已 resetApiClientState()，无已登录 token，头应来自入参。
      final rec = installMockAdapter((options) => jsonResponse({'valid': true}));
      await AuthApi.checkToken('passed-in-token');
      expect(rec.last()!.headers['Authorization'], 'Bearer passed-in-token');
    });
  });

  group('AuthApi.changePassword', () {
    test('成功：POST /api/change_password，body 含 old/new password', () async {
      final rec = installMockAdapter((options) => jsonResponse({
            'success': true,
            'message': '修改成功',
          }));
      final r = await AuthApi.changePassword('old123', 'new456');
      final req = rec.last()!;
      expect(req.path, '/api/change_password');
      expect(req.method, 'POST');
      final body = bodyOf(req);
      expect(body['old_password'], 'old123');
      expect(body['new_password'], 'new456');
      expect(body['password_hashed'], false);
      expect(r['success'], true);
      expect(r['message'], '修改成功');
    });

    // 源码真实行为（auth_api.dart changePassword）：HTTP 200 但业务 success=false 时，
    // changePassword **抛 Exception**，消息透传 response.data['message']。
    test('业务 success=false：抛 Exception 且消息透传 message', () async {
      installMockAdapter((options) => jsonResponse({'success': false, 'message': '原密码错误'}));
      expect(
        () => AuthApi.changePassword('a', 'b'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('原密码错误'))),
      );
    });

    test('响应缺省 message（success=true）：回退为「修改密码失败」', () async {
      installMockAdapter((options) => jsonResponse({'success': true}));
      final r = await AuthApi.changePassword('a', 'b');
      expect(r['message'], '修改密码失败');
    });

    test('HTTP 500：网络错误分支抛 Exception，消息含「修改密码失败」', () async {
      installMockAdapter((options) => jsonResponse({}, statusCode: 500));
      expect(
        () => AuthApi.changePassword('a', 'b'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('修改密码失败'))),
      );
    });
  });

  group('AuthApi.forceChangePassword', () {
    test('成功：POST /api/users/me/change-password，body 仅含 password', () async {
      final rec = installMockAdapter((options) => jsonResponse({
            'success': true,
            'message': '已强制修改',
          }));
      final r = await AuthApi.forceChangePassword('freshpw');
      final req = rec.last()!;
      expect(req.path, '/api/users/me/change-password');
      expect(req.method, 'POST');
      expect(bodyOf(req), {'password': 'freshpw'});
      expect(r['success'], true);
      expect(r['message'], '已强制修改');
    });

    test('HTTP 错误带 error 字段：DioException 分支抛 Exception，消息透传 error', () async {
      installMockAdapter((options) => jsonResponse({'error': '旧密码不匹配'}, statusCode: 400));
      expect(
        () => AuthApi.forceChangePassword('x'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('旧密码不匹配'))),
      );
    });

    test('HTTP 错误无 error 字段：抛 Exception，消息回退为「修改密码失败」', () async {
      installMockAdapter((options) => jsonResponse({}, statusCode: 500));
      expect(
        () => AuthApi.forceChangePassword('x'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'msg', contains('修改密码失败'))),
      );
    });
  });

  group('Token / Authorization 头', () {
    test('已登录态下拦截器注入存储 token；清除后 checkToken 改用入参 token', () async {
      // 1) 已登录（setToken）：拦截器用存储 token 覆盖，入参 token 被覆盖
      ApiClient().setToken('bearer-token-aaa');
      final rec = installMockAdapter((options) => jsonResponse({'valid': true}));
      await AuthApi.checkToken('x');
      expect(rec.last()!.headers['Authorization'], 'Bearer bearer-token-aaa');

      // 2) 清除登录态后：拦截器不再注入，checkToken 仍显式发送入参 token（不依赖登录态）
      resetApiClientState(); // clearToken + resetEffectiveBaseUrl
      await AuthApi.checkToken('passed-tok');
      final afterClear = rec.last()!;
      expect(afterClear.headers['Authorization'], 'Bearer passed-tok');
    });
  });
}
