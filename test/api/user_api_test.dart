// UserApi 单元测试（传输层 mock，不触达真实网络）
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/api/user_api.dart';
import 'package:population_mobile/models/user_info.dart';

import '../test_helpers.dart';

Map<String, dynamic> _userJson(String id) => {
      'id': id,
      'username': 'user_$id',
      'real_name': '张三$id',
      'role': 'admin',
      'is_active': '是',
      'is_default': '否',
      'created_at': '2024-01-01 10:00:00',
      'last_login': '2024-01-02 09:00:00',
      'login_attempts': '0',
    };

void main() {
  ensureTestBinding();

  group('UserApi.getUserList', () {
    late RequestRecorder rec;

    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async {
        if (options.path == '/api/users/' && options.method == 'GET') {
          return jsonResponse({
            'users': [_userJson('1'), _userJson('2')],
          });
        }
        return jsonResponse({}, statusCode: 404);
      });
    });

    test('GET /api/users/ 并解析为 UserInfo 列表', () async {
      final list = await UserApi.getUserList();
      final req = rec.last()!;
      expect(req.method, 'GET');
      expect(req.path, '/api/users/');
      expect(list, hasLength(2));
      expect(list[0], isA<UserInfo>());
      expect(list[0].id, '1');
      expect(list[0].username, 'user_1');
      expect(list[0].isAdmin, isTrue);
    });

    test('users 缺省时返回空列表', () async {
      installMockAdapter((options) async => jsonResponse({'users': []}));
      final list = await UserApi.getUserList();
      expect(list, isEmpty);
    });

    test('非 200（201）响应抛异常', () async {
      installMockAdapter((options) async =>
          jsonResponse({}, statusCode: 201));
      expect(
        UserApi.getUserList(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('获取用户列表失败'))),
      );
    });

    test('服务端 500 抛 DioException 并被包装', () async {
      installMockAdapter(
          (options) async => jsonResponse({'error': 'boom'}, statusCode: 500));
      expect(
        UserApi.getUserList(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'msg', contains('获取用户列表失败'))),
      );
    });
  });

  group('UserApi.createUser', () {
    late RequestRecorder rec;

    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async {
        if (options.path == '/api/users/' && options.method == 'POST') {
          return jsonResponse({'success': true, 'id': '9'});
        }
        return jsonResponse({}, statusCode: 404);
      });
    });

    test('POST /api/users/ 携带完整字段并透传响应', () async {
      final result = await UserApi.createUser(
        username: 'zhangsan',
        password: 'pwd123',
        realName: '张三',
        role: 'admin',
      );
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/users/');
      expect(req.data, isA<Map>());
      expect(req.data['username'], 'zhangsan');
      expect(req.data['password'], 'pwd123');
      expect(req.data['real_name'], '张三');
      expect(req.data['role'], 'admin');
      expect(result['success'], isTrue);
      expect(result['id'], '9');
    });

    test('realName/role 使用默认值', () async {
      await UserApi.createUser(username: 'lisi', password: 'x');
      final data = rec.last()!.data as Map;
      expect(data['real_name'], '');
      expect(data['role'], 'user');
    });

    test('500 时抛异常', () async {
      installMockAdapter((options) async =>
          jsonResponse({'error': '服务器错'}, statusCode: 500));
      expect(
        UserApi.createUser(username: 'a', password: 'b'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('创建用户失败'))),
      );
    });
  });

  group('UserApi.updateUser', () {
    late RequestRecorder rec;

    setUp(() {
      resetApiClientState();
      rec = installMockAdapter((options) async {
        if (options.path == '/api/users/42' && options.method == 'PUT') {
          // 服务端真实契约：成功仅返回 {'success': true}，不回传 user 对象
          return jsonResponse({'success': true});
        }
        return jsonResponse({}, statusCode: 404);
      });
    });

    test('PUT /api/users/42 仅发送非空字段，按真实契约返回 success=true', () async {
      final ok = await UserApi.updateUser('42', realName: '新名字', role: 'admin');
      final req = rec.last()!;
      expect(req.method, 'PUT');
      expect(req.path, '/api/users/42');
      final data = req.data as Map;
      expect(data['real_name'], '新名字');
      expect(data['role'], 'admin');
      expect(data.containsKey('is_active'), isFalse);
      expect(ok, isTrue);
    });

    test('三个字段都为空时 body 为空 map', () async {
      await UserApi.updateUser('42');
      expect(rec.last()!.data as Map, isEmpty);
    });

    test('500 时抛异常', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        UserApi.updateUser('42', realName: 'x'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('更新用户失败'))),
      );
    });
  });

  group('UserApi.deleteUser', () {
    late RequestRecorder rec;

    setUp(() => resetApiClientState());

    test('DELETE /api/users/42 且 200 返回 true', () async {
      rec = installMockAdapter(
          (options) async => jsonResponse({'success': true}));
      expect(await UserApi.deleteUser('42'), isTrue);
      expect(rec.last()!.method, 'DELETE');
      expect(rec.last()!.path, '/api/users/42');
    });

    test('非 200（201）返回 false 而非抛异常', () async {
      installMockAdapter((options) async =>
          jsonResponse({'success': false}, statusCode: 201));
      expect(await UserApi.deleteUser('42'), isFalse);
    });

    test('500 时抛异常', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        UserApi.deleteUser('42'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('删除用户失败'))),
      );
    });
  });

  group('UserApi.resetPassword', () {
    late RequestRecorder rec;

    setUp(() => resetApiClientState());

    test('POST /api/users/42/reset-password 携带新密码，200 返回 true', () async {
      rec = installMockAdapter((options) async => jsonResponse({'ok': true}));
      expect(await UserApi.resetPassword('42', 'newPwd123'), isTrue);
      final req = rec.last()!;
      expect(req.method, 'POST');
      expect(req.path, '/api/users/42/reset-password');
      expect(req.data['password'], 'newPwd123');
    });

    test('500 时抛异常', () async {
      installMockAdapter(
          (options) async => jsonResponse({}, statusCode: 500));
      expect(
        UserApi.resetPassword('42', 'x'),
        throwsA(isA<Exception>()
            .having((e) => e.toString(), 'msg', contains('重置密码失败'))),
      );
    });
  });
}
