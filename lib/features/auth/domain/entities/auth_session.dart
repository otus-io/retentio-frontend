import 'package:equatable/equatable.dart';

class AuthSession extends Equatable {
  final String token;
  final bool isLoggedIn;

  const AuthSession({required this.token, required this.isLoggedIn});

  const AuthSession.unauthenticated() : this(token: '', isLoggedIn: false);

  bool get hasToken => token.isNotEmpty;

  @override
  List<Object?> get props => [token, isLoggedIn];
}
