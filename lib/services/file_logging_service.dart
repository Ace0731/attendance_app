import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../helpers/logger_helper.dart';
import 'package:share_plus/share_plus.dart';

class FileLoggingService {
  static File? _logFile;

  /// Initializes the log file in the app's document directory
  static Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/app_logs.txt');

      // Ensure the file exists
      if (!(await _logFile!.exists())) {
        await _logFile!.create(recursive: true);
      }

      AppLogger.success('File logging initialized at: ${_logFile!.path}');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize file logging', e, stack);
    }
  }

  /// Writes a log entry to the log file with timestamp
  static Future<void> writeLog(String message) async {
    try {
      if (_logFile != null) {
        final timestamp = DateTime.now().toIso8601String();
        await _logFile!.writeAsString(
          '[$timestamp] $message\n',
          mode: FileMode.append,
        );
      } else {
        AppLogger.warning('Log file is null, cannot write log');
      }
    } catch (e, stack) {
      AppLogger.error('Failed to write to log file', e, stack);
    }
  }

  /// Returns all logs from the log file as a string
  static Future<String> getLogs() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
      return 'No logs available';
    } catch (e, stack) {
      AppLogger.error('Failed to read log file', e, stack);
      return 'Error reading logs';
    }
  }

  /// Shares the log file via Share Plus (supports Gmail, WhatsApp, Drive, etc.)
  static Future<void> emailLogs({
    String to = 'anand@innovaneers.in',
    String subject = 'App Logs',
  }) async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await Share.shareXFiles(
          [XFile(_logFile!.path)],
          subject: subject,
          text: 'Please find the app logs attached.\n\nSend to: $to',
        );
      } else {
        AppLogger.warning('No log file available to share');
      }
    } catch (e, stack) {
      AppLogger.error('Failed to share log file', e, stack);
    }
  }
}
