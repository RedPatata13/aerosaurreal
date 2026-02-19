class Endpoints {
  static const usersMe = '/users/me';
  static const usersProfile = '/users/profile';
  static String control(String deviceId) => '/devices/$deviceId/control';
  static String latestReading(String deviceId) =>
      '/devices/$deviceId/readings/latest';
  static String readings(String deviceId) => '/devices/$deviceId/readings';
}
