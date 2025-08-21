// ignore_for_file: deprecated_member_use

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/wifi_service.dart';
import '../services/attendance_service.dart';
import 'profile_screen.dart';
import 'leaderboard_screen.dart';
import 'package:intl/intl.dart';
import '../helpers/logger_helper.dart';
import '../main.dart'; // For isDarkModeNotifier and toggleDarkMode

class HomeScreen extends StatefulWidget {
  // HomeScreen no longer needs these parameters as they are managed globally.
  // final bool isDarkMode;
  // final Function(bool) onToggleTheme;

  const HomeScreen({
    super.key,
    // No longer required in the constructor
    // required this.isDarkMode,
    // required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  String statusMessage = '🔍 Checking WiFi...';
  bool isMarkedToday = false;
  final String officeBSSID = '98:DA:C4:7A:43:50';
  int _selectedIndex = 0;

  List<Map<String, dynamic>> attendanceRecords = [];

  late DateTime _currentMonth;
  late DateTime _today;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _currentMonth = DateTime(_today.year, _today.month, 1);
    loadUserInfo();
    requestLocationAndMark();
    fetchAttendanceHistory(_currentMonth.year, _currentMonth.month);
  }

  /// Loads the user's name from SharedPreferences.
  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('user_name') ?? 'Guest';
    setState(() {});
  }

  /// Fetches monthly attendance history from the AttendanceService.
  Future<void> fetchAttendanceHistory(int year, int month) async {
    try {
      final List<Map<String, dynamic>> fetchedRecords =
          await AttendanceService.getMonthlyAttendanceSummary(year, month);

      final todayFormatted = DateFormat('yyyy-MM-dd').format(_today);
      // Check if attendance has already been marked for today.
      bool tempIsMarkedToday = fetchedRecords.any((record) {
        final DateTime recordDate = record['date'] as DateTime;
        final String recordDateFormatted = DateFormat(
          'yyyy-MM-dd',
        ).format(recordDate);
        return recordDateFormatted == todayFormatted;
      });

      setState(() {
        attendanceRecords = fetchedRecords;
        isMarkedToday = tempIsMarkedToday;
      });

      AppLogger.info(
        'Attendance history loaded: ${fetchedRecords.length} records',
      );
    } catch (e) {
      AppLogger.error('Error fetching attendance history', e);
      setState(() {
        statusMessage = "Error loading history. Please try again.";
      });
    }
  }

