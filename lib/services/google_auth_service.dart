import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const List<String> scopes = <String>[
  'email',
  'profile',
  'openid',
  'https://www.googleapis.com/auth/userinfo.email',
  'https://www.googleapis.com/auth/userinfo.profile',
];

class GoogleAuthService {
  bool isAuthorized = false;
  bool initialized = false;
  GoogleSignInAccount? currentUser;

  final GoogleSignIn signin = GoogleSignIn.instance;

  Future<void> handleSignIn({
    required void Function(UserCredential credential) onSuccess,
    required void Function(Object error) onError,
  }) async {
    try {
      await signin
          .initialize(
            clientId: dotenv.env['CLIENT_ID'],
            serverClientId: dotenv.env['SERVER_CLIENT_ID'],
          )
          .then((_) {
            signin.authenticationEvents
                .listen((event) {
                  _handleAuthenticationEvent(event, onSuccess);
                })
                .onError(onError);

            print('Attemping to sign in...');
            signin.attemptLightweightAuthentication();
          });

      await signin.signOut();
      await signin.disconnect();

      initialized = true;
      print('End of block in Google Sign In');
    } catch (e) {
      print('Error while logging on to Google: $e');
    }
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
    void Function(UserCredential credential) onSuccess,
  ) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    final GoogleSignInClientAuthorization? authorization = await user
        ?.authorizationClient
        .authorizeScopes(scopes);

    currentUser = user;
    isAuthorized = authorization != null;

    if (user != null && authorization != null) {
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authorization.accessToken,
        idToken: user.authentication.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      onSuccess(userCredential);
    }
  }
}
