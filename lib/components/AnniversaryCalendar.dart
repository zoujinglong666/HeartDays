import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:heart_days/apis/anniversary.dart';

class AnniversaryCalendar extends StatefulWidget {
  final List<Anniversary> anniversaries;
  final Function(DateTime)? onDaySelected;
  final Function(DateTime, List<Anniversary>)? onDayWithEventsSelected;
  final DateTime? initialDate;
  final Color? primaryColor;
  final Color? accentColor;

  const AnniversaryCalendar({
    super.key,
    required this.anniversaries,
    this.onDaySelected,
    this.onDayWithEventsSelected,
    this.initialDate,
    this.primaryColor,
    this.accentColor,
  });

  @override
  State<AnniversaryCalendar> createState() => _AnniversaryCalendarState();
}

class _AnniversaryCalendarState extends State<AnniversaryCalendar> {
  late DateTime _focusedDay;
  late DateTime? _selectedDay;
  late CalendarFormat _calendarFormat;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate ?? DateTime.now();
    _calendarFormat = CalendarFormat.month;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.primaryColor ?? const Color(0xFF6A8CFF);
    final accentColor = widget.accentColor ?? const Color(0xFF64B5F6);

    return Container(
      width: double.infinity,
      height: 540,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getEventsForDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });

          final events = _getEventsForDay(selectedDay);
          if (events.isNotEmpty) {
            widget.onDayWithEventsSelected?.call(selectedDay, events);
          } else {
            widget.onDaySelected?.call(selectedDay);
          }
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        daysOfWeekHeight: 48,
        rowHeight: 64, // 格子更大
        calendarStyle: CalendarStyle(
          // 移除事件标记（黑色小圆点）
          markersAutoAligned: false,
          markersMaxCount: 0,
          markerSize: 0,
          markerDecoration: const BoxDecoration(
            color: Colors.transparent,
          ),

          defaultTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          weekendTextStyle: const TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
          todayDecoration: BoxDecoration(
            color: primaryColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          selectedDecoration: BoxDecoration(
            color: accentColor.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: accentColor, width: 2),
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          outsideTextStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          disabledTextStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          cellMargin: const EdgeInsets.all(2),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: true,
          formatButtonShowsNext: false,
          formatButtonDecoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          formatButtonTextStyle: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: primaryColor,
            size: 24,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: primaryColor,
            size: 24,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, date, _) {
            final events = _getEventsForDay(date);
            if (events.isNotEmpty) {
              return _buildEventCell(date, events, isSelected: false);
            } else {
              return _buildEmptyCell(date, isSelected: false);
            }
          },
          selectedBuilder: (context, date, _) {
            final events = _getEventsForDay(date);
            if (events.isNotEmpty) {
              return _buildEventCell(date, events, isSelected: true);
            } else {
              return _buildEmptyCell(date, isSelected: true);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEventCell(DateTime date, List<Anniversary> events, {bool isSelected = false}) {
    // 只显示第一条，若有多条则显示+N
    final firstEvent = events.first;
    final moreCount = events.length - 1;
    // 获取事件颜色或使用默认颜色
    final eventColor = firstEvent.color ?? const Color(0xFF6A8CFF);

    return Container(
      margin: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80, minWidth: double.infinity),
      decoration: BoxDecoration(
        gradient: isSelected 
            ? LinearGradient(
                colors: [
                  eventColor.withOpacity(0.2),
                  eventColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white,
                  eventColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: eventColor, width: 2.5)
            : Border.all(color: eventColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: eventColor.withOpacity(isSelected ? 0.2 : 0.1),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
            spreadRadius: isSelected ? 1 : 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 日期数字 - 更现代的设计
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  eventColor,
                  eventColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: eventColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 事件标题 - 优化字体和颜色
          Flexible(
            child: Text(
              firstEvent.title,
              style: TextStyle(
                fontSize: 11,
                color: eventColor.withOpacity(0.9),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // 多事件指示器 - 更精致的设计
          if (moreCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      eventColor.withOpacity(0.8),
                      eventColor.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: eventColor.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '+$moreCount',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCell(DateTime date, {bool isSelected = false}) {
    final today = DateTime.now();
    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
    
    return Container(
      margin: const EdgeInsets.all(3),
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 72, minWidth: double.infinity),
      decoration: BoxDecoration(
        gradient: isSelected 
            ? const LinearGradient(
                colors: [
                  Color(0xFFE3F2FD),
                  Color(0xFFF3E5F5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isToday
                ? LinearGradient(
                    colors: [
                      Colors.white,
                      const Color(0xFF6A8CFF).withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFFAFAFA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFF90CAF9)
              : isToday
                  ? const Color(0xFF6A8CFF).withOpacity(0.4)
                  : Colors.grey.withOpacity(0.15),
          width: isSelected ? 2.5 : isToday ? 2 : 1,
        ),
        boxShadow: [
          if (isSelected || isToday)
            BoxShadow(
              color: isSelected 
                  ? const Color(0xFF90CAF9).withOpacity(0.2)
                  : const Color(0xFF6A8CFF).withOpacity(0.1),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
              spreadRadius: isSelected ? 1 : 0,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: isSelected 
                ? const LinearGradient(
                    colors: [
                      Color(0xFF90CAF9),
                      Color(0xFF64B5F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : isToday
                    ? LinearGradient(
                        colors: [
                          const Color(0xFF6A8CFF).withOpacity(0.2),
                          const Color(0xFF6A8CFF).withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.08),
                          Colors.grey.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
            borderRadius: BorderRadius.circular(16),
            border: isToday && !isSelected
                ? Border.all(
                    color: const Color(0xFF6A8CFF).withOpacity(0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected 
                    ? Colors.white
                    : isToday
                        ? const Color(0xFF6A8CFF)
                        : const Color(0xFF2C3E50),
                fontSize: 16,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Anniversary> _getEventsForDay(DateTime day) {
    return widget.anniversaries
        .where((anniversary) => isSameDay(anniversary.date, day))
        .toList();
  }
}

// 使用示例
class AnniversaryCalendarExample extends StatefulWidget {
  const AnniversaryCalendarExample({super.key});

  @override
  State<AnniversaryCalendarExample> createState() => _AnniversaryCalendarExampleState();
}

class _AnniversaryCalendarExampleState extends State<AnniversaryCalendarExample> {
  final List<Anniversary> _anniversaries = [];
  DateTime? _selectedDate;
  List<Anniversary> _selectedDateEvents = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('纪念日日历'),
        backgroundColor: const Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AnniversaryCalendar(
              anniversaries: _anniversaries,
              onDaySelected: (date) {
                setState(() {
                  _selectedDate = date;
                  _selectedDateEvents = [];
                });
              },
              onDayWithEventsSelected: (date, events) {
                setState(() {
                  _selectedDate = date;
                  _selectedDateEvents = events;
                });
                _showEventsDialog(date, events);
              },
              primaryColor: const Color(0xFFF48FB1),
              accentColor: const Color(0xFF64B5F6),
            ),
            const SizedBox(height: 20),
            if (_selectedDate != null)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF48FB1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选中日期: ${DateFormat('yyyy年MM月dd日').format(_selectedDate!)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_selectedDateEvents.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '该日期的纪念日:',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ..._selectedDateEvents.map((event) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(event.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEventsDialog(DateTime date, List<Anniversary> events) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('yyyy年MM月dd日').format(date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: events.map((event) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(event.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (event.description.isNotEmpty)
                        Text(
                          event.description,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.color?.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.type,
                    style: TextStyle(
                      color: event.color ?? Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
} 