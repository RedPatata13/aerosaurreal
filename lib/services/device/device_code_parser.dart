import 'dart:convert';

class DeviceCodeParser {
  static String normalize(String raw) {
    final candidates = extractCandidates(raw);
    if (candidates.isEmpty) {
      throw const FormatException('Device code is required.');
    }

    String? fallback;
    for (final candidate in candidates) {
      final compact = _compact(candidate);
      if (compact == null) {
        continue;
      }
      fallback ??= compact;
      if (_looksLikeDeviceCode(compact)) {
        return compact;
      }
    }

    if (fallback != null) {
      return fallback;
    }

    throw const FormatException('Invalid device code format.');
  }

  static List<String> extractCandidates(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final candidates = <String>[];

    void addCandidate(String? value) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        candidates.add(normalized);
      }
    }

    addCandidate(trimmed);

    final uri = Uri.tryParse(raw);
    if (uri != null) {
      final fromQuery =
          uri.queryParameters['deviceId'] ??
          uri.queryParameters['code'] ??
          uri.queryParameters['id'];
      addCandidate(fromQuery);

      final segments = uri.pathSegments
          .where((e) => e.trim().isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        addCandidate(segments.last);
      }
    }

    if ((raw.startsWith('{') && raw.endsWith('}')) ||
        (raw.startsWith('[') && raw.endsWith(']'))) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final key in const ['deviceId', 'code', 'id']) {
            final value = decoded[key];
            if (value is String) {
              addCandidate(value);
            }
          }
        }
      } catch (_) {}
    }

    final labeledMatch = RegExp(
      r'(?:device\s*(?:id|code)?|code|id)\s*[:#-]?\s*([A-Za-z0-9_-]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (labeledMatch != null) {
      addCandidate(labeledMatch.group(1));
    }

    for (final match in RegExp(r'\b[A-Za-z0-9_-]{4,24}\b').allMatches(raw)) {
      final token = match.group(0);
      if (token != null &&
          RegExp(r'^(?=.*\d)[A-Za-z0-9_-]+$').hasMatch(token)) {
        addCandidate(token);
      }
    }

    return candidates.toSet().toList(growable: false);
  }

  static String? _compact(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }

    final compact = normalized.replaceAll(RegExp(r'\s+'), '');
    final allowed = RegExp(r'^[A-Z0-9_-]+$');
    if (!allowed.hasMatch(compact)) {
      return null;
    }

    return compact;
  }

  static bool _looksLikeDeviceCode(String candidate) {
    if (candidate.length < 4 || candidate.length > 24) {
      return false;
    }

    return RegExp(r'^(?=.*\d)[A-Z0-9_-]+$').hasMatch(candidate);
  }
}
