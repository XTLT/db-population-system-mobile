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

class _MyAppState extends State<MyApp> {
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
    
    _authProvider.init();
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
                    : const LoginPage(),
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
