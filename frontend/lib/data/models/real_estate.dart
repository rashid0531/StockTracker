class RealEstateAsset {
  final String id;
  final String userId;
  final String propertyName;
  final String propertyType;
  final String region;
  final String propertyCategory;
  final String structuralType;
  final String tenureModel;
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
    this.region = "North America (NA)",
    this.propertyCategory = "Single-Family",
    this.structuralType = "Single-Family Detached",
    this.tenureModel = "Freehold",
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
      region: json['region'] as String? ?? "North America (NA)",
      propertyCategory: json['property_category'] as String? ?? "Single-Family",
      structuralType: json['structural_type'] as String? ?? json['property_type'] as String? ?? "Single-Family Detached",
      tenureModel: json['tenure_model'] as String? ?? "Freehold",
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
      'region': region,
      'property_category': propertyCategory,
      'structural_type': structuralType,
      'tenure_model': tenureModel,
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
