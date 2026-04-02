import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<GoogleSignInAccount> _authenticateGoogleAccount() async {
    await _googleSignIn.initialize();

    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }

    return googleUser;
  }

  Future<AuthCredential> getGoogleCredential() async {
    final googleUser = await _authenticateGoogleAccount();
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Missing Google idToken');
    }

    return GoogleAuthProvider.credential(idToken: idToken);
  }

  Future<UserCredential> signInWithGoogle() async {
    final credential = await getGoogleCredential();

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  Future<void> disconnectGoogle() async {
    await _googleSignIn.disconnect();
  }
}
