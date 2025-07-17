// date_picker.dart

import 'package:flutter/material.dart';
import 'dart:ui'; // 导入 dart:ui 以使用 ImageFilter
import 'edit_date.dart';
import 'edit_time.dart';
import 'filter_date.dart';
// import 'package:time_picker/utils/logger.dart'; // 假设的日志工具

/// 定义选择器的几种工作模式
enum AppDatePickerMode {
  /// 编辑完整日期和时间
  editDate,
  /// 按 周/月/年 筛选
  filterDate,
  /// 仅编辑时间（时:分）
  editTime,
  /// 编辑开始日期（年月日）
  startTime,
  /// 编辑结束日期（年月日）
  endTime,
}

/// 定义筛选器的类型
enum FilterType { week, month, year }

/// Builder function for custom week item UI.
/// [context] - The build context.
/// [weekData] - The raw string data for the week (e.g., "2024.01.01~2024.01.07(本周)").
/// [isSelected] - Whether this item is currently selected.
//  为 weekItemBuilder 定义一个清晰的类型别名
typedef WeekItemBuilder = Widget Function(BuildContext context, String weekData, bool isSelected);

/// 一个封装好的应用级日期选择器，通过静态方法 `show` 来调用。
class AppDatePicker {
  /// 显示日期选择器浮层
  ///
  /// @param context - BuildContext
  /// @param mode - 选择器模式，决定了UI和行为
  /// @param onConfirm - 点击"确定"按钮的回调，返回选择结果
  /// @param filterType - 当 mode 为 filterDate 时，指定筛选类型（周/月/年）
  /// @param initialDateTime - 初始显示的日期时间，默认为当前时间
  /// @param startTime - 可选的最小开始时间，用于限制选择范围
  /// @param weekItemBuilder - week子组件渲染函数
  /// @param title - 定制title
  /// @param yearsBack - 在筛选模式下，从当前年份回溯的年数
  /// @param showLaterTime - 是否允许选择未来的时间，默认为 true
  /// @param onChange - （可选）当选择值变化时的实时回调
  /// @param onCancel - （可选）点击"取消"或遮罩时的回调
  static void show({
    required BuildContext context,
    required AppDatePickerMode mode,
    required Function(dynamic) onConfirm,
    String? title, // 添加可选的自定义标题参数
    WeekItemBuilder? weekItemBuilder, // 添加可选的自定义周UI构建器
    FilterType? filterType,
    DateTime? initialDateTime,
    DateTime? startTime,
    int? yearsBack,
    bool? showLaterTime,
    Color? primaryColor, // ✅ 新增：主题色参数
    Function(dynamic)? onChange,
    Function()? onCancel,
  }) {
    OverlayState overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          color: Colors.transparent,
          child: DatePickerOverlay(
            mode: mode,
            title: title, // [MODIFIED] 传递 title
            weekItemBuilder: weekItemBuilder, // [MODIFIED] 传递 weekItemBuilder
            initialDateTime: initialDateTime ?? DateTime.now(),
            onChange: onChange ?? (_) {},
            filterType: filterType ?? FilterType.week,
            yearsBack: yearsBack ?? 3,
            startTime: startTime,
            showLaterTime: showLaterTime ?? true,
            onConfirm: (selectedTime) {
              onConfirm(selectedTime);
              overlayEntry.remove();
            },
            onCancel: () {
              onCancel?.call();
              overlayEntry.remove();
            },
          ),
        );
      },
    );
    overlayState.insert(overlayEntry);
  }
}

/// 日期选择器的浮层UI和状态管理
class DatePickerOverlay extends StatefulWidget {
  final AppDatePickerMode mode;
  final DateTime initialDateTime;
  final DateTime? startTime;
  final FilterType filterType;
  final int yearsBack;
  final String? title; // [NEW]
  final WeekItemBuilder? weekItemBuilder; // [NEW]
  final bool showLaterTime;
  final Function(dynamic) onChange;
  final Function(dynamic) onConfirm;
  final Function() onCancel;

  const DatePickerOverlay({
    super.key,
    required this.mode,
    required this.initialDateTime,
    required this.onChange,
    required this.onConfirm,
    required this.onCancel,
    required this.showLaterTime,
    this.title, // [NEW]
    this.weekItemBuilder, // [NEW]
    this.startTime,
    this.filterType = FilterType.week,
    this.yearsBack = 3,
  });

  @override
  State<DatePickerOverlay> createState() => _DatePickerOverlayState();
}

