import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 一个混入（mixin）用于扩展 [Notifier] 类，提供状态更新功能。
///
/// 该混入定义了一个 `update` 方法，允许通过回调函数修改当前状态。
///
/// 泛型参数:
///   - [ValueT]: 表示状态的类型。
mixin NotifierMixin<ValueT> on Notifier<ValueT> {
  /// 使用提供的回调函数更新当前状态。
  ///
  /// 参数:
  ///   - [cb]: 一个接受当前状态并返回新状态的回调函数。
  ///
  /// 返回值:
  ///   返回更新后的状态值。
  ValueT update(ValueT Function(ValueT state) cb) => state = cb(state);
}
