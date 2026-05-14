import 'package:get_it/get_it.dart';

import 'package:retentio/features/auth/data/datasources/local_auth_data_source.dart';
import 'package:retentio/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:retentio/features/auth/domain/repositories/auth_repository.dart';
import 'package:retentio/features/auth/domain/usecases/login.dart';
import 'package:retentio/features/auth/domain/usecases/logout.dart';
import 'package:retentio/features/auth/domain/usecases/restore_session.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart';

import '../navigation/router_refresh_bridge.dart';

final GetIt sl = GetIt.instance;

Future<GetIt> registerCoreDependencies() async {
  if (!sl.isRegistered<LocalAuthDataSource>()) {
    sl.registerLazySingleton<LocalAuthDataSource>(
      () => const LocalAuthDataSource(),
    );
  }

  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl<LocalAuthDataSource>()),
    );
  }

  if (!sl.isRegistered<RestoreSession>()) {
    sl.registerLazySingleton<RestoreSession>(
      () => RestoreSession(sl<AuthRepository>()),
    );
  }

  if (!sl.isRegistered<Login>()) {
    sl.registerLazySingleton<Login>(() => Login(sl<AuthRepository>()));
  }

  if (!sl.isRegistered<Logout>()) {
    sl.registerLazySingleton<Logout>(() => Logout(sl<AuthRepository>()));
  }

  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        restoreSession: sl<RestoreSession>(),
        login: sl<Login>(),
        logout: sl<Logout>(),
      ),
    );
  }

  if (!sl.isRegistered<RouterRefreshBridge>()) {
    sl.registerLazySingleton<RouterRefreshBridge>(
      () => RouterRefreshBridge(sl<AuthBloc>()),
    );
  }

  return sl;
}
