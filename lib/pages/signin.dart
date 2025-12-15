import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/signup.dart';
import '../components/input_field.dart';
import '../components/password_input_field.dart';
import '../components/rounded_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
  bool _isAuthorized = false;
  bool _initialized = false;
  late GoogleSignInAccount? _currentUser;
  bool _isLoading = false;
  final List<String> scopes = <String>[
    // 'https://www.googleapis.com/auth/contacts.readonly',
    'email',
    'profile',
    'openid',
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Helper method to show messages to the user
  void _showSnackbar(String message, Color color) {
    // CRITICAL: Check mounted state before using context
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // The main sign up logic, relying on exceptions for errors
  void _signUp() async {
    // 1. Validate Form Fields
    if (!_formKey.currentState!.validate()) {
      _showSnackbar("Please correct the errors in the form.", Colors.orange);
      return;
    }

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 2. Validate Password Match
    if (password != confirmPassword) {
      _showSnackbar("Passwords do not match.", Colors.orange);
      return;
    }

    // 3. Start Loading State
    setState(() {
      _isLoading = true;
    });

    try {
      // 4. Call the Sign Up Service (relies on throwing exceptions on failure)
      await signUpUser(email: email, password: password, username: username);

      // Check mounted state after the await, before using Navigator
      if (!mounted) return;

      // Success: Show message and navigate
      _showSnackbar(
        "Sign up successful! Redirecting to Login Page...",
        Colors.green,
      );
      // Navigate to the main application route
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      // 5. Handle specific Firebase Authentication errors
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
      // 6. Handle other general errors
      // Check mounted state before showing Snackbar
      if (!mounted) return;
      _showSnackbar(
        "An unexpected error occurred during sign up: ${e.toString()}",
        Colors.red,
      );
    } finally {
      // 7. Stop Loading State
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    _showSnackbar('Initializing Google Sign In. Please wait...', Colors.green);
    try {
      final GoogleSignIn signin = GoogleSignIn.instance;
      await signin
          .initialize(
            clientId:
                '315539143951-o953euhck7eiqhm9775f7mg0pm0omlr8.apps.googleusercontent.com',
            serverClientId:
                '315539143951-l6l6nq15fm45qbdq22hqce0pv4rfu55i.apps.googleusercontent.com',
          )
          .then((_) {
            signin.authenticationEvents
                .listen(_handleAuthenticationEvent)
                .onError(_handleAuthenticationError);

            signin.attemptLightweightAuthentication();
          });
      // await signin.signOut();
      // await signin.disconnect();
      setState(() {
        _initialized = true;
      });

      // final GoogleSignInAccount? googleUser = await signin.signIn();
    } catch (e) {
      _showSnackbar('Error logging in using Google', Colors.red);
      print(e);
    }
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    final GoogleSignInClientAuthorization? authorization = await user
        ?.authorizationClient
        .authorizeScopes(scopes);

    setState(() {
      _currentUser = user;
      _isAuthorized = authorization != null;
      // _errorMessage = '';
    });
    if (user != null && authorization != null) {
      final GoogleSignInAuthentication googleAuth = user.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithCredential(credential);

        final String? uid = userCredential.user?.uid;
        final String? email = user.email;
        final String? displayName = user.displayName;

        if (uid != null) {
          final DocumentReference userDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(uid);

          final DocumentSnapshot doc = await userDocRef.get();

          if (!doc.exists) {
            await userDocRef.set({
              'uid': uid,
              'email': email,
              'displayName': displayName,
              'username': displayName,
              'createdAt': FieldValue.serverTimestamp(),
            });
            print('New user document created in Firestore for $uid');
          } else {
            print('User document already exists in Firestore for UID: $uid');
          }
        }

        _navigateToLogin();
      } catch (e) {
        print("Error signing in or writing to Firestore");
        print(e);
      }
    }
  }

  Future<void> _handleAuthenticationError(Object e) async {
    setState(() {
      _currentUser = null;
      _isAuthorized = false;
      // _errorMessage =
      //     e is GoogleSignInException
      //         ? _errorMessageFromSignInException(e)
      //         : 'Unknown error: $e';
    });
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

              // Title
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

                      // validator: (value) => value == null || value.isEmpty ? 'Username is required' : null,
                    ),
                    const SizedBox(height: 20),

                    InputField(
                      label: "Email",
                      hintText: "Enter your Email",
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      // validator: (value) {
                      //   if (value == null || value.isEmpty) return 'Email is required';
                      //   if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Enter a valid email';
                      //   return null;
                      // },
                    ),
                    const SizedBox(height: 20),

                    PasswordInputField(
                      label: "Password",
                      hintText: "Enter your Password",
                      controller: _passwordController,
                      // validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 20),

                    PasswordInputField(
                      label: "Confirm Password",
                      hintText: "Confirm your Password",
                      controller: _confirmPasswordController,
                      // validator: (value) => value == null || value.isEmpty ? 'Confirmation is required' : null,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Login text link
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/login');
                    },
                    child: Text(
                      "Login Account",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                  // Right: Sign Up button
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
                  onPressed: () {
                    _handleGoogleSignIn();
                  },
                  label: const Text('Google'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToLogin() {
    _showSnackbar('Success! Redirecting to Login...', Colors.green);
    Navigator.of(context).pushNamed('/login');
  }
}
