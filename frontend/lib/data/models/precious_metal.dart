class PreciousMetalAsset {
  final String id;
  final String userId;
  final String metalType; // Gold, Silver, Platinum, Palladium, Bronze
  final String form; // Bullion Bar, Coin, Jewelry, Grain
  final double weightOz;
  final double purityPercent;
  final double purchasePricePerOz;
  final double currentSpotPricePerOz;
  final String storageLocation;
  final String? purchaseDate;

  PreciousMetalAsset({
    required this.id,
    required this.userId,
    required this.metalType,
    required this.form,
    required this.weightOz,
    required this.purityPercent,
    required this.purchasePricePerOz,
    required this.currentSpotPricePerOz,
    required this.storageLocation,
    this.purchaseDate,
  });

  double get totalCurrentValue => weightOz * currentSpotPricePerOz;
  double get totalPurchaseCost => weightOz * purchasePricePerOz;
  double get totalGainLoss => totalCurrentValue - totalPurchaseCost;
  double get gainLossPercent => totalPurchaseCost > 0 ? (totalGainLoss / totalPurchaseCost) * 100 : 0.0;

  factory PreciousMetalAsset.fromJson(Map<String, dynamic> json) {
    return PreciousMetalAsset(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      metalType: json['metal_type'] as String,
      form: json['form'] as String,
      weightOz: (json['weight_oz'] as num).toDouble(),
      purityPercent: (json['purity_percent'] as num? ?? 99.9).toDouble(),
      purchasePricePerOz: (json['purchase_price_per_oz'] as num).toDouble(),
      currentSpotPricePerOz: (json['current_spot_price_per_oz'] as num).toDouble(),
      storageLocation: json['storage_location'] as String? ?? 'Home Safe',
      purchaseDate: json['purchase_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'metal_type': metalType,
      'form': form,
      'weight_oz': weightOz,
      'purity_percent': purityPercent,
      'purchase_price_per_oz': purchasePricePerOz,
      'current_spot_price_per_oz': currentSpotPricePerOz,
      'storage_location': storageLocation,
      'purchase_date': purchaseDate,
    };
  }
}
