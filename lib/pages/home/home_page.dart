import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/feature_tooltip.dart';
import '../../widgets/sync_status_indicator.dart';
import '../settings/settings_page.dart';
import '../notification/notification_center_page.dart';
import 'person_list_page.dart';
import '../student/student_list_page.dart';
import 'stats_page.dart';
import '../../widgets/update_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().loadUnreadCount();
      context.read<SyncProvider>().init();
      UpdateDialog.showIfNeeded(context);
    });
  }
  
  final List<Widget> _pages = [
    const PersonListPage(),
    const StudentListPage(),
    const StatsPage(),
  ];
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('人口信息查询系统'),
        actions: [
          
          const SyncStatusIndicator(),
          const SizedBox(width: 8),
          
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Stack(
                children: [
                  FeatureTooltip(
                    featureId: FeatureTooltipIds.syncStatus,
                    message: '点击查看通知消息',
                    child: IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationCenterPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationProvider.unreadCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          FeatureTooltip(
            featureId: 'settings_button',
            message: '点击进入系统设置',
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.logout();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('退出登录'),
              ),
            ],
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people),
            label: '人员查询',
          ),
          NavigationDestination(
            icon: Icon(Icons.school),
            label: '学生管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: '数据统计',
          ),
        ],
      ),
    );
  }
}


class StudentPage extends StatelessWidget {
  const StudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('学生管理功能开发中...'),
    );
  }
}
