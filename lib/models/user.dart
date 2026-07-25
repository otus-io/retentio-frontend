import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  const User({
    @JsonKey(defaultValue: '') required this.email,
    @JsonKey(defaultValue: '') required this.username,
    this.emailVerified = false,
  });

  final String email;
  final String username;

  @JsonKey(
    name: 'email_verified',
    defaultValue: false,
    fromJson: _emailVerifiedFromJson,
  )
  final bool emailVerified;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  factory User.empty() =>
      const User(email: '', username: '', emailVerified: false);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

bool _emailVerifiedFromJson(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    return false;
  }
  return false;
}
