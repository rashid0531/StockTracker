import '../../../../data/models/precious_metal.dart';

abstract class PreciousMetalsRepository {
  Future<List<PreciousMetalAsset>> getPreciousMetals();
  Future<PreciousMetalAsset> addPreciousMetalAsset(Map<String, dynamic> body);
}
