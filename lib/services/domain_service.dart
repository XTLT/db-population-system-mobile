import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../api/api_client.dart';
import 'dart:io';

class DomainService {

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    ApiClient.applyCertificatePinning(dio);

    return dio;
  }

  /// 从域名的 AAAA 记录推导服务器的链路本地 IPv6 地址。
  ///
  /// 原理：服务器的全局 IPv6 地址接口 ID（后 64 位）与链路本地地址相同。
  /// 例如 240e:338:2c01:efc:f4e3:d2ff:feaf:1e41 → fe80::f4e3:d2ff:feaf:1e41
  ///
  /// 返回 'https://[fe80::xxx%iface]:5000' 格式的 URL，失败返回 null。
  static Future<String?> resolveLinkLocalIPv6(String url) async {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) return null;

      // 已经是 IP 地址则跳过
      if (RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(uri.host) ||
          uri.host.contains(':')) {
        return null;
      }

      // 1. DNS AAAA 查询
      final addresses = await InternetAddress.lookup(
        uri.host,
        type: InternetAddressType.IPv6,
      ).timeout(const Duration(seconds: 3));

      // 2. 筛选全局地址，优先 EUI-64 接口 ID（含 ff:fe，可可靠推导链路本地）
      final eui64 = <String>[];
      final others = <String>[];
      for (final addr in addresses) {
        final a = addr.address;
        if (a.startsWith('fe80') || a.startsWith('fd') || a.startsWith('fc')) continue;
        final parts = a.split(':');
        if (parts.length < 8) continue;
        final interfaceId = parts.sublist(4).join(':');
        if (interfaceId.contains('ff:fe') || interfaceId.contains('fffe')) {
          eui64.add('fe80::$interfaceId');
        } else {
          others.add('fe80::$interfaceId');
        }
      }

      final candidates = [...eui64, ...others];
      if (candidates.isEmpty) return null;

      // 3. 查找手机网络接口名称（作为 scope ID）
      String? scopeId;
      try {
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv6);
        for (final iface in interfaces) {
          if (iface.name == 'lo') continue;
          for (final addr in iface.addresses) {
            if (addr.address.startsWith('fe80')) {
              scopeId = iface.name;
              break;
            }
          }
          if (scopeId != null) break;
        }
      } catch (_) {}

      // Android WiFi 接口通常叫 wlan0
      scopeId ??= 'wlan0';

      // 4. 构造 URL（%25 是 % 的 URI 编码，Uri.parse 会解码回 %）
      final port = uri.port != 0 ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      final scopedHost = '[${candidates.first}%25$scopeId]';
      return '${uri.scheme}://$scopedHost:$port';
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _resolveIPv4(String url) async {
    try {
      final uri = Uri.parse(url);
      if (uri.host.isEmpty) return null;
      final addresses = await InternetAddress.lookup(
        uri.host,
        type: InternetAddressType.IPv4,
      ).timeout(const Duration(seconds: 3));
      if (addresses.isNotEmpty) {
        return url.replaceFirst(uri.host, addresses.first.address);
      }
    } catch (_) {}
    return null;
  }


  static Future<bool> checkDomain(String url) async {
    try {
      final response = await _createDio().get(
        '$url/api/health',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }


  static Future<Map<String, dynamic>> testCurrentDomain() async {
    final url = AppConfig.normalizeUrl(AppConfig.apiBaseUrl);
    final startTime = DateTime.now();

    // 1. 尝试主域名（流量场景：全局 IPv6 直达）
    try {
      final response = await _createDio().get('$url/api/health');
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      return {
        'url': url,
        'available': response.statusCode == 200,
        'response_time': duration,
      };
    } catch (_) {}

    // 2. 尝试链路本地 IPv6（WiFi 场景：手机和服务器在同一局域网）
    final linkLocalUrl = await resolveLinkLocalIPv6(url);
    if (linkLocalUrl != null) {
      try {
        final llStart = DateTime.now();
        final response = await _createDio().get('$linkLocalUrl/api/health');
        final duration = DateTime.now().difference(llStart).inMilliseconds;
        if (response.statusCode == 200) {
          return {
            'url': url,
            'available': true,
            'response_time': duration,
            'fallback': 'IPv6 链路本地',
          };
        }
      } catch (_) {}
    }

    // 3. 尝试 IPv4 解析（端口转发场景）
    final ipv4Url = await _resolveIPv4(url);
    if (ipv4Url != null && ipv4Url != url) {
      try {
        final v4Start = DateTime.now();
        final response = await _createDio().get('$ipv4Url/api/health');
        final duration = DateTime.now().difference(v4Start).inMilliseconds;
        if (response.statusCode == 200) {
          return {
            'url': url,
            'available': true,
            'response_time': duration,
            'fallback': 'IPv4',
          };
        }
      } catch (_) {}
    }

    // 4. 尝试备用地址
    for (final rawUrl in AppConfig.backupUrls) {
      final backupUrl = AppConfig.normalizeUrl(rawUrl);
      try {
        final bStart = DateTime.now();
        final response = await _createDio().get('$backupUrl/api/health');
        final duration = DateTime.now().difference(bStart).inMilliseconds;
        if (response.statusCode == 200) {
          await AppConfig.updateBaseUrl(backupUrl);
          return {
            'url': backupUrl,
            'available': true,
            'response_time': duration,
            'fallback': '备用地址',
          };
        }
      } catch (_) {}
    }

    return {
      'url': url,
      'available': false,
      'response_time': 0,
    };
  }


  static Future<List<Map<String, dynamic>>> checkAllDomains() async {
    final results = <Map<String, dynamic>>[];

    results.add(await testCurrentDomain());

    for (final rawUrl in AppConfig.backupUrls) {
      final url = AppConfig.normalizeUrl(rawUrl);
      final startTime = DateTime.now();
      try {
        final response = await _createDio().get('$url/api/health');
        final endTime = DateTime.now();

        results.add({
          'url': url,
          'available': response.statusCode == 200,
          'response_time': endTime.difference(startTime).inMilliseconds,
        });
      } catch (e) {
        results.add({
          'url': url,
          'available': false,
          'response_time': 0,
        });
      }
    }

    return results;
  }
}
