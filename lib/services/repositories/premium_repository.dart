import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/endpoints.dart';

class PremiumRepository {
  PremiumRepository(this._api);

  final ApiClient _api;

  bool _paymayaStatusAllowsPremium(String status, String expiresAt) {
    if (status == 'ACTIVE') return true;
    if (status != 'CANCELLED' || expiresAt.isEmpty) return false;

    try {
      return DateTime.now().isBefore(DateTime.parse(expiresAt).toLocal());
    } catch (_) {
      return false;
    }
  }

  bool _paypalStatusAllowsPremium(String status, String expiresAt) {
    if (status == 'ACTIVE') return true;
    if (status != 'CANCELLED' || expiresAt.isEmpty) return false;

    try {
      return DateTime.now().isBefore(DateTime.parse(expiresAt).toLocal());
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decodeBody(String raw) {
    if (raw.trim().isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;

    return <String, dynamic>{'message': 'Invalid JSON response'};
  }

  Map<String, dynamic> _errorBody(String raw) {
    try {
      return _decodeBody(raw);
    } catch (_) {
      return <String, dynamic>{'message': raw.isEmpty ? 'Request failed' : raw};
    }
  }

  Future<Map<String, dynamic>> getPremiumStatus(String userId) async {
    final paymayaRes = await _api.get(Endpoints.paymayaPremium(userId));
    final paymayaBody = _decodeBody(paymayaRes.body);

    if (paymayaRes.statusCode >= 200 && paymayaRes.statusCode < 300) {
      final paymayaStatus = (paymayaBody['status'] ?? '').toString().toUpperCase();
      final paymayaExpiresAt = (paymayaBody['expiresAt'] ?? '').toString();
      if (paymayaBody['isPremium'] == true ||
          _paymayaStatusAllowsPremium(paymayaStatus, paymayaExpiresAt)) {
        return {...paymayaBody, 'provider': 'paymaya'};
      }
    } else {
      throw ApiException(paymayaRes.statusCode, _errorBody(paymayaRes.body));
    }

    final paypalRes = await _api.get(
      Endpoints.billingSubscriptionStatus(userId),
    );

    if (paypalRes.statusCode == 404 || paypalRes.statusCode >= 500) {
      return {...paymayaBody, 'provider': 'paymaya'};
    }

    final paypalBody = _decodeBody(paypalRes.body);

    if (paypalRes.statusCode >= 200 && paypalRes.statusCode < 300) {
      final status = (paypalBody['status'] ?? '').toString().toUpperCase();
      final expiresAt = (paypalBody['nextBillingTime'] ?? '').toString();
      return {
        'isPremium': _paypalStatusAllowsPremium(status, expiresAt),
        'premiumPlan': paypalBody['planId'],
        'expiresAt': expiresAt,
        'provider': 'paypal',
        'status': status,
      };
    }

    throw ApiException(paypalRes.statusCode, _errorBody(paypalRes.body));
  }

  Future<Map<String, dynamic>> createPaymayaCheckout({
    required String userId,
    required Map<String, dynamic> buyer,
    Map<String, dynamic>? redirectUrls,
  }) async {
    final res = await _api.post(
      Endpoints.paymayaCheckout,
      body: {
        'userId': userId,
        'buyer': buyer,
        if (redirectUrls != null) 'redirectUrls': redirectUrls,
      },
    );

    final body = _decodeBody(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw ApiException(res.statusCode, _errorBody(res.body));
  }

  Future<Map<String, dynamic>> createPaypalSubscription({
    required String userId,
    required String planId,
  }) async {
    final res = await _api.post(
      Endpoints.billingSubscription,
      body: {'userId': userId, 'planId': planId},
    );

    final body = _decodeBody(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw ApiException(res.statusCode, _errorBody(res.body));
  }

  Future<Map<String, dynamic>> getPaymayaPaymentStatus({
    required String paymentId,
    required String userId,
  }) async {
    final res = await _api.get(Endpoints.paymayaStatus(paymentId, userId));
    final body = _decodeBody(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw ApiException(res.statusCode, _errorBody(res.body));
  }

  Future<Map<String, dynamic>> cancelSubscription(String userId) async {
    final res = await _api.delete(Endpoints.billingSubscriptionStatus(userId));
    final body = _decodeBody(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw ApiException(res.statusCode, _errorBody(res.body));
  }

  Future<Map<String, dynamic>> cancelPaymayaPremium(String userId) async {
    final res = await _api.delete(Endpoints.paymayaCancelPremium(userId));
    final body = _decodeBody(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw ApiException(res.statusCode, _errorBody(res.body));
  }
}
