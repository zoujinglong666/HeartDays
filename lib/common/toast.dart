import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

class MyToast {
  MyToast._();

  static CancelFunc showSuccess(
      String message, {
        Icon? icon,
        Alignment? align,
        Duration? duration,
      }) {
    return showToast(
      message,
      align: align,
      duration: duration,
      icon: icon ?? const Icon(Icons.check_circle, color: Colors.white),
      iconBackgroundColor: Colors.green,
    );
  }

  static CancelFunc showInfo(
      String message, {
        Icon? icon,
        Alignment? align,
        Duration? duration,
      }) {
    return showToast(
      message,
      align: align,
      duration: duration,
      icon: icon ?? const Icon(Icons.info, color: Colors.white),
      iconBackgroundColor: Colors.blueAccent,
    );
  }

  static CancelFunc showWarning(
      String message, {
        Icon? icon,
        Alignment? align,
        Duration? duration,
      }) {
    return showToast(
      message,
      align: align,
      duration: duration,
      icon: icon ?? const Icon(Icons.warning, color: Colors.white),
      iconBackgroundColor: Colors.orange,
    );
  }

  static CancelFunc showError(
      String message, {
        Icon? icon,
        Alignment? align,
        Duration? duration,
      }) {
    return showToast(
      message,
      align: align,
      duration: duration,
      icon: icon ?? const Icon(Icons.error, color: Colors.white),
      iconBackgroundColor: Colors.red,
    );
  }

