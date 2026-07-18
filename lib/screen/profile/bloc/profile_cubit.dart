import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/models/user.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/auth_service.dart';
import 'package:retentio/services/index.dart';

class ProfileState {
  const ProfileState({
    required this.user,
    this.status = ProfileStatus.loading,
    this.errorMessage,
  });

  final User user;
  final ProfileStatus status;
  final String? errorMessage;

  ProfileState copyWith({
    User? user,
    ProfileStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) => ProfileState(
    user: user ?? this.user,
    status: status ?? this.status,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  factory ProfileState.initial() =>
      ProfileState(user: User.empty(), status: ProfileStatus.loading);
}

enum ProfileStatus { loading, loaded, error }

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
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    dynamic res;
    try {
      res = await ApiService.get(Api.profile);
    } catch (e) {
      if (_disposed || currentEpoch != _requestEpoch) {
        return;
      }
      emit(
        state.copyWith(
          user: User.empty(),
          status: ProfileStatus.error,
          errorMessage: e.toString(),
        ),
      );
      return;
    }
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
      emit(
        state.copyWith(
          user: user,
          status: ProfileStatus.loaded,
          clearError: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        user: User.empty(),
        status: ProfileStatus.error,
        errorMessage: res?.msg ?? 'Error retrieving user profile',
      ),
    );
  }

  Future<void> logout() async {
    emit(
      state.copyWith(
        user: User.empty(),
        status: ProfileStatus.loaded,
        clearError: true,
      ),
    );
    await AuthService.logoutByAuthBloc();
  }
}
