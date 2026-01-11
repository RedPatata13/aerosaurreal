import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';

class GoogleAuthService {
  bool isAuthorized = false;
  bool initialized = false;
  GoogleSignInAccount? currentUser;
  final GoogleSignIn signin =
      GoogleSignIn.instance; // Use the singleton instance

  // Handle the Google Sign-In process
  Future<void> handleSignIn({
    required void Function(UserCredential credential) onSuccess,
    required void Function(Object error) onError,
  }) async {
    try {
      // Step 1: Initialize Google Sign-In with client ID and server client ID
      await signin.initialize(
        clientId: dotenv.env['CLIENT_ID'],
        serverClientId: dotenv.env['SERVER_CLIENT_ID'],
      );

      // Step 2: Listen for authentication events (success or error)
      signin.authenticationEvents.listen((event) {
        _handleAuthenticationEvent(event, onSuccess);
      }, onError: onError);

      print('Attempting to sign in...');

      // Step 3: Attempt lightweight authentication
      await signin.attemptLightweightAuthentication();
    } catch (e) {
      print('Error during Google Sign-In: $e');
      onError(e); // Call the error callback in case of any issues
    }
  }

  // Handle the authentication event when the user successfully signs in
  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
    void Function(UserCredential credential) onSuccess,
  ) async {
    final GoogleSignInAccount? user =
        event is GoogleSignInAuthenticationEventSignIn ? event.user : null;

    final GoogleSignInAuthentication? auth = await user?.authentication;
    currentUser = user;
    isAuthorized = auth != null;

    if (user != null && auth != null) {
      // Step 4: Create Firebase credentials using the Google sign-in tokens
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

      // Step 5: Sign in to Firebase with the new credentials
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      onSuccess(
        userCredential,
      ); // Pass the userCredential to the success callback
    }
  }

  // Function to handle linking a new Google account
  Future<void> linkOrReplaceGoogleAccount() async {
    final firebaseAuth = FirebaseAuth.instance;
    final user = firebaseAuth.currentUser;
    if (user == null) return;

    final hasGoogle = user.providerData.any(
      (p) => p.providerId == 'google.com',
    );

    // Remove old Google binding if exists
    if (hasGoogle) {
      await user.unlink('google.com');
    }

    // Clear cached Google session
    await signin.signOut();

    // Force interactive sign-in
    await signin.authenticate();

    final event = await signin.authenticationEvents.firstWhere(
      (e) => e is GoogleSignInAuthenticationEventSignIn,
    );

    final googleUser = (event as GoogleSignInAuthenticationEventSignIn).user;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await user.linkWithCredential(credential);
  }
}
