import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: Level.debug,
  );

  // Debug logs - only in debug mode
  static void debug(String message) {
    _logger.d('🔍 DEBUG: $message');
  }

  // Info logs - important app events
  static void info(String message) {
    _logger.i('ℹ️ INFO: $message');
  }

  // Warning logs - potential issues
  static void warning(String message) {
    _logger.w('⚠️ WARNING: $message');
  }

  // Error logs - actual errors
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('❌ ERROR: $message', error: error, stackTrace: stackTrace);
  }

  // Fatal logs - critical errors
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f('💀 FATAL: $message', error: error, stackTrace: stackTrace);
  }

  // Success logs - positive events
  static void success(String message) {
    _logger.i('✅ SUCCESS: $message');
  }

  // API logs - network requests
  static void api(String message) {
    _logger.i('�� API: $message');
  }

  // Notification logs
  static void notification(String message) {
    _logger.i('🔔 NOTIFICATION: $message');
  }
}
