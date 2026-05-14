import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/models/user.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/auth_service.dart';
import 'package:retentio/services/index.dart';

class ProfileState {
  const ProfileState({required this.user});

  final User user;

  ProfileState copyWith({User? user}) => ProfileState(user: user ?? this.user);

  factory ProfileState.initial() => ProfileState(user: User.empty());
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileState.initial()) {
    getProfile();
  }

  bool _disposed = false;
  int _requestEpoch = 0;

  @override
  Future<void> close() {
    _disposed = true;
    _requestEpoch++;
    return super.close();
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
      emit(state.copyWith(user: user));
      return;
    }
    emit(state.copyWith(user: User.empty()));
  }

  Future<void> logout() async {
    emit(state.copyWith(user: User.empty()));
    await AuthService.logoutByAuthBloc();
  }
}
