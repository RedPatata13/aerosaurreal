class Endpoints {
  static const usersMe = '/users/me';
  static const usersProfile = '/users/profile';
  static const notifications = '/notifications';
  static const notificationSettings = '/notifications/settings';
  static const notificationMarkAllRead = '/notifications/mark-all-read';
  static const notificationClearAll = '/notifications/clear-all';
  static const billingSubscription = '/billing/subscription';
  static const paymayaCheckout = '/paymaya/checkout';
  static String paymayaPremium(String userId) => '/paymaya/premium/$userId';
  static String paymayaStatus(String paymentId, String userId) =>
      '/paymaya/status/$paymentId?userId=$userId';
  static String paymayaCancelPremium(String userId) => '/paymaya/premium/$userId';
  static String billingSubscriptionStatus(String userId) =>
      '/billing/subscription/$userId';
  static String notificationMarkRead(String notificationId) =>
      '/notifications/$notificationId/read';
  static String control(String deviceId) => '/devices/$deviceId/control';
  static String latestReading(String deviceId) =>
      '/devices/$deviceId/readings/latest';
  static String readings(String deviceId) => '/devices/$deviceId/readings';
}
