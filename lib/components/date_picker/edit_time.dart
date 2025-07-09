import 'package:flutter/material.dart';
import 'package:heart_days/components/date_picker/picker_item.dart';
import 'custom_picker.dart';
/// 仅用于编辑时间（时、分）的组件
class EditTime extends StatefulWidget {
  final DateTime initialDate;
  final bool showLaterTime;
  final ValueChanged<Map<String, int>> onDateChanged;

  const EditTime({
    super.key,
    required this.initialDate,
    required this.showLaterTime,
    required this.onDateChanged,
  });

  @override
  State<EditTime> createState() => _EditTimeState();
}

class _EditTimeState extends State<EditTime> {
  late int _selectedHour;
  late int _selectedMinute;
  final DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 初始化时，根据 showLaterTime 约束初始值
    if (!widget.showLaterTime && widget.initialDate.isAfter(_now)) {
      _selectedHour = _now.hour;
      _selectedMinute = _now.minute;
    } else {
      _selectedHour = widget.initialDate.hour;
      _selectedMinute = widget.initialDate.minute;
    }
  }

  void _notifyChange() {
    widget.onDateChanged({
      "hour": _selectedHour,
      "minute": _selectedMinute,
    });
  }

  @override
  Widget build(BuildContext context) {
    // 动态计算分钟选择器的最大值
    int maxMinute = 59;
    if (!widget.showLaterTime && _selectedHour == _now.hour) {
      maxMinute = _now.minute;
    }

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // 小时选择器
          Expanded(
            child: CustomPicker(
              startValue: 0,
              endValue: widget.showLaterTime ? 23 : _now.hour,
              initialValue: _selectedHour,
              onValueChanged: (value) {
                setState(() {
                  _selectedHour = value;
                  // 当小时改变时，如果新的小时是当前小时，且分钟超过了当前分钟，则重置分钟
                  if (!widget.showLaterTime && _selectedHour == _now.hour && _selectedMinute > _now.minute) {
                    _selectedMinute = _now.minute;
                  }
                });
                _notifyChange();
              },
              itemBuilder: (context, value, isSelected) => pickerItem(
                value.toString().padLeft(2, '0'),
                "时",
                isSelected,
              ),
            ),
          ),
          // 分钟选择器
          Expanded(
            child: CustomPicker(
              startValue: 0,
              endValue: maxMinute,
              initialValue: _selectedMinute,
              onValueChanged: (value) {
                setState(() {
                  _selectedMinute = value;
                });
                _notifyChange();
              },
              itemBuilder: (context, value, isSelected) => pickerItem(
                value.toString().padLeft(2, '0'),
                "分",
                isSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }


}
