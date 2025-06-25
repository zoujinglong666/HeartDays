import 'package:flutter/cupertino.dart';

class SafeNavigator {
  static bool _locked = false;

  static Future<T?> pushOnce<T>(BuildContext context, Widget page) async {
    if (_locked) return null;
    _locked = true;
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => page),
    );
    _locked = false;
    return result;
  }
}
