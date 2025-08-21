// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
// import 'package:attendance_app/helpers/notification_helper.dart';

import 'login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../data/constants.dart';
import '../main.dart'; // Make sure this path is correct

class ProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const ProfileScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

// class NotificationTestWidget extends StatelessWidget {
//   const NotificationTestWidget({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: ElevatedButton.icon(
//         icon: const Icon(Icons.notifications_active),
//         label: const Text("Send Test Notification"),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.blueAccent,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//         ),
//         onPressed: () async {
//           try {
//             // Don't call initializeNotifications() here if already done at app startup!

//             // Pass custom message to notification function
//             await showReminderNotification("This is a test notification 🔔");

//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text("Notification sent! Check your tray."),
//               ),
//             );
//           } catch (e) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text("Failed to send notification: $e")),
//             );
//           }
//         },
//       ),
//     );
//   }
// }

class _ProfileScreenState extends State<ProfileScreen> {
  String name = '';
  String email = '';
  String department = '';
  File? profileImage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('user_image_path');

    setState(() {
      name = prefs.getString('user_name') ?? '';
      email = prefs.getString('user_email') ?? '';
      department = prefs.getString('user_department') ?? '';

      if (imagePath != null && File(imagePath).existsSync()) {
        profileImage = File(imagePath);
      }

      isLoading = false;
    });
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final newImage = await File(
        pickedFile.path,
      ).copy('${directory.path}/${p.basename(pickedFile.path)}');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_image_path', newImage.path);

      setState(() {
        profileImage = newImage;
      });
    }
  }

  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear first

    // Only navigate if the widget is still mounted
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Widget buildInfoCard(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary, size: 28),
        title: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(value, style: theme.textTheme.bodyLarge),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage:
                                profileImage != null
                                    ? FileImage(profileImage!)
                                    : null,
                            child:
                                profileImage == null
                                    ? Icon(
                                      Icons.person,
                                      size: 50,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          "Tap to change photo",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildInfoCard(Icons.person, "Name", name),
                      buildInfoCard(Icons.email, "Email", email),
                      buildInfoCard(Icons.business, "Designation", department),

                      const SizedBox(height: 30),
                      Text(
                        "Settings",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: theme.colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  isDarkModeNotifier.value =
                                      !isDarkModeNotifier.value;
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                    KCOnstants.themeModeKey,
                                    isDarkModeNotifier.value,
                                  );
                                },
                                icon: ValueListenableBuilder(
                                  valueListenable: isDarkModeNotifier,
                                  builder: (context, isDarkMode, child) {
                                    return Icon(
                                      isDarkMode
                                          ? Icons.dark_mode
                                          : Icons.light_mode,
                                    );
                                  },
                                ),
                              ),
                              Switch(
                                value: widget.isDarkMode,
                                onChanged: (val) => widget.onToggleTheme(val),
                                activeThumbColor: theme.colorScheme.primary,
                                inactiveThumbColor: Colors.grey.shade300,
                                inactiveTrackColor: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// ✅ Send Logs Card
                      // const SizedBox(height: 20),
                      // Card(
                      //   elevation: 1,
                      //   margin: const EdgeInsets.symmetric(vertical: 8),
                      //   shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(16),
                      //   ),
                      //   color: theme.colorScheme.surface,
                      //   child: Padding(
                      //     padding: const EdgeInsets.all(16.0),
                      //     child: Column(
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         Text(
                      //           'Send Logs',
                      //           style: theme.textTheme.titleMedium?.copyWith(
                      //             fontWeight: FontWeight.bold,
                      //           ),
                      //         ),
                      //         const SizedBox(height: 12),
                      //         SizedBox(
                      //           width: double.infinity,
                      //           child: ElevatedButton.icon(
                      //             onPressed:
                      //                 () => FileLoggingService.emailLogs(
                      //                   to: 'anand@innovaneers.in',
                      //                   subject: 'Logs from Attendance App',
                      //                 ),

                      //             icon: const Icon(Icons.send),
                      //             label: const Text('Send Logs to Support'),
                      //             style: ElevatedButton.styleFrom(
                      //               padding: const EdgeInsets.symmetric(
                      //                 vertical: 14,
                      //               ),
                      //               shape: RoundedRectangleBorder(
                      //                 borderRadius: BorderRadius.circular(12),
                      //               ),
                      //             ),
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ),

                      /// Logout
                      const SizedBox(height: 30),
                      FilledButton.icon(
                        onPressed: () => logoutUser(context),
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            233,
                            11,
                            11,
                          ),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
