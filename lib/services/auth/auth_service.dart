import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  //login
  Future<User> login({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!;
  }

  //signup
  Future<User> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCred.user!;
    await user.updateDisplayName(username);
    await user.sendEmailVerification();

    return user;
  }

  //pass reset
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  //sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  //current user
  User? get currentUser => _auth.currentUser;
}
