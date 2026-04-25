import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retentio/providers/auth_provider.dart';
import 'package:retentio/models/user.dart';
import 'package:retentio/services/apis/api_service.dart';

import '../../../services/index.dart';

final profileProvider = NotifierProvider.autoDispose(ProfileNotifier.new);

class ProfileNotifier extends Notifier<UserState> {
  bool _disposed = false;
  int _requestEpoch = 0;

  @override
  UserState build() {
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _requestEpoch++;
    });
    final isLoggedIn = ref.read(isLoginProvider);
    if (isLoggedIn) {
      getProfile();
    }
    return UserState(user: User.empty());
  }

  Future<void> getProfile() async {
    final currentEpoch = ++_requestEpoch;
    final res = await ApiService.get(Api.profile);
    if (_disposed || currentEpoch != _requestEpoch) {
      return;
    }
    if (res?.isSuccess == true) {
      final raw = res?.data;
      final user = raw is Map<String, dynamic>
          ? User.fromJson(raw)
          : User.empty();
      if (_disposed || currentEpoch != _requestEpoch) {
        return;
      }
      state = UserState(user: user);
    } else {
      if (_disposed || currentEpoch != _requestEpoch) {
        return;
      }
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
