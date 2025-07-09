// edit_date.dart

import 'package:flutter/material.dart';

import 'custom_picker.dart';

/// 编辑日期和时间的组件。
/// 它可以显示年月日选择器，并能动态切换到时分选择器。
class EditDate extends StatefulWidget {
  /// 初始日期时间
  final DateTime initialDate;

  /// 是否显示 "时刻" 切换功能
  final bool showMoment;

  /// 是否允许选择未来的时间
  final bool showLaterTime;

  /// 可选的最小开始时间，用于限制选择范围
  final DateTime? startTime;

  /// 日期或时间发生变化时的回调
  final ValueChanged<DateTime> onDateChanged;


  const EditDate({
    super.key,
    required this.initialDate,
    required this.onDateChanged,

    this.showMoment = true,
    this.showLaterTime = true,
    this.startTime,
  });

  @override
  State<EditDate> createState() => _EditDateState();
}

class _EditDateState extends State<EditDate> {
  // 使用单一 DateTime 对象来管理所有选择的状态
  late DateTime _selectedDate;

  // 控制显示日期选择还是时间选择
  bool _isTimeSelectorVisible = false;

  // 当前时间，用于限制选择范围
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 初始化时，对传入的 initialDate 进行一次约束检查
    _selectedDate = _constrainDate(widget.initialDate);
  }

  @override
  void didUpdateWidget(EditDate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当外部传入的 initialDate 变化时，同步更新内部状态
    if (widget.initialDate != oldWidget.initialDate) {
      setState(() {
        _selectedDate = _constrainDate(widget.initialDate);
      });
    }
  }

  /// 核心方法：约束日期时间值
  /// 确保选择的日期不早于 `startTime` 且（在`showLaterTime`为false时）不晚于当前时间
  DateTime _constrainDate(DateTime date) {
    DateTime constrained = date;

    // 1. 检查是否早于允许的最小开始时间
    if (widget.startTime != null && constrained.isBefore(widget.startTime!)) {
      constrained = widget.startTime!;
    }

    // 2. 如果不允许选择未来时间，检查是否晚于当前时间
    if (!widget.showLaterTime && constrained.isAfter(_now)) {
      constrained = _now;
    }

    // 3. 修正日：确保 `day` 在当前年月下是有效的
    final daysInMonth = _getDaysInMonth(constrained.year, constrained.month);
    if (constrained.day > daysInMonth) {
      constrained = DateTime(
        constrained.year,
        constrained.month,
        daysInMonth,
        constrained.hour,
        constrained.minute,
      );
    }

    return constrained;
  }

  /// 统一处理值变化的方法
  void _handleDateChanged(DateTime newDate) {
    // 每次变化后都进行约束检查
    final constrainedDate = _constrainDate(newDate);

    // 如果约束后的值与当前值不同，则更新状态并回调
    if (constrainedDate != _selectedDate) {
      setState(() {
        _selectedDate = constrainedDate;
      });
    }
    // 即使值没有变化（例如，从31日切换到2月，自动修正为28/29日），也需要回调
    // 因为可能父组件需要知道这个被修正后的值
    widget.onDateChanged(constrainedDate);
  }

  /// 获取指定年月的总天数
  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDivider(),
        // 日期选择器部分 (年/月/日)
        AnimatedContainer(
          height: _isTimeSelectorVisible ? 1 : 120,
          duration: const Duration(milliseconds: 200),
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child:
              _isTimeSelectorVisible
                  ? const SizedBox.shrink()
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildYearPicker(),
                      _buildMonthPicker(),
                      _buildDayPicker(),
                    ],
                  ),
        ),
        // 如果需要显示时刻切换功能
        if (widget.showMoment) ...[
          // 如果时间选择器可见，显示已选的日期
          if (_isTimeSelectorVisible)
            _buildTapRow(
              "日期",
              "${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日",
            ),
          _buildDivider(),
          // 如果日期选择器可见，显示已选的时刻
          if (!_isTimeSelectorVisible)
            _buildTapRow(
              "时刻",
              "${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}",
            ),
          // 时间选择器部分 (时/分)
          AnimatedContainer(
            height: !_isTimeSelectorVisible ? 1 : 120,
            duration: const Duration(milliseconds: 200),
            color: Colors.white,
            child:
                !_isTimeSelectorVisible
                    ? const SizedBox.shrink()
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [_buildHourPicker(), _buildMinutePicker()],
                    ),
          ),
        ],
      ],
    );
  }

  // --- Picker Builder Methods ---

  Widget _buildYearPicker() {
    return Expanded(
      child: CustomPicker(
        startValue: widget.startTime?.year ?? 1970,
        endValue: _now.year,
        initialValue: _selectedDate.year,
        onValueChanged: (year) {
          _handleDateChanged(
            DateTime(
              year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedDate.hour,
              _selectedDate.minute,
            ),
          );
        },
        itemBuilder:
            (context, value, isSelected) =>
                _buildPickerItem(value.toString(), "年", isSelected),
      ),
    );
  }

  Widget _buildMonthPicker() {
    // 确定月份的最小和最大值
    int minMonth = 1;
    if (widget.startTime != null &&
        _selectedDate.year == widget.startTime!.year) {
      minMonth = widget.startTime!.month;
    }

    int maxMonth = 12;
    if (!widget.showLaterTime && _selectedDate.year == _now.year) {
      maxMonth = _now.month;
    }

    return Expanded(
      child: CustomPicker(
        startValue: minMonth,
        endValue: maxMonth,
        initialValue: _selectedDate.month,
        onValueChanged: (month) {
          _handleDateChanged(
            DateTime(
              _selectedDate.year,
              month,
              _selectedDate.day,
              _selectedDate.hour,
              _selectedDate.minute,
            ),
          );
        },
        itemBuilder:
            (context, value, isSelected) => _buildPickerItem(
              value.toString().padLeft(2, '0'),
              "月",
              isSelected,
            ),
      ),
    );
  }

  Widget _buildDayPicker() {
    int minDay = 1;
    if (widget.startTime != null &&
        _selectedDate.year == widget.startTime!.year &&
        _selectedDate.month == widget.startTime!.month) {
      minDay = widget.startTime!.day;
    }

    int maxDay = _getDaysInMonth(_selectedDate.year, _selectedDate.month);
    if (!widget.showLaterTime &&
        _selectedDate.year == _now.year &&
        _selectedDate.month == _now.month) {
      maxDay = _now.day;
    }

    return Expanded(
      child: CustomPicker(
        startValue: minDay,
        endValue: maxDay,
        initialValue: _selectedDate.day,
        onValueChanged: (day) {
          _handleDateChanged(
            DateTime(
              _selectedDate.year,
              _selectedDate.month,
              day,
              _selectedDate.hour,
              _selectedDate.minute,
            ),
          );
        },
        itemBuilder:
            (context, value, isSelected) => _buildPickerItem(
              value.toString().padLeft(2, '0'),
              "日",
              isSelected,
            ),
      ),
    );
  }

  Widget _buildHourPicker() {
    int minHour = 0;
    if (widget.startTime != null &&
        _isSameDay(_selectedDate, widget.startTime!)) {
      minHour = widget.startTime!.hour;
    }

    int maxHour = 23;
    if (!widget.showLaterTime && _isSameDay(_selectedDate, _now)) {
      maxHour = _now.hour;
    }

    return Expanded(
      child: CustomPicker(
        startValue: minHour,
        endValue: maxHour,
        initialValue: _selectedDate.hour,
        onValueChanged: (hour) {
          _handleDateChanged(
            DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              hour,
              _selectedDate.minute,
            ),
          );
        },
        itemBuilder:
            (context, value, isSelected) => _buildPickerItem(
              value.toString().padLeft(2, '0'),
              "时",
              isSelected,
            ),
      ),
    );
  }

  Widget _buildMinutePicker() {
    int minMinute = 0;
    if (widget.startTime != null &&
        _isSameDay(_selectedDate, widget.startTime!) &&
        _selectedDate.hour == widget.startTime!.hour) {
      minMinute = widget.startTime!.minute;
    }

    int maxMinute = 59;
    if (!widget.showLaterTime &&
        _isSameDay(_selectedDate, _now) &&
        _selectedDate.hour == _now.hour) {
      maxMinute = _now.minute;
    }

    return Expanded(
      child: CustomPicker(
        startValue: minMinute,
        endValue: maxMinute,
        initialValue: _selectedDate.minute,
        onValueChanged: (minute) {
          // 分钟是最后一个单位，直接回调即可
          final newDate = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedDate.hour,
            minute,
          );
          // 这里不需要再调用 _handleDateChanged，因为它会再次触发约束检查，可能导致死循环
          // 我们相信前面的选择已经保证了分钟的范围是正确的
          setState(() {
            _selectedDate = newDate;
          });
          widget.onDateChanged(newDate);
        },
        itemBuilder:
            (context, value, isSelected) => _buildPickerItem(
              value.toString().padLeft(2, '0'),
              "分",
              isSelected,
            ),
      ),
    );
  }

  /// 辅助函数，判断两个DateTime是否在同一天
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 构建一个可点击的行，用于切换日期/时间选择器
  Widget _buildTapRow(String title, String textValue) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isTimeSelectorVisible = !_isTimeSelectorVisible;
        });
      },
      child: Container(
        color: Colors.white, // 扩大点击区域
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  textValue,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromRGBO(0, 0, 0, 0.4),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.keyboard_arrow_right,
                    color: Color.fromRGBO(0, 0, 0, 0.4),
                    size: 16.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分割线
  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: double.infinity,
      color: const Color(0xFFF5F5F5),
    );
  }

  /// 通用的 Picker Item 构建器
  // Widget _buildPickerItem(String value, String suffix, bool isSelected) {
  //   final Color textColor =
  //       isSelected ? const Color(0xFF3482FF) : Colors.black54;
  //   final FontWeight fontWeight =
  //       isSelected ? FontWeight.bold : FontWeight.normal;
  //   final double fontSize = isSelected ? 24 : 18;
  //
  //   return Center(
  //     child: FittedBox(
  //       fit: BoxFit.scaleDown,
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         crossAxisAlignment: CrossAxisAlignment.end,
  //         children: [
  //           Text(
  //             value,
  //             style: TextStyle(
  //               fontSize: fontSize,
  //               color: textColor,
  //               fontWeight: fontWeight,
  //             ),
  //           ),
  //           if (isSelected)
  //             Padding(
  //               padding: const EdgeInsets.only(left: 2),
  //               child: Text(
  //                 suffix,
  //                 style: const TextStyle(
  //                   fontSize: 12,
  //                   color: Color(0xFF3482FF),
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildPickerItem(String value, String suffix, bool isSelected) {
    final Color textColor =
        isSelected ? const Color(0xFF3482FF) : Colors.black54;
    final FontWeight fontWeight =
        isSelected ? FontWeight.bold : FontWeight.normal;
    final double fontSize = isSelected ? 24 : 18;

    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: fontSize,
                color: textColor,
                fontWeight: fontWeight,
              ),
            ),
            TextSpan(
              text: suffix,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
