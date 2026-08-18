import 'package:flutter/material.dart';
import 'data/services/api_service.dart';

void main() async {
  final api = ApiService();
  final profiles = await api.getProfiles();
  print("Profiles count: \${profiles.length}");
  for (var p in profiles) {
    print("Profile \${p.name} has \${p.stocks.length} stocks");
  }
}
