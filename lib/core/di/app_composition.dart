import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_event.dart';

import '../navigation/router_refresh_bridge.dart';
import 'app_service_locator.dart';

class AppComposition {
  AppComposition({required this.authBloc, required this.routerRefreshBridge});

  final AuthBloc authBloc;
  final RouterRefreshBridge routerRefreshBridge;
}

Future<AppComposition> createAppComposition() async {
  await registerCoreDependencies();
  final authBloc = sl<AuthBloc>();
  authBloc.add(const AuthRestoreSessionRequested());

  return AppComposition(
    authBloc: authBloc,
    routerRefreshBridge: sl<RouterRefreshBridge>(),
  );
}
