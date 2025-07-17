import 'dart:math';
import 'package:flutter/material.dart';

enum EventType { birthday, festival, memorial, other }

class AnimatedProgressIndicator extends StatefulWidget {
  final double progress; // 0.0~1.0
  final double size;
  final double strokeWidth;
  final EventType eventType;
  final Duration duration;

  const AnimatedProgressIndicator({
    super.key,
    required this.progress,
    this.size = 36,
    this.strokeWidth = 3,
    this.eventType = EventType.other,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedProgressIndicator> createState() =>
      _AnimatedProgressIndicatorState();
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  late AnimationController _rotateController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(_rotateController);
  }

  @override
  void dispose() {
    _breathController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  List<Color> _getGradientColors() {
    switch (widget.eventType) {
      case EventType.birthday:
        return [
          const Color(0xFFFAD0C4),
          const Color(0xFFFFD1DC),
        ]; // 莫兰迪粉
      case EventType.festival:
        return [
          const Color(0xFFD1FAE5),
          const Color(0xFF6EE7B7),
        ]; // 低饱和绿色
      case EventType.memorial:
        return [
          const Color(0xFFFBE4C5),
          const Color(0xFFF5B78B),
        ]; // 柔和橘
      case EventType.other:
      default:
        return [
          const Color(0xFFFFFFFF),
          const Color(0xFFFFFFFF),
        ]; // 通用灰
    }
  }

  // List<Color> _getGradientColors() {
  //   switch (widget.eventType) {
  //     case EventType.birthday:
  //       return [
  //         const Color(0xFFFFE0EC), // 淡粉
  //         const Color(0xFFFF8FB1), // 莫兰迪桃
  //       ];
  //     case EventType.festival:
  //       return [
  //         const Color(0xFFE6FFF4), // 薄荷底
  //         const Color(0xFF5FE1B5), // 清新绿
  //       ];
  //     case EventType.memorial:
  //       return [
  //         const Color(0xFFFFF3E0), // 奶橙
  //         const Color(0xFFFFB87A), // 焦糖橘
  //       ];
  //     case EventType.other:
  //     default:
  //       return [
  //         const Color(0xFFE5F0FF), // 天蓝底
  //         const Color(0xFF84B6F4), // 莫兰迪蓝
  //       ];
  //   }
  // }



  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_breathAnimation, _rotationAnimation]),
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RotatingGradientArcPainter(
                  progress: widget.progress.clamp(0.0, 1.0),
                  strokeWidth: widget.strokeWidth,
                  colors: gradientColors,
                  opacity: _breathAnimation.value,
                  rotationAngle: _rotationAnimation.value,
                ),
              );
            },
          ),
          Text(
            '${(widget.progress * 100).toInt()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: widget.size * 0.3,
              color: gradientColors.last,
            ),
          ),
        ],
      ),
    );
  }
}

class _RotatingGradientArcPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;
  final double opacity;
  final double rotationAngle;

  _RotatingGradientArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.colors,
    required this.opacity,
    required this.rotationAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 背景圆
    final backgroundPaint = Paint()
      ..color = colors.last.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // 应用旋转变换
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    // 渐变弧
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2, // 完整圆
      colors: colors.map((c) => c.withOpacity(opacity)).toList(),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(rect, -pi / 2, sweepAngle, false, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RotatingGradientArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.colors != colors;
  }
}
