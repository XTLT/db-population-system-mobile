
class User {
  final String username;
  final String? role;
  final String? token;
  
  User({
    required this.username,
    this.role,
    this.token,
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] ?? '',
      role: json['role'],
      token: json['token'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'role': role,
      'token': token,
    };
  }
}
