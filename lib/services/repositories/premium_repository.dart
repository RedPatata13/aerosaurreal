import 'dart:convert';

import '../api/api_client.dart';
import '../api/api_exceptions.dart';
import '../api/endpoints.dart';

class PremiumRepository {
  PremiumRepository(this._api);

  final ApiClient _api;

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
      if (paymayaBody['isPremium'] == true) {
        return {...paymayaBody, 'provider': 'paymaya'};
      }
    } else {
      throw ApiException(paymayaRes.statusCode, _errorBody(paymayaRes.body));
    }

    final paypalRes = await _api.get(
      Endpoints.billingSubscriptionStatus(userId),
    );

    if (paypalRes.statusCode == 404) {
      return {...paymayaBody, 'provider': 'paymaya'};
    }

    final paypalBody = _decodeBody(paypalRes.body);

    if (paypalRes.statusCode >= 200 && paypalRes.statusCode < 300) {
      final status = (paypalBody['status'] ?? '').toString().toUpperCase();
      return {
        'isPremium': status == 'ACTIVE',
        'premiumPlan': paypalBody['planId'],
        'expiresAt': paypalBody['nextBillingTime'],
        'provider': 'paypal',
        'status': status,
      };
    }

    throw ApiException(paypalRes.statusCode, _errorBody(paypalRes.body));
  }

  Future<Map<String, dynamic>> createPaymayaCheckout({
    required String userId,
    required Map<String, dynamic> buyer,
  }) async {
    final res = await _api.post(
      Endpoints.paymayaCheckout,
      body: {'userId': userId, 'planId': 'PREMIUM_QUARTERLY', 'buyer': buyer},
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
}
