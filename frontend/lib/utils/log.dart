import 'package:logger/logger.dart';
import 'dart:developer' as developer;

/// Created on 2026/2/5
/// Description:
Log logger = Log();

class Log {
  static Level level = Level.all;
  static final Log _instance = Log._internal();

  Log._internal() : _logger = _buildLogger(level);
  Logger _logger;

  factory Log() {
    return _instance;
  }

  static Logger _buildLogger(Level level) {
    return Logger(
      printer: PrefixPrinter(
        PrettyPrinter(
          stackTraceBeginIndex: 1,
          methodCount: 3,
          errorMethodCount: 20,
          colors: false,
        ),
      ),
      level: level,
    );
  }

  static void setLevel(Level newLevel) {
    level = newLevel;
    _instance._logger = _buildLogger(newLevel);
  }

  void v(dynamic message) {
    _logger.t(message);
  }

  void d(dynamic message) {
    _logger.d(message);
  }

  void info(dynamic message) {
    i(message);
  }

  void i(dynamic message) {
    _logger.i(message);
  }

  void warning(dynamic message) {
    w(message);
  }

  void w(dynamic message) {
    _logger.w(message);
  }

  void severe(dynamic message) {
    e(message);
  }

  void m(dynamic message) {
    developer.log('[MESSAGE]$message');
  }

  void rtc(dynamic message) {
    developer.log('[RTC] $message');
  }

  void e(dynamic message, {StackTrace? stackTrace}) {
    _logger.e(message, stackTrace: stackTrace);
  }

  void wtf(dynamic message) {
    _logger.f(message);
  }
}
