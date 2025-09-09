import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:heart_days/models/regional.dart';

final class Consts {
  Consts._();

  static late final List<Regional> regional;

  static Future<void> ensureInitialized() async {
    final data = await rootBundle.loadString("assets/city.json");
    final items = jsonDecode(data) as List<dynamic>;
    regional = items.map((e) => Regional.fromJson(e)).toList();
  }
  /// Empty function constant
  static void doNothing() {}

  /// About network request
  static const request = (
  baseUrl: "http://10.9.17.103:8888/api/v1",
  socketUrl: "http://10.9.17.103:8888",

  minWaitingTime: Duration(milliseconds: 500),
  cachedTime: Duration(milliseconds: 2000),

  sendTimeout: Duration(seconds: 5),
  connectTimeout: Duration(seconds: 30),
  receiveTimeout: Duration(seconds: 30),

  successCode: 200,

  pageSize: 10,
  );
  static const password = (
  secret: "HeartDays0625",
  );


}