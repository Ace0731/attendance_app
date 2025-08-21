import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // Ensure this path is correct
import '../data/constants.dart';

/// LoginScreen is a StatefulWidget because it manages its own internal state
/// like text controller values, loading status, and password visibility.
/// Theme management responsibilities have been removed from this widget.
class LoginScreen extends StatefulWidget {
  // Removed `isDarkMode` and `onToggleTheme` parameters.
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Text controllers for input fields.
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  // GlobalKey for the Form widget to manage form validation.
  final _formKey = GlobalKey<FormState>();

  // State variables for UI elements.
  bool isLoading = false; // Controls visibility of loading indicator.
  bool rememberMe = false; // State for the "Remember Me" checkbox.
  bool _obscurePassword = true; // State for password visibility toggle.

  @override
  void initState() {
    super.initState();
    // Load the "Remember Me" preference when the screen initializes.
    loadRememberMe();
    // Attempt to auto-login if a token is remembered.
    autoLoginIfRemembered();
  }

  /// Loads the 'remember_me' preference and user email from SharedPreferences.
  Future<void> loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rememberMe = prefs.getBool('remember_me') ?? false;
      if (rememberMe) {
        emailController.text = prefs.getString('user_email') ?? '';
      }
    });
  }

  /// Checks for a stored JWT token and 'remember_me' flag to automatically
  /// navigate to the HomeScreen.
  Future<void> autoLoginIfRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final remember = prefs.getBool('remember_me') ?? false;

    // If remember_me is true and a token exists, proceed to Home Screen.
    if (remember && token != null && token.isNotEmpty) {
      if (!mounted) return; // Prevent navigation if widget is disposed.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => const HomeScreen(), // Navigating without theme parameters
        ),
      );
    }
  }

  /// Handles the login process by sending user credentials to the API.
  Future<void> login() async {
    // Validate the form fields before proceeding.
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true); // Show loading indicator.

    final url = '${AppConstants.baseUrl}/api/employees/login';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email': emailController.text.trim(),
          'Password': passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Save user data and JWT token to SharedPreferences upon successful login.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setInt('user_id', data['user']['ID']);
        await prefs.setString('user_name', data['user']['Name']);
        await prefs.setString('user_email', data['user']['Email']);
        await prefs.setString('user_department', data['user']['Designation']);
        await prefs.setBool(
          'remember_me',
          rememberMe,
        ); // Save rememberMe preference.

        if (!mounted) return; // Prevent navigation if widget is disposed.
        // Navigate to the Home Screen on successful login.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    const HomeScreen(), // Navigating without theme parameters
          ),
        );
      } else {
        // Handle login errors based on status code.
        final errorMsg =
            response.statusCode == 401
                ? "Invalid email or password."
                : "Server error: ${response.statusCode}";
        showSnackBar(errorMsg);
      }
    } catch (e) {
      // Catch and display any network or other errors.
      showSnackBar("Error: ${e.toString()}");
    }

    setState(() => isLoading = false); // Hide loading indicator.
  }

  /// Displays a SnackBar with a given message.
  void showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows an AlertDialog prompting the user to contact an administrator for password reset.
  void showContactAdminDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Reset Password"),
            content: const Text(
              "Please contact your administrator to reset the password.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme and color scheme for consistent styling.
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Use theme background color.
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
            color: colorScheme.surface, // Use theme surface color for the card.
            shadowColor: colorScheme.shadow,
            surfaceTintColor: colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Login", style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Icon(
                      Icons.account_circle,
                      size: 80,
                      color: colorScheme.primary, // Use primary color for icon.
                    ),
                    const SizedBox(height: 24),

                    /// Email input field.
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person),
                        labelText: "Email",
                        border: const OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? "Enter email"
                                  : null,
                    ),
                    const SizedBox(height: 16),

                    /// Password input field with visibility toggle.
                    TextFormField(
                      controller: passwordController,
                      obscureText:
                          _obscurePassword, // Controls text visibility.
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            // Icon changes based on `_obscurePassword` state.
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            // Toggle password visibility state.
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      validator:
                          (value) =>
                              (value == null || value.isEmpty)
                                  ? "Enter password"
                                  : null,
                    ),
                    const SizedBox(height: 10),

                    /// Forgot password button.
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: showContactAdminDialog,
                        child: const Text("Forgot password?"),
                      ),
                    ),
                    const SizedBox(height: 10),

                    /// "Remember Me" checkbox. Removed theme toggle icon.
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.start, // Align to start
                      children: [
                        // Remember Me checkbox.
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value ?? false;
                                });
                              },
                            ),
                            const Text("Remember Me"),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    /// Login button.
                    isLoading
                        ? const CircularProgressIndicator() // Show loading spinner if `isLoading` is true.
                        : FilledButton(
                          onPressed:
                              login, // Call the `login` function when pressed.
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              50,
                            ), // Full width button.
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                50,
                              ), // Rounded corners.
                            ),
                          ),
                          child: const Text(
                            "Sign in",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
