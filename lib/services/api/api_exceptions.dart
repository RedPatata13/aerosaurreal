class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final Map<String, dynamic> body;

  String get message {
    final m = body['message'];
    if (m is String && m.isNotEmpty) return m;
    return 'Request failed ($statusCode)';
  }

  @override
  String toString() => 'ApiException($statusCode): $body';
}
