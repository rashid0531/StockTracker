import '../entities/investment_profile.dart';
import '../entities/stock_holding.dart';
import '../entities/transaction_record.dart';

abstract class StocksRepository {
  Future<List<InvestmentProfile>> getProfiles();
  Future<List<ChartPoint>> getChartPoints({String profileId = 'ALL', String interval = '1Y', bool isDividend = false});
  Future<List<Map<String, dynamic>>> getDividendCalendarEvents();
  Future<List<TransactionRecord>> getTransactions();
  Future<bool> executeBuySellTransaction({
    required String profileId,
    required String ticker,
    required String type,
    required double shares,
    required double price,
    required String currency,
    String? date,
  });
}
