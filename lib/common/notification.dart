import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:bot_toast/bot_toast.dart';

class MyNotification {
  MyNotification._();

  static CancelFunc showNotification({
    String? title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    assert(title != null || subtitle != null);

    return BotToast.showCustomNotification(
      crossPage: true,
      duration: const Duration(seconds: 6),
      align: Alignment.topCenter,
      toastBuilder: (cancel) {
        return GestureDetector(
          onTap: () {
            cancel();
            onTap?.call();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: _AnimatedBorderContainer(
              onClose: () {
                cancel();
                onClose?.call();
              },
              title: title,
              subtitle: subtitle,
              leading: leading,
              trailing: trailing,
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedBorderContainer extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onClose;

  const _AnimatedBorderContainer({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onClose,
  });

  @override
  State<_AnimatedBorderContainer> createState() =>
      _AnimatedBorderContainerState();
}

class _AnimatedBorderContainerState extends State<_AnimatedBorderContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              // ✅ 把 CustomPaint 提到最外层
              painter: _ShimmerBorderPainter(progress: _controller.value),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.20),
                      Colors.white.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null)
                            Text(
                              widget.title!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          if (widget.subtitle != null)
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 10),
                      widget.trailing!,
                    ],
                    GestureDetector(
                      onTap: widget.onClose,
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShimmerBorderPainter extends CustomPainter {
  final double progress;

  _ShimmerBorderPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // ✅ 动态渐变光泽沿整个外框旋转
    final gradient = SweepGradient(
      startAngle: 0,
      endAngle: 6.28318, // 2π
      colors: [
        Colors.white.withOpacity(0.0),
        Colors.white.withOpacity(0.8),
        Colors.white.withOpacity(0.0),
      ],
      stops: [
        (progress - 0.15).clamp(0.0, 1.0),
        progress,
        (progress + 0.15).clamp(0.0, 1.0),
      ],
      transform: GradientRotation(progress * 6.28318),
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect.inflate(0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
