class RealEstateAsset {
  final String id;
  final String userId;
  final String propertyName;
  final String propertyType; // Single Family, Condo, Commercial, Land
  final double purchasePrice;
  final double currentValue;
  final double mortgageBalance;
  final double monthlyRentIncome;
  final double monthlyExpenses;
  final String? address;
  final String? purchaseDate;

  RealEstateAsset({
    required this.id,
    required this.userId,
    required this.propertyName,
    required this.propertyType,
    required this.purchasePrice,
    required this.currentValue,
    required this.mortgageBalance,
    required this.monthlyRentIncome,
    required this.monthlyExpenses,
    this.address,
    this.purchaseDate,
  });

  double get netEquity => currentValue - mortgageBalance;
  double get monthlyCashFlow => monthlyRentIncome - monthlyExpenses;
  double get annualCapRate => currentValue > 0 ? ((monthlyCashFlow * 12) / currentValue) * 100 : 0.0;

  factory RealEstateAsset.fromJson(Map<String, dynamic> json) {
    return RealEstateAsset(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      propertyName: json['property_name'] as String,
      propertyType: json['property_type'] as String,
      purchasePrice: (json['purchase_price'] as num).toDouble(),
      currentValue: (json['current_value'] as num).toDouble(),
      mortgageBalance: (json['mortgage_balance'] as num? ?? 0.0).toDouble(),
      monthlyRentIncome: (json['monthly_rent_income'] as num? ?? 0.0).toDouble(),
      monthlyExpenses: (json['monthly_expenses'] as num? ?? 0.0).toDouble(),
      address: json['address'] as String?,
      purchaseDate: json['purchase_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'property_name': propertyName,
      'property_type': propertyType,
      'purchase_price': purchasePrice,
      'current_value': currentValue,
      'mortgage_balance': mortgageBalance,
      'monthly_rent_income': monthlyRentIncome,
      'monthly_expenses': monthlyExpenses,
      'address': address,
      'purchase_date': purchaseDate,
    };
  }
}
