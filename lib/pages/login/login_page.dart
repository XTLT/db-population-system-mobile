import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../home/home_page.dart';
import '../../config/app_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = '用户名和密码不能为空';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        _usernameController.text,
        _passwordController.text,
      );
      
      if (result['success'] == true && mounted) {
        
        if (result['require_password_change'] == true) {
          _showForceChangePasswordDialog();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? '登录失败，请检查用户名和密码';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '登录失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  
  void _showForceChangePasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('安全警告'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '您正在使用默认密码登录，存在安全风险。\n请立即修改密码以保护您的账户安全。',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: '新密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  helperText: '至少6位，包含字母和数字',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: '确认新密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
              child: const Text('稍后再说'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;
                
                
                if (newPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入新密码')),
                  );
                  return;
                }
                
                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码至少需要6位')),
                  );
                  return;
                }
                
                if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(newPassword)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码必须包含字母和数字')),
                  );
                  return;
                }
                
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('两次输入的密码不一致')),
                  );
                  return;
                }
                
                setState(() => isLoading = true);
                
                try {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final result = await authProvider.forceChangePassword(newPassword);
                  
                  if (result['success'] == true) {
                    if (mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('密码修改成功'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'] ?? '修改失败')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('修改密码失败: $e')),
                  );
                } finally {
                  setState(() => isLoading = false);
                }
              },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('确认修改'),
            ),
          ],
        ),
      ),
    );
  }
  
  
  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('正在测试连接...'),
          ],
        ),
      ),
    );
    
    try {
      
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 10);
      
      
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
        client.connectionTimeout = const Duration(seconds: 10);
        return client;
      };
      
      final url = AppConfig.apiBaseUrl;
      
      debugPrint('测试连接 URL: $url');
      
      
      final healthResponse = await dio.get('$url/api/health');
      debugPrint('Health 响应: ${healthResponse.data}');
      
      
      
      final testUsername = const String.fromEnvironment('TEST_USERNAME', defaultValue: '');
      final testPassword = const String.fromEnvironment('TEST_PASSWORD', defaultValue: '');
      
      if (testUsername.isEmpty || testPassword.isEmpty) {
        
        debugPrint('未配置测试账户，跳过登录测试');
        if (healthResponse.statusCode == 200) {
          Navigator.pop(context);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('连接成功'),
                ],
              ),
              content: const Text('服务器连接正常'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        }
        return;
      }
      
      final loginResponse = await dio.post(
        '$url/api/login',
        data: {'username': testUsername, 'password': testPassword},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      debugPrint('登录响应: ${loginResponse.data}');
      
      Navigator.pop(context);
      
      if (healthResponse.statusCode == 200 && loginResponse.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('连接成功'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('服务器地址: $url'),
                const SizedBox(height: 8),
                Text('Health状态: ${healthResponse.data}'),
                const SizedBox(height: 8),
                Text('登录测试: ${loginResponse.data['success'] == true ? "成功" : "失败"}'),
                if (loginResponse.data['success'] == true)
                  Text('Token: ${loginResponse.data['token'].toString().substring(0, 20)}...'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } on DioException catch (e) {
      Navigator.pop(context);
      
      debugPrint('连接错误: ${e.type} - ${e.message}');
      debugPrint('错误详情: ${e.error}');
      
      String errorDetail = '';
      if (e.type == DioExceptionType.connectionError) {
        errorDetail = '无法建立连接到 ${AppConfig.apiBaseUrl}\n\n'
            '错误类型: connectionError\n'
            '错误消息: ${e.message}\n'
            '错误详情: ${e.error}\n\n'
            '可能原因:\n'
            '1. 网络安全配置未生效\n'
            '2. HTTP连接被阻止\n'
            '3. 网络不通';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorDetail = '连接超时\n${e.message}';
      } else {
        errorDetail = '${e.type}: ${e.message}\n${e.error}';
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('连接失败'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前服务器地址: ${AppConfig.apiBaseUrl}'),
                const Divider(),
                Text(errorDetail),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      debugPrint('未知错误: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('测试失败: $e')),
      );
    }
  }
  
  
  void _showServerConfigDialog() {
    final urlController = TextEditingController(text: AppConfig.apiBaseUrl);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置服务器地址'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'API 域名',
                hintText: '例如: 192.168.9.30:5000',
                helperText: '自动添加 http:// 或 https:// 前缀',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Text(
              '当前地址: ${AppConfig.apiBaseUrl}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              String newUrl = urlController.text.trim();
              
              if (newUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入服务器地址'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
                newUrl = 'http://$newUrl';
              }
              
              try {
                final uri = Uri.parse(newUrl);
                if (uri.host.isEmpty) {
                  throw FormatException('无效的地址');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('地址格式错误: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              
              
              final (isValid, warningMessage) = AppConfig.validateServerUrl(newUrl);
              if (!isValid) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(warningMessage ?? '服务器地址无效'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              
              
              if (warningMessage != null) {
                if (!mounted) return;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('安全提示'),
                    content: Text(
                      '$warningMessage\n\n'
                      '是否继续设置该服务器地址？',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('确认'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed != true) return;
              }
              
              
              await AppConfig.updateBaseUrl(newUrl);
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('服务器地址已更新为: $newUrl'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                enabled: !_isLoading,
                onSubmitted: (_) => _login(),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('登录'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isLoading ? null : _showServerConfigDialog,
                icon: const Icon(Icons.settings, size: 20),
                label: const Text('设置服务器地址'),
              ),
              TextButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: const Icon(Icons.network_check, size: 20),
                label: const Text('测试连接'),
              ),
              const SizedBox(height: 12),
              Text(
                '当前服务器: ${AppConfig.apiBaseUrl}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
