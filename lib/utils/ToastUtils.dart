import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class ToastUtils {
  // 取消当前显示的toast
  static void cancel() {
    Fluttertoast.cancel();
  }

  // 纯文本Toast
  static void showToast(String msg) {
    cancel();
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // 带图标的Toast，icon放左边，支持自定义背景和字体颜色
  static void showIconToast(
      String msg, {
        required IconData icon,
        Color backgroundColor = Colors.black87,
        Color textColor = Colors.white,
        ToastGravity gravity = ToastGravity.BOTTOM,
        int durationSeconds = 2,
      }) {
    cancel();
    Fluttertoast.showToast(
      msg: msg,
      toastLength: durationSeconds > 2 ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.0,
      // 直接使用 Fluttertoast 默认的 msg 方式不能内嵌图标，需用自定义 Widget 实现
      // 这里给出简单替代方案，带emoji的文本icon：
    );
  }

  // 下面是带图标的复杂Toast（需要自己引入第三方包flutter_overlay或用OverlayEntry实现）
  // 如果你想要真正带图标的toast弹窗，可以用如下思路：
  static void showCustomToast(
      BuildContext context,
      String msg, {
        IconData? icon,
        Color backgroundColor = Colors.black87,
        Color textColor = Colors.white,
        ToastGravity gravity = ToastGravity.BOTTOM,
        Duration duration = const Duration(seconds: 2),
      }) {
    cancel();
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(builder: (context) {
      return Positioned(
        bottom: gravity == ToastGravity.BOTTOM ? 50 : null,
        top: gravity == ToastGravity.TOP ? 50 : null,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(icon, color: textColor, size: 20),
                  ),
                Flexible(
                  child: Text(
                    msg,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });

    Overlay.of(context)?.insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry?.remove();
    });
  }
}
