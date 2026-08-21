
class UserInfo {
  final String id;
  final String username;
  final String realName;
  final String role;
  final String isActive;
  final String isDefault;
  final String createdAt;
  final String lastLogin;
  final String loginAttempts;

  UserInfo({
    required this.id,
    required this.username,
    required this.realName,
    required this.role,
    required this.isActive,
    required this.isDefault,
    required this.createdAt,
    required this.lastLogin,
    required this.loginAttempts,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      realName: json['real_name'] ?? '',
      role: json['role'] ?? 'user',
      isActive: json['is_active'] ?? '是',
      isDefault: json['is_default'] ?? '否',
      createdAt: json['created_at'] ?? '',
      lastLogin: json['last_login'] ?? '',
      loginAttempts: json['login_attempts'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'real_name': realName,
      'role': role,
      'is_active': isActive,
      'is_default': isDefault,
      'created_at': createdAt,
      'last_login': lastLogin,
      'login_attempts': loginAttempts,
    };
  }

  
  bool get isAdmin => role == 'admin';

  
  bool get isActiveUser => isActive == '是';

  
  bool get isDefaultUser => isDefault == '是';
}
