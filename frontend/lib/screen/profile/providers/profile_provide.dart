import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordupx/models/user.dart';
import 'package:wordupx/services/apis/auth_service.dart';
import 'package:wordupx/services/apis/api_service.dart';

import '../../../services/index.dart';

final profileProvide = NotifierProvider.autoDispose(ProfileNotifier.new);

class ProfileNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    getProfile();
    return UserState(user: User.empty());
  }

  Future<void> getProfile() async {
    final res = await ApiService.get(Api.profile);
    if (res?.isSuccess == true && res?.data is Map<String, dynamic>) {
      state = UserState(user: User.fromJson(res!.data as Map<String, dynamic>));
    } else {
      state = UserState(user: User.empty());
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    state = UserState(user: User.empty());
  }
}

class UserState {
  final User user;

  UserState({required this.user});

  UserState copyWith({User? user}) => UserState(user: user ?? this.user);
}
