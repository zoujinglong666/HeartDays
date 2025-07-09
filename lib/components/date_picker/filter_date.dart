// filter_date.dart

import 'package:flutter/material.dart';
import 'package:heart_days/components/date_picker/picker_item.dart';
import 'custom_picker.dart';
import 'date_picker.dart';
import 'date_picker_utils.dart';

/// 用于按年、月、周筛选日期的组件
class FilterDate extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<dynamic> onDateChanged;
  final FilterType type;
  final int yearsBack;
  final int yearsForward;
  final bool showLaterTime;
  final WeekItemBuilder? weekItemBuilder; // 接收自定义构建器

  const FilterDate({
    super.key,
    this.yearsBack = 3,
    this.yearsForward = 0,
    required this.showLaterTime,
    required this.type,
    required this.initialDate,
    required this.onDateChanged,
    this.weekItemBuilder,
  });

  @override
  State<FilterDate> createState() => _FilterDateState();
}

class _FilterDateState extends State<FilterDate> {
  // 周选择器状态
  List<String> _weekList = [];
  int _initialWeekIndex = 0;

  // 年/月选择器状态
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  //  将默认的周UI构建逻辑提取到一个单独的方法中
  Widget _defaultWeekItemBuilder(
    BuildContext context,
    String weekData,
    bool isSelected,
  ) {
    final dateRange = weekData.split("(")[0];
    final weekText = weekData.split("(")[1];

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            dateRange,
            style: TextStyle(
              fontSize: isSelected ? 18 : 14,
              color: isSelected ? const Color(0xFF3482FF) : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "($weekText",
            style: TextStyle(
              fontSize: isSelected ? 14 : 11,
              color: isSelected ? const Color(0xFF3482FF) : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _initializeState() {
    switch (widget.type) {
      case FilterType.week:
        _weekList = getWeeksList(
          widget.initialDate,
          widget.yearsBack,
          widget.showLaterTime,
        );
        // 查找初始日期所在的周的索引
        _initialWeekIndex = _weekList.indexWhere((week) {
          final weekTime = getWeekTime(week);
          final start = weekTime["startTime"]!;
          final end = weekTime["endTime"]!.add(
            const Duration(days: 1),
          ); // end is exclusive
          return widget.initialDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              widget.initialDate.isBefore(end);
        });
        if (_initialWeekIndex == -1)
          _initialWeekIndex = _weekList.length - 1; // 默认选中最后一周
        break;
      case FilterType.year:
        _selectedYear = widget.initialDate.year;
        break;
      case FilterType.month:
        _selectedYear = widget.initialDate.year;
        _selectedMonth = widget.initialDate.month;
        break;
    }
  }

  void _onFilterChanged() {
    late Map<String, int> resDate;
    if (widget.type == FilterType.year) {
      resDate = {"year": _selectedYear};
    } else if (widget.type == FilterType.month) {
      resDate = {"year": _selectedYear, "month": _selectedMonth};
    }
    widget.onDateChanged(resDate);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, // 统一高度
      child: _buildPickerForType(),
    );
  }

  Widget _buildPickerForType() {
    switch (widget.type) {
      case FilterType.week:
        return _buildWeekPicker();
      case FilterType.month:
        return _buildMonthPicker();
      case FilterType.year:
        return _buildYearPicker();
    }
  }

  Widget _buildWeekPicker() {
    return CustomPicker(
      startValue: 0,
      endValue: _weekList.length - 1,
      initialValue: _initialWeekIndex,
      onValueChanged: (index) {
        final weekTime = getWeekTime(_weekList[index]);
        widget.onDateChanged(weekTime);
      },
      itemBuilder: (context, value, isSelected) {
        // value 在这里是 index
        final weekData = _weekList[value];
        // 如果外部传入了自定义构建器，则使用它
        if (widget.weekItemBuilder != null) {
          return widget.weekItemBuilder!(context, weekData, isSelected);
        }
        // 否则，使用我们定义的默认构建器
        return _defaultWeekItemBuilder(context, weekData, isSelected);
      },
    );
  }

  Widget _buildMonthPicker() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: CustomPicker(
              startValue: now.year - widget.yearsBack,
              endValue: now.year + widget.yearsForward,
              initialValue: _selectedYear,
              onValueChanged: (value) {
                setState(() {
                  _selectedYear = value;
                  // 如果年份是今年，且月份超过了当前月份，则修正月份
                  if (!widget.showLaterTime &&
                      _selectedYear == now.year &&
                      _selectedMonth > now.month) {
                    _selectedMonth = now.month;
                  }
                });
                _onFilterChanged();
              },
              itemBuilder:
                  (context, value, isSelected) =>
                      pickerItem(value.toString(), "年", isSelected),
            ),
          ),
          Expanded(
            child: CustomPicker(
              startValue: 1,
              endValue:
                  !widget.showLaterTime && _selectedYear == now.year
                      ? now.month
                      : 12,
              initialValue: _selectedMonth,
              onValueChanged: (value) {
                setState(() {
                  _selectedMonth = value;
                });
                _onFilterChanged();
              },
              itemBuilder:
                  (context, value, isSelected) => pickerItem(
                    value.toString().padLeft(2, '0'),
                    "月",
                    isSelected,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearPicker() {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: CustomPicker(
        startValue: now.year - widget.yearsBack,
        endValue: now.year,
        initialValue: _selectedYear,
        onValueChanged: (value) {
          setState(() {
            _selectedYear = value;
          });
          _onFilterChanged();
        },
        itemBuilder:
            (context, value, isSelected) =>
               pickerItem(value.toString(), "年", isSelected),
      ),
    );
  }

}
