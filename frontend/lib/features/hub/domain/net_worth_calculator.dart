import '../../../data/models/real_estate.dart';
import '../../../data/models/precious_metal.dart';
import '../../../data/models/health_metric.dart';

class NetWorthSummary {
  final double stocksValuationCAD;
  final double realEstateEquityCAD;
  final double preciousMetalsValuationCAD;
  final double totalNetWorthCAD;
  final int healthScore;

  const NetWorthSummary({
    required this.stocksValuationCAD,
    required this.realEstateEquityCAD,
    required this.preciousMetalsValuationCAD,
    required this.totalNetWorthCAD,
    required this.healthScore,
  });
}

class NetWorthCalculator {
  static NetWorthSummary calculate({
    required double stocksValuationCAD,
    required List<RealEstateAsset> realEstateProperties,
    required List<PreciousMetalAsset> preciousMetals,
    required List<HealthMetricLog> healthMetrics,
  }) {
    final double reEquity = realEstateProperties.fold(0.0, (sum, p) => sum + p.netEquity);
    final double pmValue = preciousMetals.fold(0.0, (sum, m) => sum + m.totalCurrentValue);
    final double totalNetWorth = stocksValuationCAD + reEquity + pmValue;

    // Health Score Weighting (Default 92 if metrics present)
    int score = 92;
    if (healthMetrics.isNotEmpty) {
      final sleepScore = healthMetrics.firstWhere((m) => m.metricType.toLowerCase().contains("sleep"), orElse: () => HealthMetricLog(id: '', userId: '', metricType: '', value: 88, unit: '', loggedAt: '')).value;
      score = sleepScore.toInt().clamp(60, 100);
    }

    return NetWorthSummary(
      stocksValuationCAD: stocksValuationCAD,
      realEstateEquityCAD: reEquity,
      preciousMetalsValuationCAD: pmValue,
      totalNetWorthCAD: totalNetWorth,
      healthScore: score,
    );
  }
}
