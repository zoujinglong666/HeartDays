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

  static CancelFunc showNotification({
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
}
