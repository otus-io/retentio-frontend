// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  email: json['email'] as String? ?? '',
  username: json['username'] as String? ?? '',
  emailVerified: json['email_verified'] == null
      ? false
      : _emailVerifiedFromJson(json['email_verified']),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'email': instance.email,
  'username': instance.username,
  'email_verified': instance.emailVerified,
};
