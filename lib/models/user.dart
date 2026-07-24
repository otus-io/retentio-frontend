import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  const User({
    @JsonKey(defaultValue: '') required this.email,
    @JsonKey(defaultValue: '') required this.username,
    @JsonKey(name: 'email_verified', defaultValue: false)
    this.emailVerified = false,
  });

  final String email;
  final String username;
  final bool emailVerified;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  factory User.empty() =>
      const User(email: '', username: '', emailVerified: false);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
