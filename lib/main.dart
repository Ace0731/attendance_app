import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/splash_screen.dart';
import 'data/constants.dart';
import 'helpers/notification_helper.dart';
import 'helpers/logger_helper.dart';
import 'services/file_logging_service.dart'; // 👈 Add this import

final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);

// Toggle and persist theme mode
Future<void> toggleDarkMode(bool enabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(KCOnstants.themeModeKey, enabled);
  isDarkModeNotifier.value = enabled;
  AppLogger.info('Theme mode changed to: ${enabled ? "Dark" : "Light"}');
}

// Request notification permission for Android 13+ devices
Future<void> requestNotificationPermission() async {
  if (await Permission.notification.isDenied) {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      AppLogger.success('Notification permission granted');
    } else {
      AppLogger.warning('Notification permission denied');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔧 Initialize Logging File System First
  await FileLoggingService.initialize(); // ✅ Required for file logging

  AppLogger.info('App starting...');

  // Ask for permissions before anything else
  await requestNotificationPermission();

  // Initialize Awesome Notifications
  await initializeNotifications();
  AppLogger.success('Notifications initialized');

  // Schedule Notifications
  await scheduleAttendanceNotifications();
  AppLogger.success('Attendance notifications scheduled');

  // Setup notification listeners
  listenToNotificationActions();
  AppLogger.info('Notification listeners configured');

  // Load Theme Preference
  final prefs = await SharedPreferences.getInstance();
  final bool? savedDarkMode = prefs.getBool(KCOnstants.themeModeKey);
  isDarkModeNotifier.value = savedDarkMode ?? false;

  AppLogger.success('App initialization completed');

  runApp(const MyApp(isDarkMode: true));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required bool isDarkMode});

  @override
  Widget build(BuildContext context) {
    const Color defaultSeedColor = Color.fromARGB(255, 57, 145, 217);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final lightColorScheme =
            lightDynamic ?? ColorScheme.fromSeed(seedColor: defaultSeedColor);
        final darkColorScheme =
            darkDynamic ??
            ColorScheme.fromSeed(
              seedColor: defaultSeedColor,
              brightness: Brightness.dark,
            );

        return ValueListenableBuilder<bool>(
          valueListenable: isDarkModeNotifier,
          builder: (context, isDarkMode, child) {
            return MaterialApp(
              title: 'WiFi Attendance',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: lightColorScheme,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: darkColorScheme,
                brightness: Brightness.dark,
              ),
              themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
