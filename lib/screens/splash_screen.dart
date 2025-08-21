import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // Make sure this path is correct
import 'login_screen.dart'; // Make sure this path is correct

class SplashScreen extends StatefulWidget {
  // Removed isDarkMode and onToggleTheme parameters, as the splash screen
  // will no longer directly manage or pass the theme toggle.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), checkLoginStatus);
  }

  /// Checks the login status using SharedPreferences and navigates
  /// to either HomeScreen or LoginScreen accordingly.
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(
      'jwt_token',
    ); // Get the JWT token from SharedPreferences

    if (!mounted) {
      return; // Check if the widget is still in the tree before navigating
    }

    // Navigate to the appropriate screen based on the token's presence.
    // isDarkMode and onToggleTheme are no longer passed, as the theme
    // should be managed at a higher level (e.g., MaterialApp or a global ValueNotifier).
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                (token != null && token.isNotEmpty)
                    ? const HomeScreen() // Navigating without theme parameters
                    : const LoginScreen(), // Navigating without theme parameters
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor:
          colorScheme.surface, // Set background color based on current theme
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min, // Keep column content compact
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(
                16,
              ), // Change this to control roundness
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 296,
                height: 296,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 10),
            Text(
              "by Innovaneers Technologies",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.secondary, // Text color adapts to theme
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(), // Loading indicator
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
