import 'dart:convert';

class DeviceCodeParser {
  static const int deviceCodeLength = 6;

  static String normalize(String raw) {
    final candidates = extractCandidates(raw);
    if (candidates.isEmpty) {
      throw const FormatException('Device code is required.');
    }

    for (final candidate in candidates) {
      final compact = _compact(candidate);
      if (compact != null && _looksLikeDeviceCode(compact)) {
        return compact;
      }
    }

    throw const FormatException('Device code must be 6 letters or numbers.');
  }

  static String normalizeQrPayload(String raw) {
    final candidates = extractCandidates(raw);
    if (candidates.isEmpty) {
      throw const FormatException('No device code found in QR.');
    }

    for (final candidate in candidates) {
      final compact = _compact(candidate);
      if (compact != null && _looksLikeDeviceCode(compact)) {
        return compact;
      }
    }

    throw const FormatException(
      'QR code does not contain a valid 6-character device code.',
    );
  }

  static String extractRegistrationIdentifier(String raw) {
    final candidates = extractRegistrationCandidates(raw);
    if (candidates.isEmpty) {
      throw const FormatException('No device identifier found in QR.');
    }

    for (final candidate in candidates) {
      final trimmed = candidate.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    throw const FormatException('No device identifier found in QR.');
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

    final aerosaurMatch = RegExp(
      r'AEROSAUR[-_\s:]*([A-Za-z0-9]{6})',
      caseSensitive: false,
    ).firstMatch(raw);
    if (aerosaurMatch != null) {
      addCandidate(aerosaurMatch.group(1));
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

  static List<String> extractRegistrationCandidates(String raw) {
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

    final uri = Uri.tryParse(raw);
    if (uri != null) {
      addCandidate(
        uri.queryParameters['deviceId'] ??
            uri.queryParameters['device_id'] ??
            uri.queryParameters['registrationId'] ??
            uri.queryParameters['registration_id'] ??
            uri.queryParameters['id'] ??
            uri.queryParameters['code'],
      );

      final segments = uri.pathSegments
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);
      if (segments.isNotEmpty) {
        addCandidate(segments.last);
      }
    }

    if ((raw.startsWith('{') && raw.endsWith('}')) ||
        (raw.startsWith('[') && raw.endsWith(']'))) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final key in const [
            'deviceId',
            'device_id',
            'registrationId',
            'registration_id',
            'id',
            'code',
          ]) {
            final value = decoded[key];
            if (value is String) {
              addCandidate(value);
            }
          }
        }
      } catch (_) {}
    }

    final labeledMatch = RegExp(
      r'(?:device\s*(?:id|code)?|registration\s*(?:id|code)?|code|id)\s*[:#-]?\s*([A-Za-z0-9_-]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (labeledMatch != null) {
      addCandidate(labeledMatch.group(1));
    }

    addCandidate(trimmed);

    return candidates.toSet().toList(growable: false);
  }

  static String? _compact(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }

    final compact = normalized.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final allowed = RegExp(r'^[A-Z0-9]+$');
    if (!allowed.hasMatch(compact)) {
      return null;
    }

    return compact;
  }

  static bool _looksLikeDeviceCode(String candidate) {
    if (candidate.length != deviceCodeLength) {
      return false;
    }

    return RegExp(r'^(?=.*\d)[A-Z0-9]+$').hasMatch(candidate);
  }
}
