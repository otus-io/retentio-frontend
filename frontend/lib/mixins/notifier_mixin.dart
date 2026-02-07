import 'package:flutter_riverpod/flutter_riverpod.dart';

/**
 * Created on 2026/2/7
 * Description:
 */
mixin NotifierMixin<ValueT> on Notifier<ValueT> {
  ValueT update(ValueT Function(ValueT state) cb) => state = cb(state);
}