  static CancelFunc showToast(
      String message, {
        Icon? icon,
        Color? textColor,
        Color? iconBackgroundColor,
        Alignment? align,
        Duration? duration,
        VoidCallback? onClose,
      }) {
    return BotToast.showCustomText(
      onlyOne: true,
      crossPage: false,
      onClose: onClose,
      align: align ?? const Alignment(0.0, 0.85), // 底部
      duration: duration ?? const Duration(seconds: 3),
      toastBuilder: (cancel) {
        final List<Widget> items = [];

        if (icon != null) {
          items.add(Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? Colors.black12,
              borderRadius: BorderRadius.circular(50),
            ),
            child: icon,
          ));
        }

        items.add(Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: icon == null ? 5 : 0,
            ),
            child: Text(
              message,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: textColor ?? Colors.black87),
              strutStyle: const StrutStyle(leading: 0, forceStrutHeight: true),
            ),
          ),
        ));

        return Container(
          padding: const EdgeInsets.all(5),
          margin: const EdgeInsets.only(left: 10, right: 10, bottom: 20), // 底部增加间距
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: items,
          ),
        );
      },
    );
  }


  // static CancelFunc showToast(
  //     String message, {
  //       Icon? icon,
  //       Color? textColor,
  //       Color? iconBackgroundColor,
  //       Alignment? align,
  //       Duration? duration,
  //       VoidCallback? onClose,
  //     }) {
  //
  //   return BotToast.showCustomText(
  //     onlyOne: true,
  //     crossPage: false,
  //     onClose: onClose,
  //     align: align ?? const Alignment(0.0, -0.85),
  //     duration: duration ?? const Duration(seconds: 3),
  //     toastBuilder: (cancel) {
  //       final List<Widget> items = [];
  //
  //       if (icon != null) {
  //         items.add(Container(
  //           padding: const EdgeInsets.all(3),
  //           decoration: BoxDecoration(
  //             color: iconBackgroundColor ?? Colors.black12,
  //             borderRadius: BorderRadius.circular(50),
  //           ),
  //           child: icon,
  //         ));
  //       }
  //
  //       items.add(Flexible(
  //         child: Padding(
  //           padding: EdgeInsets.symmetric(
  //             horizontal: 10,
  //             vertical: icon == null ? 5 : 0,
  //           ),
  //           child: Text(
  //             message,
  //             overflow: TextOverflow.ellipsis,
  //             style: TextStyle(fontSize: 14, color: textColor ?? Colors.black87),
  //             strutStyle: const StrutStyle(leading: 0, forceStrutHeight: true),
  //           ),
  //         ),
  //       ));
  //
  //       return Container(
  //         padding: const EdgeInsets.all(5),
  //         margin: const EdgeInsets.only(left: 10, right: 10),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(50),
  //           boxShadow: const [
  //             BoxShadow(
  //               color: Colors.black12,
  //               blurRadius: 5,
  //               offset: Offset(0, 3),
  //             ),
  //           ],
  //         ),
  //         child: Row(
  //           mainAxisSize: MainAxisSize.min,
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           crossAxisAlignment: CrossAxisAlignment.center,
  //           children: items,
  //         ),
  //       );
  //     },
  //   );
  // }

  static CancelFunc showLoading({
    String? placeholder,
    VoidCallback? onClose,
    Widget? loadingWidget,
    Duration? duration,
  }) {
    loadingWidget ??= const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: Colors.redAccent,
      ),
    );
    return BotToast.showCustomLoading(
      crossPage: false,
      clickClose: true,
      ignoreContentClick: false,
      backgroundColor: Colors.black12,
      onClose: onClose,
      duration: duration ?? const Duration(seconds: 3),
      toastBuilder: (cancel) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              loadingWidget!,
              const SizedBox(height: 6),
              Text(
                placeholder ?? "加载中",
                style: const TextStyle(fontSize: 14, color: Colors.redAccent),
              ),
            ],
          ),
        );
      },
    );
  }

  static CancelFunc showNotification1({
    String? title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    assert(title != null || subtitle != null);
    return BotToast.showNotification(
      crossPage: true,
      borderRadius: 6.0,
      duration: const Duration(seconds: 10),
      margin: const EdgeInsets.only(left: 10, right: 10),
      leading: leading == null ? null : (_) => leading,
      trailing: trailing == null ? null : (_) => trailing,
      title: (_) => Text(
        (title ?? subtitle)!,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: subtitle == null
          ? null
          : (_) => Text(
        subtitle,
        style: const TextStyle(fontSize: 14),
      ),
      onTap: onTap,
      onClose: onClose,
    );
  }

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    // 背景渐变：微亮+轻透
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.20),
                        Colors.white.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    // 细高光边框
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 0.8,
                    ),
                    // 阴影 & 内层描边
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      // 顶部轻微高光
                      BoxShadow(
                        color: Colors.white.withOpacity(0.25),
                        blurRadius: 0.5,
                        spreadRadius: -0.5,
                        offset: const Offset(-0.5, -0.5),
                      ),
                      // 底部轻微暗边
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 0.5,
                        spreadRadius: -0.5,
                        offset: const Offset(0.8, 0.8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        leading,
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title != null)
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: 10),
                        trailing,
                      ],
                      GestureDetector(
                        onTap: () {
                          cancel();
                          onClose?.call();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close, size: 18, color: Colors.white),
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





  /// iOS 16 风格液态玻璃通知卡片
  /// 返回 CancelFunc 可随时关闭
  static CancelFunc showNotification3({
    String? title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onClose,
    Duration duration = const Duration(seconds: 6),
  }) {
    assert(title != null || subtitle != null);

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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    // 半透明白色渐变（亮/暗自动切换）
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.20),
                        Colors.white.withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    // 高光描边 + 外发光
                    border: Border.all(
                      color: Colors.white.withOpacity(0.30),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.15),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 左侧图标占位 36 px
                      if (leading != null) ...[
                        SizedBox.square(dimension: 36, child: leading),
                        const SizedBox(width: 12),
                      ] else
                        const SizedBox(width: 4),
                      // 标题 + 副标题
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (title != null)
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            if (subtitle != null)
                              Text(
                                subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                  letterSpacing: -0.08,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // 右侧关闭按钮
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing,
                      ],
                      GestureDetector(
                        onTap: () {
                          cancel();
                          onClose?.call();
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
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





}







