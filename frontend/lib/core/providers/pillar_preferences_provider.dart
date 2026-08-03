import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PillarPreferencesProvider extends ChangeNotifier {
  bool _isStocksEnabled = true;
  bool _isRealEstateEnabled = true;
  bool _isPreciousMetalsEnabled = true;
  bool _isHealthEnabled = true;

  bool get isStocksEnabled => _isStocksEnabled;
  bool get isRealEstateEnabled => _isRealEstateEnabled;
  bool get isPreciousMetalsEnabled => _isPreciousMetalsEnabled;
  bool get isHealthEnabled => _isHealthEnabled;

  int get activePillarCount {
    int count = 0;
    if (_isStocksEnabled) count++;
    if (_isRealEstateEnabled) count++;
    if (_isPreciousMetalsEnabled) count++;
    if (_isHealthEnabled) count++;
    return count;
  }

  PillarPreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isStocksEnabled = prefs.getBool('pillar_stocks') ?? true;
      _isRealEstateEnabled = prefs.getBool('pillar_real_estate') ?? true;
      _isPreciousMetalsEnabled = prefs.getBool('pillar_precious_metals') ?? true;
      _isHealthEnabled = prefs.getBool('pillar_health') ?? true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> togglePillar(String pillarKey, bool enabled) async {
    if (pillarKey == "Stocks") {
      _isStocksEnabled = enabled;
    } else if (pillarKey == "Real-Estate") {
      _isRealEstateEnabled = enabled;
    } else if (pillarKey == "Precious Metals") {
      _isPreciousMetalsEnabled = enabled;
    } else if (pillarKey == "Health") {
      _isHealthEnabled = enabled;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (pillarKey == "Stocks") await prefs.setBool('pillar_stocks', enabled);
      if (pillarKey == "Real-Estate") await prefs.setBool('pillar_real_estate', enabled);
      if (pillarKey == "Precious Metals") await prefs.setBool('pillar_precious_metals', enabled);
      if (pillarKey == "Health") await prefs.setBool('pillar_health', enabled);
    } catch (_) {}
  }

  bool isPillarEnabled(String key) {
    if (key == "Stocks") return _isStocksEnabled;
    if (key == "Real-Estate") return _isRealEstateEnabled;
    if (key == "Precious Metals") return _isPreciousMetalsEnabled;
    if (key == "Health") return _isHealthEnabled;
    return true;
  }
}
