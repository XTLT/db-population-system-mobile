import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/models/user_info.dart';

void main() {
  group('UserInfo Model Tests', () {
    test('fromJson 应字段级解析全部 9 个字段', () {
      final json = {
        'id': 'u-1',
        'username': 'admin',
        'real_name': '管理员',
        'role': 'admin',
        'is_active': '是',
        'is_default': '否',
        'created_at': '2026-01-01T00:00:00',
        'last_login': '2026-09-30T09:00:00',
        'login_attempts': '3',
      };

      final u = UserInfo.fromJson(json);

      expect(u.id, 'u-1');
      expect(u.username, 'admin');
      expect(u.realName, '管理员');
      expect(u.role, 'admin');
      expect(u.isActive, '是');
      expect(u.isDefault, '否');
      expect(u.createdAt, '2026-01-01T00:00:00');
      expect(u.lastLogin, '2026-09-30T09:00:00');
      expect(u.loginAttempts, '3');
    });

    test('fromJson 缺省默认值应正确（role=user, is_active=是, is_default=否, login_attempts=0）', () {
      final u = UserInfo.fromJson(<String, dynamic>{});
      expect(u.id, '');
      expect(u.username, '');
      expect(u.realName, '');
      expect(u.role, 'user');
      expect(u.isActive, '是');
      expect(u.isDefault, '否');
      expect(u.createdAt, '');
      expect(u.lastLogin, '');
      expect(u.loginAttempts, '0');
    });

    test('toJson 应输出全部字段并往返一致', () {
      final u = UserInfo(
        id: 'u-2',
        username: 'viewer',
        realName: '查看者',
        role: 'viewer',
        isActive: '是',
        isDefault: '是',
        createdAt: '2026-02-01T00:00:00',
        lastLogin: '2026-09-29T08:00:00',
        loginAttempts: '0',
      );

      final json = u.toJson();
      expect(json['id'], 'u-2');
      expect(json['username'], 'viewer');
      expect(json['real_name'], '查看者');
      expect(json['role'], 'viewer');
      expect(json['is_active'], '是');
      expect(json['is_default'], '是');
      expect(json['created_at'], '2026-02-01T00:00:00');
      expect(json['last_login'], '2026-09-29T08:00:00');
      expect(json['login_attempts'], '0');

      final back = UserInfo.fromJson(json);
      expect(back.id, u.id);
      expect(back.username, u.username);
      expect(back.realName, u.realName);
      expect(back.role, u.role);
      expect(back.isActive, u.isActive);
      expect(back.isDefault, u.isDefault);
      expect(back.createdAt, u.createdAt);
      expect(back.lastLogin, u.lastLogin);
      expect(back.loginAttempts, u.loginAttempts);
    });

    test('isAdmin 应在 role=="admin" 时为 true', () {
      expect(UserInfo(id: '', username: '', realName: '', role: 'admin', isActive: '是', isDefault: '否', createdAt: '', lastLogin: '', loginAttempts: '').isAdmin, true);
      expect(UserInfo(id: '', username: '', realName: '', role: 'user', isActive: '是', isDefault: '否', createdAt: '', lastLogin: '', loginAttempts: '').isAdmin, false);
    });

    test('isActiveUser / isDefaultUser 应按 是 判断', () {
      expect(
          UserInfo(id: '', username: '', realName: '', role: 'user', isActive: '是', isDefault: '是', createdAt: '', lastLogin: '', loginAttempts: '').isActiveUser,
          true);
      expect(
          UserInfo(id: '', username: '', realName: '', role: 'user', isActive: '否', isDefault: '是', createdAt: '', lastLogin: '', loginAttempts: '').isActiveUser,
          false);
      expect(
          UserInfo(id: '', username: '', realName: '', role: 'user', isActive: '是', isDefault: '是', createdAt: '', lastLogin: '', loginAttempts: '').isDefaultUser,
          true);
      expect(
          UserInfo(id: '', username: '', realName: '', role: 'user', isActive: '是', isDefault: '否', createdAt: '', lastLogin: '', loginAttempts: '').isDefaultUser,
          false);
    });
  });
}
