import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/offline_data_service.dart';
import '../../services/network_cache.dart';
import '../../api/api_client.dart';
import '../../config/app_config.dart';
import 'theme_customize_page.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> with WidgetsBindingObserver {
  int _networkCacheSize = 0;
  int _offlineDataSize = 0;
  DateTime? _lastSyncTime;
  bool _isClearing = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCacheInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCacheInfo();
    }
  }
  
  Future<void> _loadCacheInfo() async {
    final networkCacheSize = await NetworkCache().getCacheSize();
    final offlineDataSize = await OfflineDataService().getDataSize();
    final lastSyncTime = await OfflineDataService().getLastSyncTime();
    
    setState(() {
      _networkCacheSize = networkCacheSize;
      _offlineDataSize = offlineDataSize;
      _lastSyncTime = lastSyncTime;
    });
  }
  
  Future<void> _clearNetworkCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空网络缓存吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isClearing = true;
    });
    
    await NetworkCache().clear();
    
    setState(() {
      _isClearing = false;
    });
    
    await _loadCacheInfo();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络缓存已清空')),
      );
    }
  }
  
  Future<void> _clearOfflineData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空离线数据吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isClearing = true;
    });
    
    await OfflineDataService().clearAllData();
    
    setState(() {
      _isClearing = false;
    });
    
    await _loadCacheInfo();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('离线数据已清空')),
      );
    }
  }
  
  Future<void> _clearAllCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有缓存和数据吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isClearing = true;
    });
    
    await Future.wait([
      NetworkCache().clear(),
      OfflineDataService().clearAllData(),
      ApiClient().clearCache(),
    ]);
    
    setState(() {
      _isClearing = false;
    });
    
    await _loadCacheInfo();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有缓存已清空')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('应用设置'),
      ),
      body: _isClearing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                
                _buildSection(
                  '主题设置',
                  [
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('主题定制'),
                      subtitle: const Text('自定义主题颜色和字体大小'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ThemeCustomizePage(),
                          ),
                        );
                      },
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              title: const Text('跟随系统'),
                              subtitle: const Text('根据系统设置自动切换'),
                              value: ThemeMode.system,
                              groupValue: themeProvider.themeMode,
                              onChanged: (mode) {
                                if (mode != null) {
                                  themeProvider.setThemeMode(mode);
                                }
                              },
                            ),
                            RadioListTile<ThemeMode>(
                              title: const Text('浅色模式'),
                              subtitle: const Text('始终使用浅色主题'),
                              value: ThemeMode.light,
                              groupValue: themeProvider.themeMode,
                              onChanged: (mode) {
                                if (mode != null) {
                                  themeProvider.setThemeMode(mode);
                                }
                              },
                            ),
                            RadioListTile<ThemeMode>(
                              title: const Text('深色模式'),
                              subtitle: const Text('始终使用深色主题'),
                              value: ThemeMode.dark,
                              groupValue: themeProvider.themeMode,
                              onChanged: (mode) {
                                if (mode != null) {
                                  themeProvider.setThemeMode(mode);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                
                const Divider(),
                
                
                _buildSection(
                  '缓存管理',
                  [
                    ListTile(
                      leading: const Icon(Icons.cached),
                      title: const Text('网络缓存'),
                      subtitle: Text('大小: ${(_networkCacheSize / 1024).toStringAsFixed(2)} KB'),
                      trailing: TextButton(
                        onPressed: _clearNetworkCache,
                        child: const Text('清空'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.offline_bolt),
                      title: const Text('离线数据'),
                      subtitle: Text('大小: ${(_offlineDataSize / 1024).toStringAsFixed(2)} KB'),
                      trailing: TextButton(
                        onPressed: _clearOfflineData,
                        child: const Text('清空'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep),
                      title: const Text('清空所有缓存'),
                      subtitle: const Text('清空网络缓存和离线数据'),
                      trailing: ElevatedButton(
                        onPressed: _clearAllCache,
                        child: const Text('清空'),
                      ),
                    ),
                  ],
                ),
                
                const Divider(),
                
                
                _buildSection(
                  '数据同步',
                  [
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: const Text('最后同步时间'),
                      subtitle: Text(
                        _lastSyncTime != null
                            ? '${_lastSyncTime!.year}-${_lastSyncTime!.month.toString().padLeft(2, '0')}-${_lastSyncTime!.day.toString().padLeft(2, '0')} '
                              '${_lastSyncTime!.hour.toString().padLeft(2, '0')}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}'
                            : '从未同步',
                      ),
                    ),
                  ],
                ),
                
                const Divider(),
                
                
                _buildSection(
                  '关于',
                  [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('应用版本'),
                      subtitle: Text(AppConfig.appVersion),
                    ),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('技术支持'),
                      subtitle: const Text('Flutter + Flask'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
