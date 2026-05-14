import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:retentio/features/auth/presentation/bloc/auth_state.dart';

class RouterRefreshBridge extends ChangeNotifier {
  RouterRefreshBridge(this._authBloc) {
    _subscription = _authBloc.stream.listen((_) => notifyListeners());
  }

  final AuthBloc _authBloc;
  late final StreamSubscription<AuthState> _subscription;

  bool get isAuthenticated =>
      _authBloc.state.status == AuthStatus.authenticated;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
