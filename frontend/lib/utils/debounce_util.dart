part of utils;


/**
 * Created on 2026/2/5
 * Description:
 */
class DebounceUtil {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  DebounceUtil({required this.milliseconds});

  void run(VoidCallback action) {
    if (null != _timer) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}