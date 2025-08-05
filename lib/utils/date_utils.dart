import 'package:intl/intl.dart';

import 'package:intl/intl.dart';

String formatMsgTime(String? timeStr) {
  if (timeStr == null || timeStr.isEmpty) return '';

  try {
    final msgTime = DateTime.parse(timeStr).toLocal();
    final now = DateTime.now().toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final diff = now.difference(msgTime);

    // 刚刚 / n分钟前 / n小时前
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24 && msgTime.isAfter(today)) {
      return '${diff.inHours}小时前';
    }

    // 昨天
    if (_isSameDate(msgTime, yesterday)) {
      return '昨天 ${DateFormat('HH:mm').format(msgTime)}';
    }

    // 本周内（周一~周日）
    final weekdayStart = today.subtract(Duration(days: today.weekday - 1));
    if (msgTime.isAfter(weekdayStart) && msgTime.isBefore(today)) {
      final weekday = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'][msgTime.weekday - 1];
      return '$weekday ${DateFormat('HH:mm').format(msgTime)}';
    }

    // 本年
    if (msgTime.year == now.year) {
      return DateFormat('MM-dd HH:mm').format(msgTime);
    }

    // 跨年
    return DateFormat('yyyy-MM-dd HH:mm').format(msgTime);
  } catch (_) {
    return '';
  }
}

/// 判断两个 DateTime 是否为同一天（忽略时分秒）
bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;


// 判断是否是同一天
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// 判断是否是昨天
bool isYesterday(DateTime messageTime, DateTime now) {
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  return isSameDay(messageTime, yesterday);
}

// 判断是否在一周内
bool isWithinAWeek(DateTime messageTime, DateTime now) {
  final oneWeekAgo = now.subtract(const Duration(days: 7));
  return messageTime.isAfter(oneWeekAgo);
}

// 获取星期几的中文名称
String getWeekdayString(int weekday) {
  const weekdayMap = {
    1: '周一',
    2: '周二',
    3: '周三',
    4: '周四',
    5: '周五',
    6: '周六',
    7: '周日',
  };
  return weekdayMap[weekday] ?? '';
}
