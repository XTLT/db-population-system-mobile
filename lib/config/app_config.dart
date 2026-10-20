







library;

import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  
  
  
  static String apiBaseUrl = 'https://tension02.ren:5000';
  
  
  static List<String> backupUrls = [];
  
  
  static const String appName = '人口通';
  static const String appVersion = '0.0.23';
  
  
  
  static (bool, String?) validateServerUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      
      if (uri.host.isEmpty) {
        return (false, '服务器地址无效');
      }
      
      
      final isHttps = uri.scheme == 'https';
      final isLocalhost = uri.host == 'localhost' || 
                          uri.host == '127.0.0.1' ||
                          uri.host.startsWith('192.168.') ||
                          uri.host.startsWith('10.') ||
                          uri.host.startsWith('172.16.') ||
                          uri.host.startsWith('172.17.') ||
                          uri.host.startsWith('172.18.') ||
                          uri.host.startsWith('172.19.') ||
                          uri.host.startsWith('172.20.') ||
                          uri.host.startsWith('172.21.') ||
                          uri.host.startsWith('172.22.') ||
                          uri.host.startsWith('172.23.') ||
                          uri.host.startsWith('172.24.') ||
                          uri.host.startsWith('172.25.') ||
                          uri.host.startsWith('172.26.') ||
                          uri.host.startsWith('172.27.') ||
                          uri.host.startsWith('172.28.') ||
                          uri.host.startsWith('172.29.') ||
                          uri.host.startsWith('172.30.') ||
                          uri.host.startsWith('172.31.');
      
      
      if (!isHttps && !isLocalhost) {
        return (false, '⚠️ 非内网地址必须使用HTTPS协议');
      }
      
      
      if (!isHttps && isLocalhost) {
        return (true, '⚠️ 当前使用HTTP明文传输，内网环境可接受，但请注意安全');
      }
      
      
      if (isHttps && !isLocalhost) {
        return (true, '✓ 已配置HTTPS安全连接');
      }
      
      return (true, null);
    } catch (e) {
      return (false, '地址格式错误: $e');
    }
  }
  
  
  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    
    
    final savedUrl = prefs.getString('api_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      apiBaseUrl = savedUrl;
    }
    
    
    final savedBackupUrls = prefs.getStringList('backup_urls');
    if (savedBackupUrls != null && savedBackupUrls.isNotEmpty) {
      backupUrls = savedBackupUrls;
    }
  }
  
  
  static Future<void> updateBaseUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', newUrl);
    apiBaseUrl = newUrl;
  }
  
  
  static Future<void> addBackupUrl(String url) async {
    if (!backupUrls.contains(url)) {
      backupUrls.add(url);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('backup_urls', backupUrls);
    }
  }
  
  
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_base_url');
    
    apiBaseUrl = 'https://tension02.ren:5000';
  }
  
  
  // 6a 结论：getApiUrl 经全仓 Grep 确认零调用方（各 api 层直接用 dio 路径 '/api/...'）。
  // 后端蓝图实际挂载在 url_prefix='/api'（见 server/app_modular.py），并无 /api/v1 路由。
  // 此处保留该工具方法但把前缀由错误的 /api/v1 修正为 /api，避免日后被误用成 404。
  static String getApiUrl(String path) {
    final base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    return '$base/api$path';
  }

  static String normalizeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'https://$trimmed';
    }
    return trimmed;
  }
}
