import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 一个通用的、可自定义列表项的滚动选择器组件。
/// 它基于 `ListWheelScrollView` 构建，并将 item 的构建委托给外部。
class CustomPicker extends StatefulWidget {
  /// 滚动列表的起始数值
  final int startValue;
  /// 滚动列表的结束数值
  final int endValue;
  /// 选择器的初始值
  final int initialValue;
  /// 当选项发生变化时的回调函数
  final ValueChanged<int> onValueChanged;
  /// 自定义列表项的构建器。
  /// 参数：(BuildContext context, int value, bool isSelected)
  /// `value` 是当前项的数值，`isSelected` 表示当前项是否被选中。
  final Widget Function(BuildContext context, int value, bool isSelected) itemBuilder;

  const CustomPicker({
    super.key,
    required this.startValue,
    required this.endValue,
    required this.initialValue,
    required this.onValueChanged,
    required this.itemBuilder,
  });

  @override
  State<CustomPicker> createState() => _CustomPickerState();
}

class _CustomPickerState extends State<CustomPicker> {
  late FixedExtentScrollController _scrollController;
  // 当前在 UI 上选中的值，用于比较和触发更新
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
    // 初始化滚动控制器，使其定位到 initialValue 对应的索引
    _scrollController = FixedExtentScrollController(
      initialItem: _calculateInitialItem(),
    );
  }

  /// 计算初始选中项的索引
  int _calculateInitialItem() {
    // 确保 initialValue 在 [startValue, endValue] 范围内
    final value = widget.initialValue.clamp(widget.startValue, widget.endValue);
    return value - widget.startValue;
  }

  @override
  void didUpdateWidget(CustomPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当父组件更新了 initialValue, startValue 或 endValue 时，
    // 我们需要检查是否需要更新滚动位置。
    if (widget.initialValue != oldWidget.initialValue ||
        widget.startValue != oldWidget.startValue ||
        widget.endValue != oldWidget.endValue) {

      // 更新内部选中的值
      _selectedValue = widget.initialValue;

      // 计算新的目标索引
      final targetItem = _calculateInitialItem();

      // 使用 addPostFrameCallback 确保在 build 完成后执行跳转，避免冲突
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && _scrollController.selectedItem != targetItem) {
          _scrollController.jumpToItem(targetItem);
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 列表中的总项目数
    final int itemCount = widget.endValue - widget.startValue + 1;
    return SizedBox(
      height: 120,
      child: Center(
        child: ListWheelScrollView.useDelegate(
          controller: _scrollController,
          itemExtent: 40, // 每一项的高度
          physics: const FixedExtentScrollPhysics(),
          magnification: 1.0,
          useMagnifier: false,
          overAndUnderCenterOpacity: 0.5, // 上下未选中项的透明度
          perspective: 0.01, // 轻微的3D透视效果
          onSelectedItemChanged: (index) {
            // 当用户滚动选择时，计算新的值
            final newValue = widget.startValue + index;
            // 🚀 增加滚动时的震动反馈
            HapticFeedback.selectionClick();
            // 更新内部状态以触发UI重建（例如，选中项的样式变化）
            setState(() {
              _selectedValue = newValue;
            });
            // 通过回调通知父组件值的变化
            widget.onValueChanged(newValue);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            builder: (context, index) {
              // 避免在滚动范围之外构建 widget
              if (index < 0 || index >= itemCount) {
                return const SizedBox.shrink();
              }
              // 计算当前索引对应的真实数值
              final int value = widget.startValue + index;
              // 判断当前项是否为选中项
              final bool isSelected = (value == _selectedValue);
              // 使用外部传入的 itemBuilder 来构建列表项的 UI
              return widget.itemBuilder(context, value, isSelected);
            },
            childCount: itemCount,
          ),
        ),
      ),
    );
  }
}
