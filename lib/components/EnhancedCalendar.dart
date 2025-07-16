import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class EnhancedCalendar extends StatefulWidget {
  final List<DateTime> eventDates;
  final Function(DateTime)? onDaySelected;
  final DateTime? initialDate;
  final bool showEventMarkers;
  final Color? primaryColor;
  final Color? accentColor;

  const EnhancedCalendar({
    super.key,
    this.eventDates = const [],
    this.onDaySelected,
    this.initialDate,
    this.showEventMarkers = true,
    this.primaryColor,
    this.accentColor,
  });

  @override
  State<EnhancedCalendar> createState() => _EnhancedCalendarState();
}

class _EnhancedCalendarState extends State<EnhancedCalendar> {
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
    final primaryColor = widget.primaryColor ?? const Color(0xFFF48FB1);
    final accentColor = widget.accentColor ?? const Color(0xFF64B5F6);

    return Container(
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
        eventLoader: widget.showEventMarkers ? _getEventsForDay : null,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDaySelected?.call(selectedDay);
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
        calendarStyle: CalendarStyle(
          // 普通日期样式
          defaultTextStyle: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          weekendTextStyle: const TextStyle(
            color: Colors.red,
            fontSize: 16,
          ),
          
          // 今天样式
          todayDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          
          // 选中日期样式
          selectedDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentColor, accentColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          
          // 标记样式
          markersMaxCount: 3,
          markerDecoration: BoxDecoration(
            color: primaryColor.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          markerSize: 6,
          markerMargin: const EdgeInsets.symmetric(horizontal: 0.3),
          
          // 其他样式
          outsideTextStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
          disabledTextStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
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
      ),
    );
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return widget.eventDates
        .where((eventDate) => isSameDay(eventDate, day))
        .toList();
  }
}

// 使用示例
class CalendarExample extends StatefulWidget {
  const CalendarExample({super.key});

  @override
  State<CalendarExample> createState() => _CalendarExampleState();
}

class _CalendarExampleState extends State<CalendarExample> {
  List<DateTime> _eventDates = [];
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // 添加一些示例事件日期
    _eventDates = [
      DateTime.now(),
      DateTime.now().add(const Duration(days: 1)),
      DateTime.now().add(const Duration(days: 7)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('增强日历'),
        backgroundColor: const Color(0xFFF48FB1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            EnhancedCalendar(
              eventDates: _eventDates,
              onDaySelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
                _showDateInfo(date);
              },
              primaryColor: const Color(0xFFF48FB1),
              accentColor: const Color(0xFF64B5F6),
            ),
            const SizedBox(height: 20),
            if (_selectedDate != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF48FB1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '选中日期: ${DateFormat('yyyy年MM月dd日').format(_selectedDate!)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDateInfo(DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('yyyy年MM月dd日').format(date)),
        content: Text('这是一个特殊的日子！'),
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