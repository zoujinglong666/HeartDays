import 'package:flutter/material.dart';

class ComContainer extends StatelessWidget {
  final Widget? child;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? radius;
  final double elevation;
  final Color? shadowColor;
  final DecorationImage? image;
  final BoxDecoration? decoration;

  const ComContainer({
    super.key,
    this.child,
    this.alignment,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.margin,
    this.elevation = 0,
    this.image,
    this.decoration,
    this.shadowColor,
    this.radius = 4, // ✅ 设置默认圆角
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: decoration ?? _getDefaultDecoration(context),
      child: child,
    );
  }

  BoxDecoration _getDefaultDecoration(BuildContext context) {
    return BoxDecoration(
      color: color ?? Colors.white, // 将这里从 Theme.of(context).colorScheme.surfaceContainer 改为 Colors.white
      image: image,
      borderRadius: radius != null ? BorderRadius.circular(radius!) : null,
      boxShadow: elevation > 0
          ? [
        BoxShadow(
          color: shadowColor ?? Theme.of(context).colorScheme.shadow,
          blurRadius: elevation,
        )
      ]
          : [],
    );
  }
}
