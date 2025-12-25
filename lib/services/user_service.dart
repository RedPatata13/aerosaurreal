import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserIfNotExists({
    required String uid,
    required String email,
    required String? displayName,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);
    final doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'username': displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
