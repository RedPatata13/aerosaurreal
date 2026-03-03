import '../api/api_client.dart';
import '../api/endpoints.dart';

class ControlApi {
  final ApiClient _api;
  ControlApi(this._api);

  Future<Map<String, dynamic>> getControl(String deviceId) async {
    return _api.getJson(Endpoints.control(deviceId));
  }

  Future<Map<String, dynamic>> updateControl(
    String deviceId, {
    required Map<String, dynamic> patch,
  }) async {
    return _api.putJson(Endpoints.control(deviceId), body: patch);
  }
}
