import 'package:firebase_auth/firebase_auth.dart';

class TokenUtils {
  static Future<String> getIdToken({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated Firebase user');
    }

    final String? token = await user.getIdToken(forceRefresh);

    if (token == null || token.isEmpty) {
      throw Exception('Failed to obtain Firebase ID token');
    }

    return token;
  }
}
