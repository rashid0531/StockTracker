import '../../../../data/models/real_estate.dart';

abstract class RealEstateRepository {
  Future<List<RealEstateAsset>> getRealEstateAssets();
  Future<RealEstateAsset> addRealEstateAsset(Map<String, dynamic> body);
}
