import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/models/user.dart';
import 'package:retentio/services/apis/api_service.dart';

import '../../../services/index.dart';

final profileProvider = NotifierProvider.autoDispose(ProfileNotifier.new);

class ProfileNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    getProfile();
    return UserState(user: User.empty());
  }

  Future<void> getProfile() async {
    final res = await ApiService.get(Api.profile);
    if (res?.isSuccess == true) {
      final raw = res?.data;
      final user = raw is Map<String, dynamic>
          ? User.fromJson(raw)
          : User.empty();
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
