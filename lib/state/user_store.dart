import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aerosaur/services/api/api_exceptions.dart';
import 'package:aerosaur/services/repositories/user_repository.dart';

class UserStore extends ChangeNotifier {
  UserStore(this._users);

  final UserRepository _users;

  Map<String, dynamic>? _profile;
  bool _loading = false;

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _loading;
  bool get hasProfile => _profile != null;

  String get username =>
      (_profile?['Username'] ?? _profile?['username'] ?? 'Unknown User')
          .toString();

  String _generateBaseUsername(User user) {
    final displayName = user.displayName?.trim();
    final emailPrefix = user.email?.split('@').first;

    final raw = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (emailPrefix != null && emailPrefix.isNotEmpty)
        ? emailPrefix
        : 'user';

    final normalized = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (normalized.isEmpty) return 'user';
    return normalized.length > 12 ? normalized.substring(0, 12) : normalized;
  }

  Future<void> loadOrCreate() async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      final me = await _users.getMe();
      _profile = (me['profile'] as Map?)?.cast<String, dynamic>() ?? me;
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw StateError('No Firebase user found while creating profile.');
        }

        final base = _generateBaseUsername(user);
        final suffix = user.uid.substring(0, 5);
        final generatedUsername = '$base$suffix';

        final created = await _users.upsertProfile(username: generatedUsername);
        _profile =
            (created['profile'] as Map?)?.cast<String, dynamic>() ?? created;
      } else {
        rethrow;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateUsername(String newUsername) async {
    if (_loading) return;
    _loading = true;
    notifyListeners();

    try {
      final updated = await _users.upsertProfile(username: newUsername);
      _profile =
          (updated['profile'] as Map?)?.cast<String, dynamic>() ?? updated;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}

