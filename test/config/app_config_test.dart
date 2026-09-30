import 'package:flutter_test/flutter_test.dart';
import 'package:population_mobile/config/app_config.dart';

void main() {
  group('AppConfig.validateServerUrl Tests', () {
    // 表驱动：(输入, 期望是否通过, 期望消息包含的关键片段)
    test('https 公网地址应通过并返回安全提示', () {
      final r = AppConfig.validateServerUrl('https://your-domain.com:5000');
      expect(r.$1, true);
      expect(r.$2, '✓ 已配置HTTPS安全连接');
    });

    test('http 公网地址应被拒绝（必须 HTTPS）', () {
      final r = AppConfig.validateServerUrl('http://example.com');
      expect(r.$1, false);
      expect(r.$2, '⚠️ 非内网地址必须使用HTTPS协议');
    });

    test('http + localhost 应放行并给出明文警告', () {
      final r = AppConfig.validateServerUrl('http://127.0.0.1:5000');
      expect(r.$1, true);
      expect(r.$2, contains('HTTP明文传输'));
    });

    test('http + 192.168.* 应放行', () {
      final r = AppConfig.validateServerUrl('http://192.168.1.100:5000');
      expect(r.$1, true);
      expect(r.$2, contains('HTTP明文传输'));
    });

    test('http + 10.* 应放行', () {
      final r = AppConfig.validateServerUrl('http://10.0.0.5:8080');
      expect(r.$1, true);
      expect(r.$2, contains('HTTP明文传输'));
    });

    test('172.16-31 内网段边界：172.16 放行 / 172.15 拒绝 / 172.31 放行 / 172.32 拒绝', () {
      // 边界下限
      expect(AppConfig.validateServerUrl('http://172.16.0.5').$1, true);
      // 边界外（172.15 不在白名单）
      expect(AppConfig.validateServerUrl('http://172.15.0.5').$1, false);
      // 边界上限内
      expect(AppConfig.validateServerUrl('http://172.31.255.255').$1, true);
      // 边界外（172.32 不在白名单）
      expect(AppConfig.validateServerUrl('http://172.32.0.5').$1, false);
    });

    test('https + 内网地址应走到默认 (true, null) 分支', () {
      final r = AppConfig.validateServerUrl('https://192.168.1.1');
      expect(r.$1, true);
      expect(r.$2, isNull);
    });

    test('localhost host 应放行', () {
      expect(AppConfig.validateServerUrl('http://localhost:5000').$1, true);
      expect(AppConfig.validateServerUrl('http://localhost:5000').$2, contains('HTTP明文传输'));
    });

    test('host 为空应返回 服务器地址无效', () {
      // Uri.parse('notaurl') 无 scheme 时 host 为空
      final r = AppConfig.validateServerUrl('notaurl');
      expect(r.$1, false);
      expect(r.$2, '服务器地址无效');
    });

    test('空字符串应返回 服务器地址无效', () {
      final r = AppConfig.validateServerUrl('');
      expect(r.$1, false);
      expect(r.$2, '服务器地址无效');
    });
  });

  group('AppConfig.normalizeUrl Tests', () {
    test('已有 https:// 应原样返回（去空白）', () {
      expect(AppConfig.normalizeUrl('https://a.com'), 'https://a.com');
      expect(AppConfig.normalizeUrl('  https://a.com  '), 'https://a.com');
    });

    test('已有 http:// 应原样返回', () {
      expect(AppConfig.normalizeUrl('http://192.168.1.1:5000'), 'http://192.168.1.1:5000');
    });

    test('无 scheme 应补 https://', () {
      expect(AppConfig.normalizeUrl('a.com:5000'), 'https://a.com:5000');
      expect(AppConfig.normalizeUrl('your-domain.com'), 'https://your-domain.com');
    });

    test('带前后空白的无 scheme 应先 trim 再补 scheme', () {
      expect(AppConfig.normalizeUrl('  example.com  '), 'https://example.com');
    });

    test('空串应原样返回空串', () {
      expect(AppConfig.normalizeUrl(''), '');
      expect(AppConfig.normalizeUrl('   '), '');
    });
  });
}
