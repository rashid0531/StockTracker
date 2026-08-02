class StockHolding {
  final String stockId;
  final String ticker;
  final String name;
  final double shares;
  final double price;
  final double change;
  final double changePercent;
  final String currency;
  final double value;

  const StockHolding({
    required this.stockId,
    required this.ticker,
    required this.name,
    required this.shares,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.currency,
    required this.value,
  });

  factory StockHolding.fromJson(Map<String, dynamic> json) {
    return StockHolding(
      stockId: json['stock_id'] as String,
      ticker: json['ticker'] as String,
      name: json['name'] as String,
      shares: (json['shares'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      currency: json['currency'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stock_id': stockId,
      'ticker': ticker,
      'name': name,
      'shares': shares,
      'price': price,
      'change': change,
      'changePercent': changePercent,
      'currency': currency,
      'value': value,
    };
  }
}

class ChartPoint {
  final String date;
  final double value;

  const ChartPoint({required this.date, required this.value});

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      date: json['date'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'date': date, 'value': value};
}
