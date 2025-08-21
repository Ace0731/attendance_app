import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/logger_helper.dart';
import '../data/constants.dart';

class AttendanceService {
  static String get _baseUrl => '${AppConstants.baseUrl}/api/attendance';

  // Private helper to get the JWT token from SharedPreferences
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token'); // ✅ from first version
  }

  /// Marks attendance for the current user with the given status label.
  /// Sends UserId, MarkedAt, and Status to the backend.
  static Future<String> markAttendance(String statusLabel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token'); // ✅
      final int? userId = prefs.getInt('user_id');

      if (token == null || userId == null) {
        AppLogger.error('Authentication token or user ID not found');
        return '❌ Authentication failed. Please login again.';
      }

      final now = DateTime.now();
      final markedAt = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(now); // ✅ Your desired format

      AppLogger.api('Marking attendance: $statusLabel at $markedAt');

      final response = await http.post(
        Uri.parse('$_baseUrl/mark'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ID': userId,
          'MarkedAt': markedAt,
          'Status': statusLabel,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          AppLogger.success('Attendance marked successfully: $statusLabel');
          return '✅ Attendance marked as $statusLabel successfully!';
        } else {
          AppLogger.warning('Mark failed: ${jsonResponse['message']}');
          return '⚠️ ${jsonResponse['message'] ?? 'Failed to mark attendance.'}';
        }
      } else {
        AppLogger.error('API error: ${response.statusCode} - ${response.body}');
        return '❌ Failed to mark attendance. Please try again.';
      }
    } catch (e) {
      AppLogger.error('Error marking attendance', e);
      return '❌ Network error. Please check your connection.';
    }
  }

  /// Fetches monthly attendance summary for a given year and month.
  static Future<List<Map<String, dynamic>>> getMonthlyAttendanceSummary(
    int year,
    int month,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('jwt_token'); // ✅
      final int? userId = prefs.getInt('user_id');

      if (token == null || userId == null) {
        AppLogger.error('Authentication token or user ID not found');
        return [];
      }

      AppLogger.api('Fetching monthly attendance summary for $year-$month');

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/monthly-summary?userId=$userId&year=$year&month=$month',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> recordsList =
            jsonResponse['attendanceRecords'] ?? [];

        List<Map<String, dynamic>> parsedRecords = [];
        for (var recordJson in recordsList) {
          if (recordJson is Map<String, dynamic>) {
            try {
              DateTime recordDate = DateTime.parse(
                recordJson['Date'] as String,
              );
              String status = recordJson['Status'] as String? ?? 'Unknown';

              parsedRecords.add({'date': recordDate, 'status': status});
            } catch (e) {
              AppLogger.error("Error parsing record: $recordJson", e);
            }
          }
        }

        AppLogger.success(
          'Monthly summary fetched: ${parsedRecords.length} records',
        );
        return parsedRecords;
      } else {
        AppLogger.error('API error fetching summary: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      AppLogger.error('Exception fetching monthly summary', e);
      return [];
    }
  }

  /// Fetches the overall attendance summary for all users (Leaderboard).
  static Future<List<Map<String, dynamic>>> getUserSummary() async {
    final token = await _getToken(); // ✅ uses jwt_token

    if (token == null) {
      throw Exception('Authentication token not found. Please log in.');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user-summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse
            .map((data) => data as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception(
          'Failed to load user summary: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Network or parsing error fetching user summary: $e');
    }
  }
}
