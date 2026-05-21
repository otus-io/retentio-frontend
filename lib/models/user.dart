import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  const User({
    @JsonKey(defaultValue: '') required this.email,
    @JsonKey(defaultValue: '') required this.username,
  });

  final String email;
  final String username;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  factory User.empty() => const User(email: '', username: '');

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
