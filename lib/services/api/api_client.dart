import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _http;

  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  Uri _uri(String path) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (auth) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');
      final token = await user.getIdToken();
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Map<String, dynamic> _decodeJsonBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(trimmed);

    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('body')) {
        final inner = decoded['body'];
        if (inner is String) {
          return jsonDecode(inner);
        }
        if (inner is Map<String, dynamic>) {
          return inner;
        }
      }
      return decoded;
    }

    throw Exception('Unexpected JSON response type: ${decoded.runtimeType}');
  }

  Future<http.Response> get(String path, {bool auth = true}) async {
    return _http.get(_uri(path), headers: await _headers(auth: auth));
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _http.post(
      _uri(path),
      headers: await _headers(auth: auth),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _http.put(
      _uri(path),
      headers: await _headers(auth: auth),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
  }

  Future<http.Response> delete(String path, {bool auth = true}) async {
    return _http.delete(_uri(path), headers: await _headers(auth: auth));
  }

  Future<Map<String, dynamic>> getJson(String path, {bool auth = true}) async {
    debugPrint('➡️ GET ${_uri(path)}');

    final res = await get(path, auth: auth);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed: ${res.statusCode} ${res.body}');
    }

    return _decodeJsonBody(res.body);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    bool auth = true,
  }) async {
    final res = await post(path, body: body, auth: auth);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed: ${res.statusCode} ${res.body}');
    }

    return _decodeJsonBody(res.body);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    bool auth = true,
  }) async {
    final res = await put(path, body: body, auth: auth);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed: ${res.statusCode} ${res.body}');
    }

    return _decodeJsonBody(res.body);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    bool auth = true,
  }) async {
    final res = await delete(path, auth: auth);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Request failed: ${res.statusCode} ${res.body}');
    }

    return _decodeJsonBody(res.body);
  }
}
