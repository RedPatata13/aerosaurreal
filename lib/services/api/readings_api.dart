import 'api_client.dart';

class ReadingsApi {
  final ApiClient _api;
  ReadingsApi(this._api);

  Future<Map<String, dynamic>> getLatest(String deviceId) async {
    return _api.getJson('/devices/$deviceId/readings/latest');
  }
}
