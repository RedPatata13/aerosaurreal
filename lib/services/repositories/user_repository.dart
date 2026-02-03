import 'dart:convert';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../api/api_exceptions.dart';

class UserRepository {
  UserRepository(this._api);
  final ApiClient _api;

  Map<String, dynamic> _decodeBody(String raw) {
    if (raw.trim().isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;

    // backend *should* always return a JSON object
    return <String, dynamic>{'message': 'Invalid JSON response'};
  }

  Map<String, dynamic> _errorBody(String raw) {
    try {
      return _decodeBody(raw);
    } catch (_) {
      return <String, dynamic>{'message': raw.isEmpty ? 'Request failed' : raw};
    }
  }

  /// GET /users/me
  Future<Map<String, dynamic>> getMe() async {
    final res = await _api.get(Endpoints.usersMe);

    final body = _decodeBody(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw ApiException(res.statusCode, _errorBody(res.body));
  }

  /// POST /users/profile
  /// Backend handles create/update + auto-generate username if missing
  Future<Map<String, dynamic>> upsertProfile({String? username}) async {
    final payload = <String, dynamic>{};

    if (username != null && username.trim().isNotEmpty) {
      payload['username'] = username.trim();
    }

    final res = await _api.post(
      Endpoints.usersProfile,
      body: payload, // IMPORTANT: ApiClient uses `body:`, not `json:`
    );

    final bodyMap = _decodeBody(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return bodyMap;
    }

    throw ApiException(res.statusCode, _errorBody(res.body));
  }

  /// Convenience:
  /// - If profile exists → return GET /users/me response
  /// - If not → create profile via POST /users/profile (username optional)
  Future<Map<String, dynamic>> getOrCreateProfile({String? username}) async {
    try {
      return await getMe();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return await upsertProfile(username: username);
      }
      rethrow;
    }
  }
}
