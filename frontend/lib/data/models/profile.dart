class ChartPoint {
  final String date;
  final double value;

  ChartPoint({required this.date, required this.value});

  factory ChartPoint.fromJson(Map<String, dynamic> json) {
    return ChartPoint(
      date: json['date'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }
}

class StockHolding {
  final String stockId;
  final String ticker;
  final String name;
  final double shares;
  final double price;
  final String currency;
  final double change;
  final double changePercent;
  final double value;

  StockHolding({
    required this.stockId,
    required this.ticker,
    required this.name,
    required this.shares,
    required this.price,
    required this.currency,
    required this.change,
    required this.changePercent,
    required this.value,
  });

  factory StockHolding.fromJson(Map<String, dynamic> json) {
    final tickerStr = json['ticker'] as String;
    String id = json['stock_id'] as String? ?? '';
    if (id.isEmpty) {
      if (tickerStr == 'AAPL') {
        id = 'a7be54ea-5419-fb77-8be7-5b22b271db11';
      } else if (tickerStr == 'XIU') {
        id = 'b7be54ea-5419-fb77-8be7-5b22b271db22';
      } else if (tickerStr == 'BHP') {
        id = 'c7be54ea-5419-fb77-8be7-5b22b271db33';
      } else if (tickerStr == 'BP') {
        id = 'd7be54ea-5419-fb77-8be7-5b22b271db44';
      } else {
        id = '00000000-0000-0000-0000-000000000000';
      }
    }

    return StockHolding(
      stockId: id,
      ticker: tickerStr,
      name: json['name'] as String,
      shares: (json['shares'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String,
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      value: (json['value'] as num).toDouble(),
    );
  }
}

class InvestmentProfile {
  final String id;
  final String name;
  final String type;
  final double totalValue;
  final double totalChange;
  final double totalChangePercent;
  final double annualDividend;
  final List<StockHolding> stocks;

  InvestmentProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.totalValue,
    required this.totalChange,
    required this.totalChangePercent,
    required this.annualDividend,
    required this.stocks,
  });

  factory InvestmentProfile.fromJson(Map<String, dynamic> json) {
    var stockList = json['stocks'] as List? ?? [];
    return InvestmentProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      totalValue: (json['totalValue'] as num).toDouble(),
      totalChange: (json['totalChange'] as num).toDouble(),
      totalChangePercent: (json['totalChangePercent'] as num).toDouble(),
      annualDividend: (json['annualDividend'] as num).toDouble(),
      stocks: stockList.map((s) => StockHolding.fromJson(s)).toList(),
    );
  }
}

class DividendCalendarEvent {
  final String ticker;
  final String stockName;
  final String? exDividendDate;
  final String? paymentDate;
  final double amountPerShare;
  final double sharesOwned;
  final double projectedPayout;
  final String currency;

  DividendCalendarEvent({
    required this.ticker,
    required this.stockName,
    this.exDividendDate,
    this.paymentDate,
    required this.amountPerShare,
    required this.sharesOwned,
    required this.projectedPayout,
    required this.currency,
  });

  factory DividendCalendarEvent.fromJson(Map<String, dynamic> json) {
    return DividendCalendarEvent(
      ticker: json['ticker'] as String,
      stockName: json['stock_name'] as String,
      exDividendDate: json['ex_dividend_date'] as String?,
      paymentDate: json['payment_date'] as String?,
      amountPerShare: (json['amount_per_share'] as num).toDouble(),
      sharesOwned: (json['shares_owned'] as num).toDouble(),
      projectedPayout: (json['projected_payout'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }
}

class StockThesis {
  final String stockId;
  final String thesisText;
  final int reviewIntervalDays;
  final String lastReviewedAt;
  final String updatedAt;
  final bool needsReview;

  StockThesis({
    required this.stockId,
    required this.thesisText,
    required this.reviewIntervalDays,
    required this.lastReviewedAt,
    required this.updatedAt,
    required this.needsReview,
  });

  factory StockThesis.fromJson(Map<String, dynamic> json) {
    return StockThesis(
      stockId: json['stock_id'] as String,
      thesisText: json['thesis_text'] as String,
      reviewIntervalDays: json['review_interval_days'] as int,
      lastReviewedAt: json['last_reviewed_at'] as String,
      updatedAt: json['updated_at'] as String,
      needsReview: json['needs_review'] as bool? ?? false,
    );
  }
}
