import 'api_client.dart';

class AnalyticsApi {
  final ApiClient _api;

  AnalyticsApi(this._api);

  Future<Map<String, dynamic>> getAnalytics7d(String deviceId) async {
    return _api.getJson('/devices/$deviceId/analytics/7d');
  }

  Future<Map<String, dynamic>> getAnalyticsToday(String deviceId) async {
    return _api.getJson('/devices/$deviceId/analytics/today');
  }
}
