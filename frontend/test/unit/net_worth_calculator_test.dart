import 'package:flutter_test/flutter_test.dart';
import 'package:stocktracker_frontend_dart/data/models/real_estate.dart';
import 'package:stocktracker_frontend_dart/data/models/precious_metal.dart';
import 'package:stocktracker_frontend_dart/data/models/health_metric.dart';
import 'package:stocktracker_frontend_dart/features/hub/domain/net_worth_calculator.dart';

void main() {
  group('NetWorthCalculator Unit Tests', () {
    test('Calculates total net worth correctly across all 4 asset classes', () {
      final properties = [
        RealEstateAsset(
          id: 're-1',
          userId: 'user-1',
          propertyName: 'Condo',
          propertyType: 'Condo',
          purchasePrice: 500000,
          currentValue: 600000,
          mortgageBalance: 200000,
          monthlyRentIncome: 3000,
          monthlyExpenses: 1000,
        ),
      ];

      final metals = [
        PreciousMetalAsset(
          id: 'pm-1',
          userId: 'user-1',
          metalType: 'Gold',
          form: '1 oz Bar',
          weightOz: 10,
          purityPercent: 99.99,
          purchasePricePerOz: 2000,
          currentSpotPricePerOz: 2500,
          storageLocation: 'Vault',
        ),
      ];

      final healthLogs = [
        HealthMetricLog(
          id: 'hm-1',
          userId: 'user-1',
          metricType: 'Sleep Score',
          value: 95,
          unit: 'score',
          loggedAt: '2026-07-30',
        ),
      ];

      final summary = NetWorthCalculator.calculate(
        stocksValuationCAD: 100000.0,
        realEstateProperties: properties,
        preciousMetals: metals,
        healthMetrics: healthLogs,
      );

      // Real Estate Net Equity = 600k - 200k = 400k
      expect(summary.realEstateEquityCAD, equals(400000.0));

      // Metals Value = 10 oz * $2500/oz = 25,000
      expect(summary.preciousMetalsValuationCAD, equals(25000.0));

      // Total Net Worth = 100k + 400k + 25k = 525,000
      expect(summary.totalNetWorthCAD, equals(525000.0));

      // Health Score = 95
      expect(summary.healthScore, equals(95));
    });

    test('Real estate cap rate and cash flow calculations are accurate', () {
      final asset = RealEstateAsset(
        id: 're-2',
        userId: 'user-1',
        propertyName: 'Commercial Lot',
        propertyType: 'Commercial',
        purchasePrice: 1000000,
        currentValue: 1200000,
        mortgageBalance: 500000,
        monthlyRentIncome: 10000,
        monthlyExpenses: 4000,
      );

      expect(asset.monthlyCashFlow, equals(6000.0));
      expect(asset.netEquity, equals(700000.0));
      expect(asset.annualCapRate, closeTo(6.0, 0.1));
    });

    test('Precious metal gain/loss percentage is accurate', () {
      final metal = PreciousMetalAsset(
        id: 'pm-2',
        userId: 'user-1',
        metalType: 'Silver',
        form: 'Coin',
        weightOz: 100,
        purityPercent: 99.99,
        purchasePricePerOz: 20.0,
        currentSpotPricePerOz: 30.0,
        storageLocation: 'Home Safe',
      );

      expect(metal.totalPurchaseCost, equals(2000.0));
      expect(metal.totalCurrentValue, equals(3000.0));
      expect(metal.totalGainLoss, equals(1000.0));
      expect(metal.gainLossPercent, equals(50.0));
    });
  });
}
