
/// 格式化日期为 YYYY.MM.DD
String _formatDate(DateTime date) {
  String year = date.year.toString();
  String month = date.month.toString().padLeft(2, '0');
  String day = date.day.toString().padLeft(2, '0');
  return "$year.$month.$day";
}

/// 计算给定日期是当年的第几周
int _getWeekOfYear(DateTime date) {
  DateTime firstDayOfYear = DateTime(date.year, 1, 1);
  int dayOfYear = date.difference(firstDayOfYear).inDays + 1;
  return ((dayOfYear - 1) / 7).floor() + 1;
}

/// 根据初始日期、回溯年数和是否允许选择未来时间，生成一个周列表
///
/// @param initialDate - 计算的基准日期
/// @param yearsBack - 从基准日期年份回溯的年数
/// @param showLaterTime - 是否允许生成未来的周
/// @return 返回一个字符串列表，格式如 "2023.01.02~2023.01.08(第一周)"
List<String> getWeeksList(DateTime initialDate, int yearsBack, bool showLaterTime) {
  int currentYear = initialDate.year;
  int startYear = currentYear - yearsBack;
  List<String> weeksList = [];

  // 计算起始年份的1月1日
  DateTime loopStartDate = DateTime(startYear, 1, 1);
  // 循环的结束日期，如果不允许选择未来，则为今天；否则可以设置一个更远的未来日期
  DateTime loopEndDate = showLaterTime ? DateTime(currentYear + 1, 12, 31) : DateTime.now();

  // 确保我们的周是从周一开始的
  int daysToMonday = (loopStartDate.weekday - DateTime.monday + 7) % 7;
  DateTime currentWeekStart = loopStartDate.subtract(Duration(days: daysToMonday));

  while (currentWeekStart.isBefore(loopEndDate)) {
    DateTime currentWeekEnd = currentWeekStart.add(const Duration(days: 6));

    // 如果不允许选择未来时间，并且当前周的结束时间在今天之后，就中断循环
    if (!showLaterTime && currentWeekEnd.isAfter(DateTime.now())) {
      // 特殊处理：如果本周包含了今天，那么将本周作为最后一周加入列表
      if (currentWeekStart.isBefore(DateTime.now())) {
        // 不截断，显示完整的一周
      } else {
        break; // 如果整周都在未来，则跳出
      }
    }

    String weekLabel;
    final now = DateTime.now();
    // 判断是否是本周
    if ( (currentWeekStart.isBefore(now) || currentWeekStart.isAtSameMomentAs(now)) &&
        (currentWeekEnd.isAfter(now) || currentWeekEnd.isAtSameMomentAs(now)) ) {
      weekLabel = "${_formatDate(currentWeekStart)}~${_formatDate(currentWeekEnd)}(本周)";
    } else {
      int weekNumber = _getWeekOfYear(currentWeekStart);
      weekLabel = "${_formatDate(currentWeekStart)}~${_formatDate(currentWeekEnd)}(第$weekNumber周)";
    }
    weeksList.add(weekLabel);

    // 如果不允许选择未来时间，并且已经处理完包含今天的周，则跳出
    if (!showLaterTime && currentWeekEnd.isAfter(DateTime.now())) {
      break;
    }

    // 移动到下一周的开始
    currentWeekStart = currentWeekStart.add(const Duration(days: 7));
  }
  return weeksList;
}

/// 从周列表的字符串中解析出开始和结束的DateTime对象
/// @param weekValue - 格式如 "2023.01.02~2023.01.08(第一周)" 的字符串
/// @return 返回一个包含 "startTime" 和 "endTime" 的Map
Map<String, DateTime> getWeekTime(String weekValue) {
  String week = weekValue.split('(')[0];
  String startDateStr = week.split('~')[0];
  String endDateStr = week.split('~')[1];
  List<String> startParts = startDateStr.split('.');
  List<String> endParts = endDateStr.split('.');
  DateTime currentWeekStart = DateTime(
    int.parse(startParts[0]),
    int.parse(startParts[1]),
    int.parse(startParts[2]),
  );
  DateTime currentWeekEnd = DateTime(
    int.parse(endParts[0]),
    int.parse(endParts[1]),
    int.parse(endParts[2]),
  );
  return {
    "startTime": currentWeekStart,
    "endTime": currentWeekEnd
  };
}
