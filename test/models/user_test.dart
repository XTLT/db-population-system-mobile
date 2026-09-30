import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/user.dart';

void main() {
  group('User Model Tests', () {
    test('fromJson 应字段级解析 username/role/token', () {
      final json = {
        'username': 'admin',
        'role': 'admin',
        'token': 'tok-123',
      };

      final u = User.fromJson(json);

      expect(u.username, 'admin');
      expect(u.role, 'admin');
      expect(u.token, 'tok-123');
    });

    test('fromJson username 缺失时回退为空串（role/token 可空）', () {
      final u = User.fromJson(<String, dynamic>{});
      expect(u.username, '');
      expect(u.role, isNull);
      expect(u.token, isNull);
    });

    test('toJson 应输出全部字段并往返一致', () {
      final u = User(username: 'editor', role: 'user', token: 'tok-abc');
      final json = u.toJson();

      expect(json['username'], 'editor');
      expect(json['role'], 'user');
      expect(json['token'], 'tok-abc');

      final back = User.fromJson(json);
      expect(back.username, u.username);
      expect(back.role, u.role);
      expect(back.token, u.token);
    });

    test('toJson 应保留 null role/token（key 存在但值为 null）', () {
      final u = User(username: 'guest');
      final json = u.toJson();
      expect(json['username'], 'guest');
      expect(json['role'], isNull);
      expect(json['token'], isNull);
    });
  });
}
