import 'package:flutter/material.dart';

class AnimatedGradientLinearProgress extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final double height;
  final Duration duration;
  final Color backgroundColor;
  final List<Color> gradientColors;
  final BorderRadius borderRadius;

  const AnimatedGradientLinearProgress({
    super.key,
    required this.value,
    this.height = 4,
    this.duration = const Duration(milliseconds: 600),
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.gradientColors = const [Color(0xFF4A90E2), Color(0xFF50E3C2)],
    this.borderRadius = const BorderRadius.all(Radius.circular(5)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      clipBehavior: Clip.hardEdge, // ✅ 正确裁剪方式
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: value.clamp(0.0, 1.0)),
        duration: duration,
        builder: (context, animatedValue, _) {
          return Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: animatedValue,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(height / 2), // ✅ 仅右端圆角
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
