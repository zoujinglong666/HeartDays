import 'package:flutter/material.dart';
import 'package:heart_days/components/ClickableGestureDetector.dart';

/// 自定义可点击效果构建器
typedef ClickableBuilder = Widget Function(WidgetState? state, Widget child);
class Clickable extends StatefulWidget {
  final Widget child;
  final bool disabled;
  final bool clickable;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onLongPress;

  // 一、颜色变化（次优先级）
  final Color? color;
  final Color? pressedColor;
  final Color? disabledColor;

  // 二、透明度变化（默认效果，优先级最低）
  final double opacity;
  final double pressedOpacity;
  final double disabledOpacity;

  // 三、自定义（优先级最高，如设置则优先使用）
  final ClickableBuilder? builder;

  const Clickable({
    super.key,
    required this.child,
    this.disabled = false,
    this.clickable = true,
    this.onTap,
    this.onLongPress,
    this.color,
    this.pressedColor,
    this.disabledColor,
    this.opacity = 1.0,
    this.pressedOpacity = 0.6,
    this.disabledOpacity = 0.4,
    this.builder,
  });

  @override
  State<StatefulWidget> createState() => _ClickableState();
}

class _ClickableState extends State<Clickable> {
  WidgetState? _state;
  late bool _disabled;
  late bool _clickable;
  late bool _withColor;
  late ClickableBuilder builder;

  @override
  void initState() {
    super.initState();
    _initAttrs();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = builder.call(_state, widget.child);
    if (_disabled || !_clickable) {
      return child;
    }
    return ClickableGestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onHandle: _onHandle,
      child: child,
    );
  }

  @override
  void didUpdateWidget(covariant Clickable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clickable != widget.clickable ||
        oldWidget.disabled != widget.disabled ||
        oldWidget.color != widget.color ||
        oldWidget.disabledColor != widget.disabledColor ||
        oldWidget.disabledOpacity != widget.disabledOpacity ||
        oldWidget.builder != widget.builder) {
      _initAttrs();
    }
  }

  void _onHandle(bool active) {
    setState(() => _state = active ? WidgetState.pressed : null);
  }

  void _initAttrs() {
    _disabled = widget.disabled;
    _clickable = widget.clickable;
    _withColor = widget.color != null;
    _state = widget.disabled ? WidgetState.disabled : null;
    builder = widget.builder == null
        ? (_withColor ? _withColorBuilder : _withOpacityBuilder)
        : widget.builder!;
  }

  /// 效果一：颜色变化构建器
  /// 通过改变组件的背景颜色达到效果反馈的目的
  Widget _withColorBuilder(WidgetState? state, Widget child) {
    Color color = widget.color!;
    if (state == WidgetState.pressed) {
      if (widget.pressedColor != null) {
        color = widget.pressedColor!;
      } else if (widget.pressedOpacity != null) {
        color = color.withOpacity(widget.pressedOpacity!);
      }
    } else if (state == WidgetState.disabled) {
      if (widget.disabledColor != null) {
        color = widget.disabledColor!;
      } else if (widget.disabledOpacity != null) {
        color = color.withOpacity(widget.disabledOpacity!);
      }
    }
    return ColoredBox(color: color, child: child);
  }

  /// 效果二：透明度变化构建器
  /// 通过改变组件的透明度达到效果反馈的目的
  Widget _withOpacityBuilder(WidgetState? state, Widget child) {
    final opacity = state == WidgetState.pressed
        ? widget.pressedOpacity
        : (state == WidgetState.disabled
        ? widget.disabledOpacity
        : widget.opacity);
    return Opacity(opacity: opacity, child: child);
  }
}