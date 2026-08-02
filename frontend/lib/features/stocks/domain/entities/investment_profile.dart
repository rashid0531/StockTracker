import 'stock_holding.dart';

class InvestmentProfile {
  final String id;
  final String name;
  final String type;
  final String country;
  final String currency;
  final double totalValue;
  final double totalChange;
  final double totalChangePercent;
  final List<StockHolding> stocks;

  const InvestmentProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.country,
    required this.currency,
    required this.totalValue,
    required this.totalChange,
    required this.totalChangePercent,
    required this.stocks,
  });

  factory InvestmentProfile.fromJson(Map<String, dynamic> json) {
    var rawStocks = json['stocks'] as List? ?? [];
    List<StockHolding> stockList = rawStocks.map((s) => StockHolding.fromJson(s)).toList();

    return InvestmentProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      country: json['country'] as String,
      currency: json['currency'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      totalChange: (json['totalChange'] as num).toDouble(),
      totalChangePercent: (json['totalChangePercent'] as num).toDouble(),
      stocks: stockList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'country': country,
      'currency': currency,
      'totalValue': totalValue,
      'totalChange': totalChange,
      'totalChangePercent': totalChangePercent,
      'stocks': stocks.map((s) => s.toJson()).toList(),
    };
  }
}