  /// Requests location permissions and then proceeds to check and mark attendance.
  Future<void> requestLocationAndMark() async {
    var status = await Permission.locationWhenInUse.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        setState(() {
          statusMessage = '❌ Location permission is required to detect WiFi.';
        });
        return;
      }
    }
    checkAndMarkAttendance();
  }

  Future<void> requestNotificationPermission() async {
    // Check if Android 13+
    if (await Permission.notification.isDenied) {
      // Request permission
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() {
          statusMessage =
              '❌ Notification permission is required to send reminders.';
        });
        return;
      }
    }
  }

  /// Checks WiFi BSSID and time constraints before marking attendance.
  Future<void> checkAndMarkAttendance() async {
    final bssid = await WifiService.getConnectedWifiBSSID();
    final cleanBssid = bssid?.toUpperCase().trim();

    if (cleanBssid == null || cleanBssid != officeBSSID) {
      setState(() {
        statusMessage =
            cleanBssid == null
                ? '⚠️ Could not detect WiFi. Make sure location/WiFi is enabled.'
                : '⚠️ Connect to the Office WiFi to Mark Attendance.';
      });
      return;
    }

    if (isMarkedToday) {
      setState(() {
        statusMessage = "✅ Attendance already marked today.";
      });
      return;
    }

    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    String label;
    if (hour < 9) {
      setState(() {
        statusMessage = "⏰ Attendance can be marked only after 9:00 AM.";
      });
      return;
    } else if (hour >= 14) {
      setState(() {
        statusMessage = "❌ Attendance cannot be marked after 2:00 PM.";
      });
      return;
    } else if (hour < 10 || (hour == 10 && minute == 0)) {
      label = "Present";
    } else if (hour < 13) {
      label = "Late";
    } else {
      label = "Half Day";
    }

    final result = await AttendanceService.markAttendance(label);

    // After marking, refetch the history to update the calendar and status.
    await fetchAttendanceHistory(_currentMonth.year, _currentMonth.month);

    setState(() {
      statusMessage = result;
    });
  }

  /// Generates a list of DateTime objects for the given month, including
  /// placeholder DateTime(0) for leading empty days in the calendar grid.
  List<DateTime> _getDaysInMonth(DateTime month) {
    final List<DateTime> days = [];
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // Add empty DateTime objects for days before the 1st of the month
    for (int i = 0; i < firstDayOfMonth.weekday - 1; i++) {
      days.add(DateTime(0)); // Placeholder for empty cells
    }

    // Add actual days of the month
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      days.add(firstDayOfMonth.add(Duration(days: i)));
    }
    return days;
  }

  /// Converts the list of attendance records into a map for quick lookup by date.
  Map<DateTime, String> _getAttendanceMap() {
    return {
      for (var record in attendanceRecords)
        DateTime(record['date'].year, record['date'].month, record['date'].day):
            record['status'] as String,
    };
  }

  /// Builds the calendar grid for displaying attendance summary.
  Widget _buildCalendarGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final daysInMonth = _getDaysInMonth(_currentMonth);
    final attendanceMap = _getAttendanceMap();

    const List<String> weekDays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return Column(
      children: [
        // Month navigation row
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1, // Go to previous month
                      1,
                    );
                    fetchAttendanceHistory(
                      _currentMonth.year,
                      _currentMonth.month,
                    );
                  });
                },
                color: colorScheme.primary,
              ),
              Text(
                DateFormat(
                  'MMMM yyyy',
                ).format(_currentMonth), // Display current month and year
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1, // Go to next month
                      1,
                    );
                    fetchAttendanceHistory(
                      _currentMonth.year,
                      _currentMonth.month,
                    );
                  });
                },
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              weekDays
                  .map(
                    (day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar days grid
        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(), // Disable scrolling for grid
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, // 7 days in a week
            mainAxisSpacing: 4.0,
            crossAxisSpacing: 4.0,
            childAspectRatio: 1.0,
          ),
          itemCount: daysInMonth.length,
          itemBuilder: (context, index) {
            final day = daysInMonth[index];
            final bool isEmptyDay = day.year == 0; // Check for placeholder day

            // Normalize today's date for accurate comparison
            final DateTime normalizedToday = DateTime(
              _today.year,
              _today.month,
              _today.day,
            );
            final bool isToday =
                !isEmptyDay &&
                DateTime(
                  day.year,
                  day.month,
                  day.day,
                ).isAtSameMomentAs(normalizedToday);

            final String? attendanceStatus =
                attendanceMap[DateTime(day.year, day.month, day.day)];

            // Default styles

            Color backgroundColor = colorScheme.surfaceContainerHighest
                .withOpacity(0.3);
            Color textColor = colorScheme.onSurface;
            IconData? icon;
            Color? iconColor;

            if (isEmptyDay) {
              return Container(); // Render empty container for placeholder days
            }

            // Apply styles based on attendance status
            if (attendanceStatus != null) {
              switch (attendanceStatus) {
                case 'Present':
                  backgroundColor = Colors.green.shade400;
                  textColor = Colors.white;
                  icon = Icons.check_circle;
                  iconColor = Colors.white;
                  break;
                case 'Late':
                  backgroundColor = Colors.orange.shade400;
                  textColor = Colors.white;
                  icon = Icons.watch_later_outlined;
                  iconColor = Colors.white;
                  break;
                case 'Half Day':
                  backgroundColor = Colors.blue.shade400;
                  textColor = Colors.white;
                  icon = Icons.more_horiz;
                  iconColor = Colors.white;
                  break;
                default:
                  backgroundColor = colorScheme.primary.withOpacity(0.7);
                  textColor = colorScheme.onPrimary;
                  icon = Icons.info_outline;
                  iconColor = colorScheme.onPrimary;
              }
            } else if (isToday) {
              // Special styling for the current day
              backgroundColor = colorScheme.primary.withOpacity(0.2);
              textColor = colorScheme.primary;
            }

            return GestureDetector(
              onTap: () {
                if (!isEmptyDay) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${DateFormat('dd MMMM yyyy').format(day)}: ${attendanceStatus ?? 'No attendance record'}',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Card(
                color: backgroundColor,
                elevation: isToday ? 4 : 1, // Higher elevation for today
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side:
                      isToday
                          ? BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ) // Border for today
                          : BorderSide.none,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}', // Display day number
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (icon != null)
                      Icon(
                        icon,
                        size: 12,
                        color: iconColor,
                      ), // Display attendance icon
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Determines which screen body to display based on the selected index in the bottom navigation.
  Widget getBody(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    // borderColor now directly uses primary or error color without checking isDarkMode.
    final borderColor = isMarkedToday ? colorScheme.primary : colorScheme.error;

    switch (_selectedIndex) {
      case 0: // Home screen content
        return SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Welcome, $userName",
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Attendance status message container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isMarkedToday
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            color: borderColor,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              statusMessage,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: borderColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      "📅 Attendance Summary",
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Calendar grid for attendance summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _buildCalendarGrid(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case 1: // Leaderboard screen
        return const LeaderboardScreen(); // Display the leaderboard screen
      case 2: // Profile screen
        // Now, ProfileScreen gets its theme info and toggle function from the global notifier.
        return ValueListenableBuilder<bool>(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDarkMode, child) {
            return ProfileScreen(
              isDarkMode: isDarkMode,
              onToggleTheme: toggleDarkMode, // Pass the global toggle function
            );
          },
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "Home"
              : _selectedIndex == 1
              ? "Leaderboard"
              : "Profile",
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: getBody(context),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex, // Set the current index for the navigation bar.
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Update the selected index on tap.
          });
        },
        backgroundColor: theme.colorScheme.surface,
        color: theme.colorScheme.primary,
        buttonBackgroundColor: theme.colorScheme.primary,
        height: 50.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.leaderboard, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
      ),
    );
  }
}
