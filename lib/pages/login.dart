import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const List<String> scopes = <String>[
  // 'https://www.googleapis.com/auth/contacts.readonly',
  'email',
  'profile',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile'  
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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return (
      Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar / Logo
                  // const RoundedImage(),
                  const SizedBox(height: 20),

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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
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
                    child: Text(
                      'Enter Email',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Password field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Enter Password',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      filled: true,
                      fillColor: Colors.grey[200],
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
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v ?? false),
                          ),
                          const Text('Remember Me'),
                        ],
                      ),
                      TextButton(
                        onPressed: () { _forgotPassword(); },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Login button
                  SizedBox(
                    width: 100,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Sign-up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          // print('tapped');
                          Navigator.of(context).pushReplacementNamed('/signup');
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  
                  Row(
                    children: const [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Or login with'),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // gugel
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: Image.asset(
                        'images/google_logo.png',
                        height: 20,
                      ),
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
      )
    );
  }

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('Login successful');
      _navigateToApp();
    } catch (e) {
      _showSnackbar('Invalid credentials. Please check email and password again', Colors.red);
      print('Login failed: $e');
    }
  }
  void _navigateToApp(){
      Navigator.of(context).pushNamed('/app');
  }
  Future<void> _handleSignIn() async {
    try{
      final GoogleSignIn signin = GoogleSignIn.instance;
      await signin.initialize(
        clientId: dotenv.env['CLIENT_ID'],
        serverClientId: dotenv.env['SERVER_CLIENT_ID']
      ).then((_,
      ){
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
      


      // signIn.auth
      print('End of block in Google Sign In');
    } catch (e){
      print('Error while logging on to Google: $e');
    }
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    final GoogleSignInAccount? user =
    switch(event){
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
    if(user != null && authorization != null){
      final GoogleSignInAuthentication googleAuth = user.authentication;
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,  
        idToken: googleAuth.idToken,
      );
    
      try{
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

        final String? uid = userCredential.user?.uid;
        final String? email = user.email;
        final String? displayName = user.displayName;

        if(uid != null){
          final DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);

          final DocumentSnapshot doc = await userDocRef.get();

          if(!doc.exists){
            await userDocRef.set({
              'uid': uid,
              'email': email,
              'displayName' : displayName,
              'username' : displayName,
              'createdAt' : FieldValue.serverTimestamp(),
            });
            print('New user document created in Firestore for $uid');
          } else {
            print('User document already exists in Firestore for UID: $uid');
          }
        }

        _navigateToApp();

      } catch (e){
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
      if(e is GoogleSignInException){
        _showSnackbar('Google Sign In failed', Colors.red);
      }
    });
  }

  
}

