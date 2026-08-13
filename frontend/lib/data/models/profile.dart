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

String getDeterministicStockId(String ticker) {
  const Map<String, String> predefined = {
    "AAPL": "a7be54ea-5419-fb77-8be7-5b22b271db11",
    "XIU": "b7be54ea-5419-fb77-8be7-5b22b271db22",
    "BHP": "c7be54ea-5419-fb77-8be7-5b22b271db33",
    "BP": "d7be54ea-5419-fb77-8be7-5b22b271db44",
  };
  if (predefined.containsKey(ticker)) {
    return predefined[ticker]!;
  }
  int hash = 0;
  for (int i = 0; i < ticker.length; i++) {
    hash = (hash * 31 + ticker.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  final hex = hash.toRadixString(16).padLeft(8, '0');
  return "00000000-0000-0000-0000-${hex.padLeft(12, '0')}";
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
    final String id = json['stock_id'] as String? ?? getDeterministicStockId(tickerStr);

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
  final String? country;
  final double totalValue;
  final double totalChange;
  final double totalChangePercent;
  final double annualDividend;
  final List<StockHolding> stocks;

  InvestmentProfile({
    required this.id,
    required this.name,
    required this.type,
    this.country,
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
      country: json['country'] as String? ?? 'Canada',
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

class DividendReceived {
  final String id;
  final String ticker;
  final String stockName;
  final String paymentDate;
  final double amountPerShare;
  final double sharesAtPayment;
  final double totalReceived;
  final String currency;
  final String? notes;

  DividendReceived({
    required this.id,
    required this.ticker,
    required this.stockName,
    required this.paymentDate,
    required this.amountPerShare,
    required this.sharesAtPayment,
    required this.totalReceived,
    required this.currency,
    this.notes,
  });

  factory DividendReceived.fromJson(Map<String, dynamic> json) {
    return DividendReceived(
      id: json['id'] as String? ?? '',
      ticker: json['ticker'] as String,
      stockName: json['stock_name'] as String? ?? json['ticker'] as String,
      paymentDate: json['payment_date'] as String,
      amountPerShare: (json['amount_per_share'] as num).toDouble(),
      sharesAtPayment: (json['shares_at_payment'] as num).toDouble(),
      totalReceived: (json['total_received'] as num).toDouble(),
      currency: json['currency'] as String,
      notes: json['notes'] as String?,
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

class TransactionRecord {
  final String id;
  final String profileId;
  final String profileName;
  final String ticker;
  final String stockName;
  final String type; // "BUY" | "SELL"
  final double shares;
  final double price;
  final double totalAmount;
  final String currency;
  final String date;

  TransactionRecord({
    required this.id,
    required this.profileId,
    required this.profileName,
    required this.ticker,
    required this.stockName,
    required this.type,
    required this.shares,
    required this.price,
    required this.totalAmount,
    required this.currency,
    required this.date,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      profileId: json['profile_id'] as String? ?? '',
      profileName: json['profile_name'] as String? ?? 'General Profile',
      ticker: json['ticker'] as String,
      stockName: json['stock_name'] as String? ?? json['ticker'] as String,
      type: (json['transaction_type'] as String? ?? 'BUY').toUpperCase(),
      shares: (json['quantity'] as num? ?? json['shares'] as num? ?? 0).toDouble(),
      price: (json['price_per_share'] as num? ?? json['price'] as num? ?? 0).toDouble(),
      totalAmount: (json['total_amount'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      date: json['transaction_date'] as String? ?? json['date'] as String? ?? 'Today',
    );
  }
}
