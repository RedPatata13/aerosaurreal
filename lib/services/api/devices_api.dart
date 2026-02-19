import 'api_client.dart';

class DevicesApi {
  final ApiClient _api;

  DevicesApi(this._api);

  Future<List<Map<String, dynamic>>> listDevices() async {
    final res = await _api.getJson('/devices');
    final raw = res['items'] ?? res['devices'] ?? res['data'] ?? [];

    if (raw is! List) return const [];

    return raw
        .cast<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    String? name,
  }) async {
    final res = await _api.postJson(
      '/devices/register',
      body: {
        'deviceId': deviceId,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      },
    );

    final device = res['device'];
    if (device is Map) {
      return device.cast<String, dynamic>();
    }

    throw Exception('Unexpected register response shape: $res');
  }

  Future<void> unregisterDevice(String deviceId) async {
    await _api.deleteJson('/devices/$deviceId');
  }
}
