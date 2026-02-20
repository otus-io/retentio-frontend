import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordupx/models/user.dart';
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
    if (res?.isSuccess == true) {
      final user = User.fromJson(res?.data);
      state = UserState(user: user);
    } else {
      state = UserState(user: User.empty());
    }
  }

  void logout() {
    state = UserState(user: User.empty());
    ApiService.handle401Unauthorized();
  }
}

class UserState {
  final User user;

  UserState({required this.user});

  UserState copyWith({User? user}) => UserState(user: user ?? this.user);
}
