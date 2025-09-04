import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'logger_helper.dart';

Future<void> initializeNotifications() async {
  try {
    await AwesomeNotifications().initialize(
      null, // null for default app icon
      [
        NotificationChannel(
          channelKey: 'attendance_channel',
          channelName: 'Attendance Reminders',
          channelDescription: 'Notifications for attendance marking',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
      ],
    );

    // Request notification permissions
    await AwesomeNotifications().requestPermissionToSendNotifications();
    AppLogger.success('Notifications initialized successfully');
  } catch (e) {
    AppLogger.error('Failed to initialize notifications', e);
  }
}

Future<void> scheduleAttendanceNotifications() async {
  try {
    // Cancel any existing scheduled notifications
    await AwesomeNotifications().cancelAllSchedules();

    // Schedule notifications for Monday to Friday at 9:30 AM
    for (int dayOfWeek = 1; dayOfWeek <= 5; dayOfWeek++) {
      // Monday = 1, Friday = 5
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: dayOfWeek,
          channelKey: 'attendance_channel',
          title: 'Attendance Reminder',
          body: 'Click me to mark attendance',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          autoDismissible: false,
          criticalAlert: true,
        ),
        schedule: NotificationCalendar(
          weekday: dayOfWeek,
          hour: 9,
          minute: 50,
          second: 0,
          millisecond: 0,
          repeats: true,
          preciseAlarm: true,
          allowWhileIdle: true,
        ),
      );
    }
    AppLogger.success('Attendance notifications scheduled');
  } catch (e) {
    AppLogger.error('Failed to schedule attendance notifications', e);
  }
}

Future<void> cancelAllNotifications() async {
  await AwesomeNotifications().cancelAll();
  await AwesomeNotifications().cancelAllSchedules();
}

// Listen to notification actions
void listenToNotificationActions() {
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: (ReceivedAction receivedAction) async {
      // When notification is tapped, it will open the app
      // The app will handle WiFi checking and attendance marking
      AppLogger.notification('Notification tapped - opening app');
    },
  );
}
