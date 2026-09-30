import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/utils/security_utils.dart';

void main() {
  group('SecurityUtils Tests', () {
    test('hashPassword 应对固定输入产生固定的 64 位十六进制 SHA-256', () {
      // SHA256("abc") 的公开已知向量
      expect(
        SecurityUtils.hashPassword('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('hashPassword 应确定性（同输入多次结果一致）', () {
      expect(SecurityUtils.hashPassword('password123'), SecurityUtils.hashPassword('password123'));
    });

    test('hashPassword 应随输入变化而变化', () {
      expect(SecurityUtils.hashPassword('abc'), isNot(SecurityUtils.hashPassword('abd')));
    });

    test('hashPassword 空串应等于 SHA256("")', () {
      // SHA256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      expect(
        SecurityUtils.hashPassword(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('hashPasswordWithSalt 应等于 sha256(salt + password)', () {
      const salt = 'mysalt';
      const pwd = 'mypassword';
      // 源码实现：combined = salt + password，再走 hashPassword(combined)
      expect(
        SecurityUtils.hashPasswordWithSalt(pwd, salt),
        SecurityUtils.hashPassword('$salt$pwd'),
      );
    });

    test('不同 salt 应对同一密码产生不同哈希', () {
      final a = SecurityUtils.hashPasswordWithSalt('pwd', 'saltA');
      final b = SecurityUtils.hashPasswordWithSalt('pwd', 'saltB');
      expect(a, isNot(b));
    });

    test('加盐哈希应与不加盐哈希不同', () {
      expect(
        SecurityUtils.hashPasswordWithSalt('abc', 'xyz'),
        isNot(SecurityUtils.hashPassword('abc')),
      );
    });
  });
}
