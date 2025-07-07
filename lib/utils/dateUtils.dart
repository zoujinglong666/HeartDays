import 'package:intl/intl.dart';

String formatDateTime(DateTime dateTime) {
  final utcTime = DateTime.parse(dateTime.toIso8601String()); // 后端返回的时间
  final localTime = utcTime.toLocal(); // 转为本地时区
  final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  return formatter.format(localTime); // 2025-07-06 16:00:00（如果你在东八区）
}