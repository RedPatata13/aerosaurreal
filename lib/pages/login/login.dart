import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/google_auth_service.dart';
import '../../utils/snackbar_utils.dart';
import '../../utils/token_utils.dart';
import 'package:aerosaur_2nd_sem/state/user_store.dart';
import '../../routes/routes.dart';

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

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    try {
      await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Firebase user is null after login');

      // DEBUG: prove we have a real token BEFORE calling backend
      await _printIdToken();

      await context.read<UserStore>().loadOrCreate();

      _navigateToApp();
    } catch (e, st) {
      debugPrint('LOGIN ERROR: $e');
      debugPrintStack(stackTrace: st);
      SnackbarUtils.show(context, 'Login failed: $e', Colors.red);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      SnackbarUtils.show(context, 'Enter your email first', Colors.orange);
      return;
    }

    try {
      await _authService.sendPasswordReset(email);
      SnackbarUtils.show(context, 'Password reset email sent', Colors.green);
    } catch (_) {
      SnackbarUtils.show(context, 'Failed to send reset email', Colors.red);
    }
  }

  //temporary
  Future<void> _printIdToken() async {
    try {
      final token = await TokenUtils.getIdToken(forceRefresh: true);

      print('FIREBASE_ID_TOKEN=$token');
      print('TOKEN_DOTS=${token.split(".").length - 1}');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.show(context, 'Failed to get token: $e', Colors.red);
    }
  }

  Future<void> _googleLogin() async {
    try {
      await _googleAuthService.signOutGoogle();

      final credential = await _googleAuthService.signInWithGoogle();
      final user = credential.user;
      if (user == null)
        throw Exception('Firebase user is null after Google sign-in');

      await user.getIdToken(true);

      // DEBUG first
      await _printIdToken();

      await context.read<UserStore>().loadOrCreate();

      _navigateToApp();
    } catch (e, st) {
      debugPrint('GOOGLE LOGIN ERROR: $e');
      debugPrintStack(stackTrace: st);
      SnackbarUtils.show(context, 'Google sign in failed: $e', Colors.red);
    }
  }

  void _navigateToApp() {
    Navigator.pushReplacementNamed(context, AppRoutes.premium);
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Enter Email'),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Enter Password'),
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
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
