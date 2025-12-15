import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';

const List<String> scopes = <String>[
  // 'https://www.googleapis.com/auth/contacts.readonly',
  'email',
  'profile',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile',
];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isAuthorized = false;
  bool _initialized = false;
  late GoogleSignInAccount? _currentUser;

  //forgot pass
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    print('Pressed');
    if (email.isEmpty) {
      _showSnackbar('Please enter your email address first.', Colors.orange);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnackbar('Password reset link sent to $email.', Colors.green);
      print('Password reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      String message = 'Failed to send reset email. Please try again.';
      if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid.';
      }
      _showSnackbar(message, Colors.red);
      print('Forgot password failed: ${e.code}');
    } catch (e) {
      _showSnackbar('An unexpected error occurred.', Colors.red);
      print('Forgot password failed: $e');
    }
  }

  //ui helpers
  void _showSnackbar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
      print('mounted');
    } else {
      print('not mounted');
    }
  }

  //ui
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return (Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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

                // LOGIN HEADER
                Text(
                  'LOGIN',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 25),

                // Email field
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

                // Password field
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                        Theme(
                          data: Theme.of(context).copyWith(
                            checkboxTheme: CheckboxThemeData(
                              fillColor:
                                  MaterialStateProperty.resolveWith<Color>((
                                    Set<MaterialState> states,
                                  ) {
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return Theme.of(
                                        context,
                                      ).colorScheme.primary;
                                    }
                                    return Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Color(0xFF414141)
                                        : Color(0xFFD9D9D9);
                                  }),
                              side: MaterialStateBorderSide.resolveWith(
                                (Set<MaterialState> states) => BorderSide.none,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                          ),
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

                //create account / login
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

                // gugel
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
                      _handleSignIn();
                    },
                    label: const Text('Google'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  //auth logic
  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('Login successful');
      _navigateToApp();
    } catch (e) {
      _showSnackbar(
        'Invalid credentials. Please check email and password again',
        Colors.red,
      );
      print('Login failed: $e');
    }
  }

  void _navigateToApp() {
    Navigator.of(context).pushNamed('/app');
  }

  //google sign in
  Future<void> _handleSignIn() async {
    try {
      final GoogleSignIn signin = GoogleSignIn.instance;
      await signin
          .initialize(
            clientId: dotenv.env['CLIENT_ID'],
            serverClientId: dotenv.env['SERVER_CLIENT_ID'],
          )
          .then((_) {
            signin.authenticationEvents
                .listen(_handleAuthenticationEvent)
                .onError(_handleAuthenticationError);
            print('Attemping to sign in...');
            _showSnackbar('Attempting to Sign in to Google...', Colors.orange);
            signin.attemptLightweightAuthentication();
          });
      await signin.signOut();
      await signin.disconnect();
      setState(() {
        _initialized = true;
      });

      print('End of block in Google Sign In');
    } catch (e) {
      print('Error while logging on to Google: $e');
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

        _navigateToApp();
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
      if (e is GoogleSignInException) {
        _showSnackbar('Google Sign In failed', Colors.red);
      }
    });
  }
}
