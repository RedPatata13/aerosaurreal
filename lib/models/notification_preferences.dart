class NotificationPreferences {
  final bool enabled;
  final bool alerts;
  final bool smartMode;
  final bool energy;

  const NotificationPreferences({
    required this.enabled,
    required this.alerts,
    required this.smartMode,
    required this.energy,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      enabled: json['enabled'] != false,
      alerts: json['alerts'] == true,
      smartMode: json['smartMode'] != false,
      energy: json['energy'] == true,
    );
  }

  NotificationPreferences copyWith({
    bool? enabled,
    bool? alerts,
    bool? smartMode,
    bool? energy,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      alerts: alerts ?? this.alerts,
      smartMode: smartMode ?? this.smartMode,
      energy: energy ?? this.energy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'alerts': alerts,
      'smartMode': smartMode,
      'energy': energy,
    };
  }
}
