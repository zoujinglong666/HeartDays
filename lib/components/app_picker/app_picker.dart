import 'package:flutter/material.dart';

class AppPicker {
  /// 显示单列选择器
  static void show<T>({
    required BuildContext context,
    required List<T> options,
    required ValueChanged<T> onConfirm,
    T? initialValue,
    String title = '请选择',
    String Function(T value)? labelBuilder,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _PickerBottomSheet<T>(
          options: options,
          title: title,
          initialValue: initialValue,
          labelBuilder: labelBuilder,
          onConfirm: onConfirm,
        );
      },
    );
  }
}

class _PickerBottomSheet<T> extends StatefulWidget {
  final List<T> options;
  final String title;
  final T? initialValue;
  final String Function(T value)? labelBuilder;
  final ValueChanged<T> onConfirm;

  const _PickerBottomSheet({
    required this.options,
    required this.title,
    required this.onConfirm,
    this.initialValue,
    this.labelBuilder,
  });

  @override
  State<_PickerBottomSheet<T>> createState() => _PickerBottomSheetState<T>();
}

class _PickerBottomSheetState<T> extends State<_PickerBottomSheet<T>> with SingleTickerProviderStateMixin {
  late FixedExtentScrollController _controller;
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialValue != null
        ? widget.options.indexOf(widget.initialValue!)
        : 0;
    if (_selectedIndex < 0) _selectedIndex = 0;
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);

    // 初始化动画控制器
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // 创建动画
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // 启动动画
    _animationController.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 处理点击选择
  void _handleItemTap(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _controller.animateToItem(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 处理确认
  void _handleConfirm() {
    _animationController.reverse().then((_) {
      widget.onConfirm(widget.options[_selectedIndex]);
      Navigator.of(context).pop();
    });
  }

  // 处理取消
  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemHeight = 42.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // 用 Transform.translate 实现底部弹出动画
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 300), // 300为弹出高度
          child: child,
        );
      },
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _handleCancel,
                    child: const Text('取消', style: TextStyle(color: Color(0xFF999999))),
                  ),
                  Text(widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Color(0xFF222222),
                      )),
                  TextButton(
                    onPressed: _handleConfirm,
                    child: const Text('确定', style: TextStyle(color: Color(0xFF3482ff), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F0F0)),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: itemHeight * 5,
                      child: ListWheelScrollView.useDelegate(
                        controller: _controller,
                        itemExtent: itemHeight,
                        diameterRatio: 100, // 极大值，近似平面
                        perspective: 0.001, // 非常小，近似无透视
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          setState(() => _selectedIndex = index);
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            if (index < 0 || index >= widget.options.length) return null;
                            final value = widget.options[index];
                            final label = widget.labelBuilder?.call(value) ?? value.toString();
                            final isSelected = index == _selectedIndex;
                            return GestureDetector(
                              onTap: () => _handleItemTap(index),
                              child: Container(
                                height: itemHeight,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF3482ff).withOpacity(0.08) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: isSelected ? 18 : 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xFF3482ff) : const Color(0xFF999999),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: widget.options.length,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}