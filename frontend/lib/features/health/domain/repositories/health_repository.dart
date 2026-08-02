import '../../../../data/models/health_metric.dart';

abstract class HealthRepository {
  Future<List<HealthMetricLog>> getHealthMetrics();
  Future<HealthMetricLog> addHealthMetric(Map<String, dynamic> body);
}
