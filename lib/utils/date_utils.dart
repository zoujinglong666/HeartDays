import 'package:intl/intl.dart';

String formatMsgTime(String? timeStr) {
  if (timeStr == null || timeStr.isEmpty) return '';
  try {
    final DateTime messageTime = DateTime.parse(timeStr).toLocal();
    final DateTime now = DateTime.now().toLocal();

    // 今天
    if (isSameDay(messageTime, now)) {
      return DateFormat('HH:mm').format(messageTime);
    }
    // 昨天
    else if (isYesterday(messageTime, now)) {
      return '昨天 ${DateFormat('HH:mm').format(messageTime)}';
    }
    // 一周内
    else if (isWithinAWeek(messageTime, now)) {
      return '${getWeekdayString(messageTime.weekday)} ${DateFormat('HH:mm').format(messageTime)}';
    }
    // 超过一周
    else {
      return DateFormat('yyyy/MM/dd HH:mm').format(messageTime);
    }
  } catch (e) {
    return '';
  }
}

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
