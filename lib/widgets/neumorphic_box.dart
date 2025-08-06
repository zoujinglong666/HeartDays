import 'package:flutter/material.dart';
import 'package:heart_days/theme/neumorphic_theme.dart';

enum NeumorphicType {
  flat,
  pressed,
  convex,
  concave,
}

class NeumorphicBox extends StatefulWidget {
  final Widget? child;
  final double width;
  final double height;
  final double borderRadius;
  final Color color;
  final NeumorphicType type;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool hasShadow;
  final Gradient? gradient;

  const NeumorphicBox({
    Key? key,
    this.child,
    this.width = double.infinity,
    this.height = 60,
    this.borderRadius = 16.0,
    this.color = NeumorphicTheme.background,
    this.type = NeumorphicType.flat,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.all(0),
    this.onTap,
    this.hasShadow = true,
    this.gradient,
  }) : super(key: key);

  @override
  State<NeumorphicBox> createState() => _NeumorphicBoxState();
}

class _NeumorphicBoxState extends State<NeumorphicBox> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveType = _isPressed && widget.onTap != null
        ? NeumorphicType.pressed
        : widget.type;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      child: AnimatedContainer(
        duration: NeumorphicTheme.expandDuration,
        curve: NeumorphicTheme.expandCurve,
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding,
        decoration: _buildDecoration(effectiveType),
        child: widget.child,
      ),
    );
  }

  BoxDecoration _buildDecoration(NeumorphicType type) {
    // 基础阴影偏移和模糊半径
    final offset = 4.0;
    final blurRadius = 8.0;

    // 根据类型设置不同的装饰
    switch (type) {
      case NeumorphicType.flat:
        return BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: widget.gradient,
          boxShadow: widget.hasShadow
              ? [
                  BoxShadow(
                    color: widget.color.darken(0.1).withOpacity(0.5),
                    offset: Offset(offset, offset),
                    blurRadius: blurRadius,
                  ),
                  BoxShadow(
                    color: widget.color.brighten(0.1).withOpacity(0.5),
                    offset: Offset(-offset, -offset),
                    blurRadius: blurRadius,
                  ),
                ]
              : null,
        );

      case NeumorphicType.pressed:
        return BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: widget.gradient,
          boxShadow: widget.hasShadow
              ? [
                  BoxShadow(
                    color: widget.color.brighten(0.05).withOpacity(0.5),
                    offset: Offset(offset / 2, offset / 2),
                    blurRadius: blurRadius / 2,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: widget.color.darken(0.05).withOpacity(0.5),
                    offset: Offset(-offset / 2, -offset / 2),
                    blurRadius: blurRadius / 2,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        );

      case NeumorphicType.convex:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: widget.gradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.brighten(0.15),
                  widget.color.darken(0.15),
                ],
              ),
          boxShadow: widget.hasShadow
              ? [
                  BoxShadow(
                    color: widget.color.darken(0.1).withOpacity(0.5),
                    offset: Offset(offset, offset),
                    blurRadius: blurRadius,
                  ),
                  BoxShadow(
                    color: widget.color.brighten(0.1).withOpacity(0.5),
                    offset: Offset(-offset, -offset),
                    blurRadius: blurRadius,
                  ),
                ]
              : null,
        );

      case NeumorphicType.concave:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: widget.gradient ??
              LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.darken(0.15),
                  widget.color.brighten(0.15),
                ],
              ),
          boxShadow: widget.hasShadow
              ? [
                  BoxShadow(
                    color: widget.color.darken(0.1).withOpacity(0.5),
                    offset: Offset(offset, offset),
                    blurRadius: blurRadius,
                  ),
                  BoxShadow(
                    color: widget.color.brighten(0.1).withOpacity(0.5),
                    offset: Offset(-offset, -offset),
                    blurRadius: blurRadius,
                  ),
                ]
              : null,
        );
    }
  }
}

// 颜色扩展方法
extension ColorExtension on Color {
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Color brighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }
}

// 自定义Neumorphic复选框
class NeumorphicCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const NeumorphicCheckbox({
    Key? key,
    required this.value,
    this.onChanged,
    this.activeColor = NeumorphicTheme.accentColor,
    this.inactiveColor = NeumorphicTheme.background,
    this.size = 28.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: NeumorphicTheme.expandDuration,
        curve: NeumorphicTheme.expandCurve,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.15) : Colors.transparent,
          border: Border.all(
            color: value ? activeColor : inactiveColor.darken(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(size / 2),
          boxShadow: value
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: value
            ? Icon(
                Icons.check,
                color: activeColor,
                size: size * 0.7,
              )
            : null,
      ),
    );
  }
  }
