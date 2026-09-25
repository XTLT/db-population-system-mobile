import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_info.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAdminAndLoad();
    });
  }

  void _checkAdminAndLoad() {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('权限不足：仅管理员可访问')),
      );
      Navigator.of(context).pop();
      return;
    }
    context.read<UserProvider>().loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<UserProvider>().loadUsers();
            },
            tooltip: '刷新',
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败: ${provider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadUsers(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (provider.users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无用户'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.users.length,
            itemBuilder: (context, index) {
              return _buildUserItem(provider.users[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('创建用户'),
      ),
    );
  }

  Widget _buildUserItem(UserInfo user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.isAdmin ? Colors.purple : Colors.blue,
                  child: Icon(
                    user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.username,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user.isDefaultUser) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '默认',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.realName.isEmpty ? '未设置姓名' : user.realName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(user),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  icon: Icons.badge,
                  label: user.isAdmin ? '管理员' : '普通用户',
                  color: user.isAdmin ? Colors.purple : Colors.blue,
                ),
                if (user.lastLogin.isNotEmpty)
                  _buildInfoChip(
                    icon: Icons.login,
                    label: '上次登录: ${user.lastLogin}',
                    color: Colors.green,
                  ),
                if (user.loginAttempts != '0')
                  _buildInfoChip(
                    icon: Icons.warning,
                    label: '登录失败: ${user.loginAttempts} 次',
                    color: Colors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: user.isDefaultUser
                      ? null
                      : () => _showEditUserDialog(user),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('编辑'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: user.isDefaultUser
                      ? null
                      : () => _showResetPasswordDialog(user),
                  icon: const Icon(Icons.lock_reset, size: 18),
                  label: const Text('重置密码'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: user.isDefaultUser
                      ? null
                      : () => _confirmDeleteUser(user),
                  icon: const Icon(Icons.delete, size: 18),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  label: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(UserInfo user) {
    Color color;
    String label;
    IconData icon;

    if (user.isActiveUser) {
      color = Colors.green;
      label = '正常';
      icon = Icons.check_circle;
    } else {
      color = Colors.red;
      label = '已禁用';
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final realNameController = TextEditingController();
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('创建用户'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: '用户名 *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码 * (至少6位)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: realNameController,
                  decoration: const InputDecoration(
                    labelText: '真实姓名',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: '角色',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('普通用户')),
                    DropdownMenuItem(value: 'admin', child: Text('管理员')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                usernameController.dispose();
                passwordController.dispose();
                realNameController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = usernameController.text.trim();
                final password = passwordController.text;
                final realName = realNameController.text.trim();

                if (username.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('用户名和密码不能为空')),
                  );
                  return;
                }

                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('密码长度至少6位')),
                  );
                  return;
                }

                usernameController.dispose();
                passwordController.dispose();
                realNameController.dispose();
                Navigator.of(context).pop();

                final success = await context.read<UserProvider>().createUser(
                      username: username,
                      password: password,
                      realName: realName,
                      role: selectedRole,
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '用户创建成功' : '创建失败'),
                    ),
                  );
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(UserInfo user) {
    final realNameController = TextEditingController(text: user.realName);
    String selectedRole = user.role;
    String selectedStatus = user.isActive;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('编辑用户: ${user.username}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: realNameController,
                  decoration: const InputDecoration(
                    labelText: '真实姓名',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: '角色',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('普通用户')),
                    DropdownMenuItem(value: 'admin', child: Text('管理员')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: '状态',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '是', child: Text('正常')),
                    DropdownMenuItem(value: '否', child: Text('禁用')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                realNameController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                realNameController.dispose();
                Navigator.of(context).pop();

                final success = await context.read<UserProvider>().updateUser(
                      user.id,
                      realName: realNameController.text.trim(),
                      role: selectedRole,
                      isActive: selectedStatus,
                    );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '用户更新成功' : '更新失败'),
                    ),
                  );
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(UserInfo user) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('重置密码: ${user.username}'),
        content: TextField(
          controller: passwordController,
          decoration: const InputDecoration(
            labelText: '新密码 (至少6位)',
            border: OutlineInputBorder(),
            helperText: '重置后，用户可使用新密码登录',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              passwordController.dispose();
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text;

              if (password.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('密码长度至少6位')),
                );
                return;
              }

              passwordController.dispose();
              Navigator.of(context).pop();

              final success = await context.read<UserProvider>().resetPassword(
                    user.id,
                    password,
                  );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '密码重置成功' : '重置失败'),
                  ),
                );
              }
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(UserInfo user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除用户 "${user.username}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();

              final success = await context.read<UserProvider>().deleteUser(
                    user.id,
                  );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '用户删除成功' : '删除失败'),
                  ),
                );
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
