class HealthMetricLog {
  final String id;
  final String userId;
  final String metricType; // Weight, Body Fat %, Resting HR, Sleep Score, Activity
  final double value;
  final String unit; // kg, lbs, bpm, %, hours, score
  final String? notes;
  final String loggedAt;

  HealthMetricLog({
    required this.id,
    required this.userId,
    required this.metricType,
    required this.value,
    required this.unit,
    this.notes,
    required this.loggedAt,
  });

  String get formattedValue => "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} $unit";

  factory HealthMetricLog.fromJson(Map<String, dynamic> json) {
    return HealthMetricLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      metricType: json['metric_type'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      notes: json['notes'] as String?,
      loggedAt: json['logged_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'metric_type': metricType,
      'value': value,
      'unit': unit,
      'notes': notes,
      'logged_at': loggedAt,
    };
  }
}
