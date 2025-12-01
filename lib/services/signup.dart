import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> signUpUser({
  required String email,
  required String password,
  required String username,
}) async {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // Step 1: Create the user
  final userCred = await auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  final user = userCred.user!;

  // Step 2: Update displayName (optional)
  await user.updateDisplayName(username);

  // Step 3: Create user document in Firestore
  await firestore.collection('users').doc(user.uid).set({
    'username': username,
    'email': email,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Step 4: Send verification email
  await user.sendEmailVerification();

  // Optional: sign out or show a message
  // to prevent unverified users from proceeding immediately
  await auth.signOut();
}
