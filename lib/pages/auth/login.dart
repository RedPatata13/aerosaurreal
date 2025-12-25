import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/snackbar_utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();
  final _googleAuthService = GoogleAuthService();
  final _userService = UserService();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  Future<void> _login() async {
    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _navigateToApp();
    } catch (_) {
      SnackbarUtils.show(context, 'Invalid credentials', Colors.red);
    }
  }

  Future<void> _forgotPassword() async {
    try {
      await _authService.sendPasswordReset(_emailController.text.trim());
      SnackbarUtils.show(context, 'Password reset email sent', Colors.green);
    } catch (_) {
      SnackbarUtils.show(context, 'Failed to send reset email', Colors.red);
    }
  }

  Future<void> _googleLogin() async {
    await _googleAuthService.handleSignIn(
      onSuccess: (credential) async {
        final user = credential.user;
        if (user != null) {
          await _userService.createUserIfNotExists(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
          );
        }
        _navigateToApp();
      },
      onError: (_) {
        SnackbarUtils.show(context, 'Google sign in failed', Colors.red);
      },
    );
  }

  void _navigateToApp() {
    Navigator.pushNamed(context, '/app');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('images/logo.png', height: 70, width: 70),
                const SizedBox(height: 10),

                Text(
                  'AEROSAUR',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Clean Air, Smart Control',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 25),

                Text(
                  'LOGIN',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 25),

                // Email
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Enter Email'),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Enter Password'),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Remember me / Forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) {
                            setState(() {
                              _rememberMe = v ?? false;
                            });
                          },
                        ),
                        const Text('Remember Me'),
                      ],
                    ),
                    TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Create account / Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/signup'),
                      child: Text(
                        'Create an account',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Or login with'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 30),

                // Google login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Image.asset('images/google_logo.png', height: 20),
                    onPressed: _googleLogin,
                    label: const Text('Google'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