class _DatePickerOverlayState extends State<DatePickerOverlay> with SingleTickerProviderStateMixin {
  // 用于存储 editDate, startTime, endTime 模式下的选择结果
  late DateTime _selectedDateTime;
  // 用于存储 filterDate, editTime 模式下的选择结果
  late dynamic _selectionResult;
  // 添加动画控制器
  late AnimationController _animationController;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
    _initializeSelectionResult();

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 创建从底部弹出的动画
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // 启动动画
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    // 添加关闭动画
    _animationController.reverse().then((_) {
      widget.onConfirm(_selectionResult);
    });
  }

  /// 处理取消按钮点击事件
  void _handleCancel() {
    // 添加关闭动画
    _animationController.reverse().then((_) {
      widget.onCancel();
    });
  }


  /// 根据不同的模式初始化 `_selectionResult`
  void _initializeSelectionResult() {
    switch (widget.mode) {
      case AppDatePickerMode.filterDate:
        if (widget.filterType == FilterType.year) {
          _selectionResult = {"year": _selectedDateTime.year};
        } else if (widget.filterType == FilterType.month) {
          _selectionResult = {"year": _selectedDateTime.year, "month": _selectedDateTime.month};
        } else { // week
          // 需要一个工具函数来获取初始日期所在的周
          // 这里暂时用 initialDateTime 模拟，实际应在 FilterDate 中处理
          _selectionResult = {
            "startTime": _selectedDateTime,
            "endTime": _selectedDateTime,
          };
        }
        break;
      case AppDatePickerMode.editTime:
        _selectionResult = {"hour": _selectedDateTime.hour, "minute": _selectedDateTime.minute};
        break;
      default:
        _selectionResult = _selectedDateTime;
        break;
    }
  }

  /// 处理来自子组件的值变化
  void _onValueChanged(dynamic value) {
    setState(() {
      if (value is DateTime) {
        _selectedDateTime = value;
      }
      _selectionResult = value;
    });
    widget.onChange(value);
  }

  /// 根据模式获取选择器的标题
  String _getPickerTitle() {
    if (widget.title != null) {
      return widget.title!;
    }
    // 如果没有提供自定义标题，则使用默认逻辑
    switch (widget.mode) {
      case AppDatePickerMode.editDate:
        return "编辑日期";
      case AppDatePickerMode.filterDate:
        return "筛选时间";
      case AppDatePickerMode.editTime:
        return "编辑时间";
      case AppDatePickerMode.startTime:
        return "编辑开始时间";
      case AppDatePickerMode.endTime:
        return "编辑结束时间";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 半透明遮罩，使用动画控制透明度，添加模糊效果
        // Positioned.fill(
        //   child: GestureDetector(
        //     onTap: _handleCancel,
        //     child: AnimatedBuilder(
        //       animation: _animation,
        //       builder: (context, child) {
        //         final opacity = _animation.value;
        //         return Container(
        //           color: Colors.black.withOpacity(0.3 * opacity),
        //           child: Container(
        //             decoration: BoxDecoration(
        //               gradient: LinearGradient(
        //                 begin: Alignment.topCenter,
        //                 end: Alignment.bottomCenter,
        //                 colors: [
        //                   Colors.black.withOpacity(0.2 * opacity),
        //                   Colors.black.withOpacity(0.5 * opacity),
        //                 ],
        //               ),
        //             ),
        //           ),
        //         );
        //       },
        //     ),
        //   ),
        // ),

        Positioned.fill(
          child: GestureDetector(
            onTap: _handleCancel,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4 * _animation.value),
                        Colors.black.withOpacity(0.6 * _animation.value),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // 主内容面板，使用动画控制位置
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Positioned(
              bottom: _animation.value * 0 + (1 - _animation.value) * (-300), // 从-300位置移动到0位置
              left: 0,
              right: 0,
              child: child!,
            );
          },
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      _getPickerTitle(),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                  _buildPickerContent(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 根据模式构建不同的选择器内容
  Widget _buildPickerContent() {
    switch (widget.mode) {
      case AppDatePickerMode.editDate:
        return EditDate(
          initialDate: _selectedDateTime,
          showLaterTime: widget.showLaterTime,
          showMoment: true,
          onDateChanged: _onValueChanged,
        );
      case AppDatePickerMode.startTime:
        return EditDate(
          initialDate: _selectedDateTime,
          showLaterTime: widget.showLaterTime,
          showMoment: false, // 开始时间不需要选时刻
          onDateChanged: _onValueChanged,
        );
      case AppDatePickerMode.endTime:
        return EditDate(
          initialDate: _selectedDateTime,
          showLaterTime: widget.showLaterTime,
          startTime: widget.startTime, // 传入开始时间以作限制
          showMoment: false, // 结束时间不需要选时刻
          onDateChanged: _onValueChanged,
        );
      case AppDatePickerMode.filterDate:
        return FilterDate(
          type: widget.filterType,
          initialDate: _selectedDateTime,
          yearsBack: widget.yearsBack,
          showLaterTime: widget.showLaterTime,
          onDateChanged: _onValueChanged,
          weekItemBuilder: widget.weekItemBuilder,
        );
      case AppDatePickerMode.editTime:
        return EditTime(
          initialDate: _selectedDateTime,
          showLaterTime: widget.showLaterTime,
          onDateChanged: _onValueChanged,
        );
    }
  }

  /// 构建底部的"取消"和"确定"按钮
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0XFFF0F0F0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            onPressed: _handleCancel,
            child: const Text("取消",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF42A5F5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            onPressed: _onConfirm,
            child: const Text("确定",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}