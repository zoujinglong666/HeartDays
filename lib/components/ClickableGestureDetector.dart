import 'package:flutter/material.dart';

class ClickableGestureDetector extends StatelessWidget {
  final Widget child;
  final GestureTapCallback? onTap;
  final ValueChanged<bool>? onLongPress;
  final ValueChanged<bool> onHandle;
  final HitTestBehavior? behavior;

  const ClickableGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    required this.onHandle,
    this.behavior = HitTestBehavior.translucent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: behavior,
      onTapDown: (details) => onHandle.call(true),
      onTapCancel: () => onHandle.call(false),
      onTapUp: (details) {
        // 由于“点击”这个动作发生的太快了
        // 导致“按下”和“抬起”这两个动作衔接的太快
        // 因此在做组件样式变化的时候可能观测不到，因此可以在“抬起”时延迟一点事件再执行相关逻辑
        // 这样有了“一定时间间隔”以后，我们就能从肉眼上观测到这个样式变化了
        Future.delayed(const Duration(milliseconds: 100), () {
          onHandle.call(false);
          onTap?.call();
        });
      },
      onLongPressStart: (details) {
        onHandle.call(true);
        onLongPress?.call(true);
      },
      onLongPressEnd: (details) {
        onHandle.call(false);
        onLongPress?.call(false);
      },
      child: child,
    );
  }
}
