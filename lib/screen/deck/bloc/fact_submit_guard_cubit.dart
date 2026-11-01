import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/core/network/connectivity_service.dart';

/// Owns the pre-submit connectivity guard for the fact composer
/// ([FactAdd]/[FactEdit]), keeping the connectivity service out of the widget
/// layer. Mirrors the injected `_isOnline` seam used by [QaModeCubit].
class FactSubmitGuardCubit extends Cubit<void> {
  FactSubmitGuardCubit({Future<bool> Function()? isOnline})
    : _isOnline = isOnline ?? hasNetworkConnection,
      super(null);

  final Future<bool> Function() _isOnline;

  /// Whether a submit may proceed. Treats a connectivity-check failure as
  /// online so a flaky probe never blocks the user.
  Future<bool> canSubmit() async {
    try {
      return await _isOnline();
    } catch (_) {
      return true;
    }
  }
}
