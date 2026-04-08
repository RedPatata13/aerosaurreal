import 'package:aerosaur/services/api/api_exceptions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../components/app_dialogs.dart';
import '../../services/auth/auth_service.dart';
import '../../services/auth/google_auth_service.dart';
import '../../components/input_field.dart';
import '../../components/password_input_field.dart';
import 'package:aerosaur/services/repositories/user_repository.dart';
import 'package:aerosaur/state/user_store.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final authService = AuthService();

  bool _isLoading = false;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      await showAppMessageDialog(
        context,
        title: 'Check Your Details',
        message: 'Please correct the errors in the form before continuing.',
      );
      return;
    }

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      await showAppMessageDialog(
        context,
        title: 'Passwords Do Not Match',
        message: 'Make sure both password fields are the same.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authService.signUp(
        email: email,
        password: password,
        username: username,
      );

      try {
        await context.read<UserRepository>().getOrCreateProfile(
          username: username,
        );
      } on ApiException catch (e) {
        if (e.statusCode == 409) {
          await showAppMessageDialog(
            context,
            title: 'Username Unavailable',
            message: 'Username already taken. Please choose another.',
          );

          final currentUser = FirebaseAuth.instance.currentUser;
          await currentUser?.delete();
          await FirebaseAuth.instance.signOut();
          return;
        }
        rethrow;
      }

      if (!mounted) return;

      _showSnackbar(
        "Sign up successful! Please verify your email. Redirecting to Login...",
        Colors.green,
      );

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'An error occurred. Please check your credentials.';
      }
      _showSnackbar(message, Colors.red);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar("An unexpected error occurred: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignUp() async {
    try {
      final credential = await _googleAuthService.signInWithGoogle();
      final user = credential.user;

      if (user == null) {
        throw Exception('Firebase user is null after Google sign-in');
      }

      await context.read<UserStore>().loadOrCreate();

      if (!mounted) return;
      _showSnackbar('Signed up with Google!', Colors.green);
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Google sign-up failed: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/logo.png',
                height: 70,
                width: 70,
                fit: BoxFit.contain,
              ),
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
                'SIGN UP',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 25),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    InputField(
                      label: "Username",
                      hintText: "Enter your Username",
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 20),
                    InputField(
                      label: "Email",
                      hintText: "Enter your Email",
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    PasswordInputField(
                      label: "Password",
                      hintText: "Enter your Password",
                      controller: _passwordController,
                    ),
                    const SizedBox(height: 20),
                    PasswordInputField(
                      label: "Confirm Password",
                      hintText: "Confirm your Password",
                      controller: _confirmPasswordController,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
                    child: Text(
                      "Login Account",
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
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Sign up'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Row(
                children: const [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text("Or register with"),
                  ),
                  Expanded(child: Divider(thickness: 1)),
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
                  onPressed: _googleSignUp,
                  label: const Text('Google'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

