import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/core/network/connectivity_service.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/models/user.dart';
import 'package:retentio/services/apis/api_service.dart';
import 'package:retentio/services/apis/auth_service.dart';
import 'package:retentio/services/index.dart';
import 'package:retentio/utils/log.dart';

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
  ProfileCubit({
    Future<void> Function()? wipeOfflineData,
    Future<bool> Function()? isOnline,
  }) : _wipeOfflineData =
           wipeOfflineData ??
           OfflineLearningSessions.instance.wipeCurrentAccount,
       _isOnline = isOnline ?? hasNetworkConnection,
       super(ProfileState.initial()) {
    getProfile();
  }

  final Future<void> Function() _wipeOfflineData;
  final Future<bool> Function() _isOnline;
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
      final user = raw is Map
          ? User.fromJson(Map<String, dynamic>.from(raw))
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

  /// Deletes the account and its offline data. Returns null on success,
  /// otherwise the raw server message. The caller logs out on success; a
  /// failed offline wipe is retried before the account id is opened again.
  Future<String?> deleteAccount(String password) async {
    if (!await _isOnline().catchError((Object _) => true)) {
      return 'Connect error';
    }
    final res = await AuthService.deleteAccount(password: password);
    if (res?.isSuccess != true) {
      return res?.msg ?? 'Unknown error';
    }
    try {
      await _wipeOfflineData();
    } catch (e) {
      logger.w('offline delete account: $e');
    }
    return null;
  }
}
