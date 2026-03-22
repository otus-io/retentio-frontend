class User {
  final String email;
  final String username;

  User({required this.email, required this.username});

  /// 从 JSON 创建 User 对象
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
    );
  }
  factory User.empty() {
    return User(email: '', username: '');
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {'email': email, 'username': username};
  }
}
