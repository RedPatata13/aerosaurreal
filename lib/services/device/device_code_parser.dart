import 'dart:convert';

class DeviceCodeParser {
  static String normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Device code is required.');
    }

    final parsed = _extractCandidate(trimmed);
    final normalized = parsed.trim().toUpperCase();

    if (normalized.isEmpty) {
      throw const FormatException('Device code is required.');
    }

    final compact = normalized.replaceAll(RegExp(r'\s+'), '');
    final allowed = RegExp(r'^[A-Z0-9_-]+$');
    if (!allowed.hasMatch(compact)) {
      throw const FormatException('Invalid device code format.');
    }

    return compact;
  }

  static String _extractCandidate(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri != null) {
      final fromQuery =
          uri.queryParameters['deviceId'] ??
          uri.queryParameters['code'] ??
          uri.queryParameters['id'];
      if (fromQuery != null && fromQuery.trim().isNotEmpty) {
        return fromQuery;
      }
    }

    if ((raw.startsWith('{') && raw.endsWith('}')) ||
        (raw.startsWith('[') && raw.endsWith(']'))) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final key in const ['deviceId', 'code', 'id']) {
            final value = decoded[key];
            if (value is String && value.trim().isNotEmpty) {
              return value;
            }
          }
        }
      } catch (_) {}
    }

    return raw;
  }
}
