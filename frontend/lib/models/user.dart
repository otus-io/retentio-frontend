class User {
  final String email;
  final String username;
  final DateTime createdAt;

  User({required this.email, required this.username, required this.createdAt});

  /// 从 JSON 创建 User 对象
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
