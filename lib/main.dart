import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/operation_log_provider.dart';
import 'providers/backup_provider.dart';
import 'providers/user_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/sync_provider.dart';
import 'pages/login/login_page.dart';
import 'pages/home/home_page.dart';
import 'pages/onboarding/onboarding_page.dart';
import 'api/api_client.dart';
import 'pages/sync/conflict_resolution_page.dart';
import 'services/notification_service.dart';
import 'services/onboarding_service.dart';
import 'services/network_cache.dart';
import 'themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  await NetworkCache().init();

  
  await AppConfig.loadConfig();

  
  await NotificationService.initialize();

  
  final onboardingCompleted = await OnboardingService.isCompleted();

  runApp(MyApp(showOnboarding: !onboardingCompleted));
}

class MyApp extends StatefulWidget {
  final bool showOnboarding;

  const MyApp({super.key, this.showOnboarding = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  /// 全局导航 Key：登录失效时把任意层级的页面栈退回根路由（登录页）。
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final AuthProvider _authProvider = AuthProvider();
  final OperationLogProvider _operationLogProvider = OperationLogProvider();
  final BackupProvider _backupProvider = BackupProvider();
  final UserProvider _userProvider = UserProvider();
  final NotificationProvider _notificationProvider = NotificationProvider();
  final ThemeProvider _themeProvider = ThemeProvider();
  final SyncProvider _syncProvider = SyncProvider();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    // 业务请求收到 401 时由 ApiClient 回调，统一登出并退回登录页
    ApiClient().onUnauthorized = _handleSessionExpired;

    _authProvider.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ApiClient().onUnauthorized = null;
    super.dispose();
  }

  /// 登录失效的统一出口：清除登录态 → 退回根路由（home 此时已是登录页）。
  Future<void> _handleSessionExpired() async {
    await _authProvider.handleSessionExpired();
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_authProvider.shouldRevalidate()) return;
    _revalidateAndResetNavigation();
  }

  /// 切回前台重新校验：超过节流窗口才发请求；
  /// 服务器明确判定失效时，同样把页面栈退回登录页。
  Future<void> _revalidateAndResetNavigation() async {
    await _authProvider.revalidate();
    if (_authProvider.sessionExpired && !_authProvider.isLoggedIn) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _operationLogProvider),
        ChangeNotifierProvider.value(value: _backupProvider),
        ChangeNotifierProvider.value(value: _userProvider),
        ChangeNotifierProvider.value(value: _notificationProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _syncProvider),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, themeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: AppConfig.appName,
            theme: AppTheme.createTheme(
              seedColor: themeProvider.seedColor,
              brightness: Brightness.light,
              textScaleFactor: themeProvider.textScaleFactor,
            ),
            darkTheme: AppTheme.createTheme(
              seedColor: themeProvider.seedColor,
              brightness: Brightness.dark,
              textScaleFactor: themeProvider.textScaleFactor,
            ),
            themeMode: themeProvider.themeMode,
            home: widget.showOnboarding
                ? const OnboardingPage()
                : auth.isLoggedIn
                    ? const HomePage()
                    : LoginPage(sessionExpired: auth.sessionExpired),
            routes: {
              '/login': (context) => const LoginPage(),
              '/home': (context) => const HomePage(),
              '/conflicts': (context) => const ConflictResolutionPage(),
            },
          );
        },
      ),
    );
  }
}
