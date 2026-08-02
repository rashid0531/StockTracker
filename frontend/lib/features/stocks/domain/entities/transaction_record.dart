class TransactionRecord {
  final String id;
  final String profileId;
  final String profileName;
  final String ticker;
  final String stockName;
  final String type; // BUY or SELL
  final double quantity;
  final double pricePerShare;
  final double totalAmount;
  final String currency;
  final String transactionDate;

  const TransactionRecord({
    required this.id,
    required this.profileId,
    required this.profileName,
    required this.ticker,
    required this.stockName,
    required this.type,
    required this.quantity,
    required this.pricePerShare,
    required this.totalAmount,
    required this.currency,
    required this.transactionDate,
  });

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      profileName: json['profile_name'] as String? ?? 'General Profile',
      ticker: json['ticker'] as String,
      stockName: json['stock_name'] as String? ?? json['ticker'] as String,
      type: json['transaction_type'] as String? ?? 'BUY',
      quantity: (json['quantity'] as num).toDouble(),
      pricePerShare: (json['price_per_share'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      transactionDate: json['transaction_date'] as String? ?? '2026-07-30',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'profile_name': profileName,
      'ticker': ticker,
      'stock_name': stockName,
      'transaction_type': type,
      'quantity': quantity,
      'price_per_share': pricePerShare,
      'total_amount': totalAmount,
      'currency': currency,
      'transaction_date': transactionDate,
    };
  }
}
