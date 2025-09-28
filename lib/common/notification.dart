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
            constraints: const BoxConstraints(
              maxHeight: 80,  // 限制最大高度
              maxWidth: 350,  // 限制最大宽度
            ),
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

  /// 微信风格通知 - 类似图片中的效果
  static CancelFunc showWeChatStyleNotification({
    required String appName,
    required String message,
    String? avatar,
    String? time,
    VoidCallback? onTap,
    VoidCallback? onClose,
    Duration duration = const Duration(seconds: 5),
  }) {
    return BotToast.showCustomNotification(
      crossPage: true,
      duration: duration,
      align: Alignment.topCenter,
      toastBuilder: (cancel) {
        return GestureDetector(
          onTap: () {
            cancel();
            onTap?.call();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            constraints: const BoxConstraints(
              maxHeight: 80,  // 限制最大高度
              maxWidth: 350,  // 限制最大宽度
            ),
            child: _WeChatNotificationCard(
              appName: appName,
              message: message,
              avatar: avatar,
              time: time ?? '现在',
              onClose: () {
                cancel();
                onClose?.call();
              },
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
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (widget.subtitle != null)
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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

/// 微信风格通知卡片
class _WeChatNotificationCard extends StatefulWidget {
  final String appName;
  final String message;
  final String? avatar;
  final String time;
  final VoidCallback? onClose;

  const _WeChatNotificationCard({
    super.key,
    required this.appName,
    required this.message,
    this.avatar,
    required this.time,
    this.onClose,
  });

  @override
  State<_WeChatNotificationCard> createState() => _WeChatNotificationCardState();
}

class _WeChatNotificationCardState extends State<_WeChatNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 应用图标
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: widget.avatar != null
                              ? Image.network(
                                  widget.avatar!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultIcon();
                                  },
                                )
                              : _buildDefaultIcon(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 内容区域
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 应用名称和时间
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.appName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.time,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            // 消息内容 - 只显示一行
                            Text(
                              widget.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.2,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1, // 只显示一行
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultIcon() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF07C160),
            Color(0xFF05A050),
          ],
        ),
      ),
      child: const Icon(
        Icons.chat_bubble_rounded,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
