import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<UserCredential> signInWithGoogle() async {
    await _googleSignIn.initialize();

    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Missing Google idToken');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  Future<void> disconnectGoogle() async {
    await _googleSignIn.disconnect();
  }
}
