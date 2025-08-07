import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:heart_days/models/regional.dart';

class RegionalDataHelper {
  static late final List<Regional> regional;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    final data = await rootBundle.loadString("lib/assets/city.json");
    final items = jsonDecode(data) as List<dynamic>;
    regional = items.map((e) => Regional.fromJson(e)).toList();
    _initialized = true;
  }

  static bool _initialized = false;
}