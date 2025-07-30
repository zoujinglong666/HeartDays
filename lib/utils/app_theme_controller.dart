import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppThemeController {
  static final AppThemeController _instance = AppThemeController._internal();

  factory AppThemeController() => _instance;

  AppThemeController._internal();

  /// 应用默认色
  final Color defaultPrimary = const Color(0xFF5C6BC0); // 靛蓝色

  /// 设置系统状态栏 + 底部导航栏样式
  void setSystemUI({
    Color? statusBarColor,
    Brightness statusBarIconBrightness = Brightness.dark,
    Color? navBarColor,
    Brightness navBarIconBrightness = Brightness.dark,
  }) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: statusBarColor ?? Colors.transparent,
      statusBarIconBrightness: statusBarIconBrightness,
      systemNavigationBarColor: navBarColor ?? Colors.transparent,
      systemNavigationBarIconBrightness: navBarIconBrightness,
    ));
  }

  /// 快速设置为透明沉浸（适合大部分页面）
  void setTransparentUI({bool darkIcons = true}) {
    setSystemUI(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
      navBarColor: Colors.transparent,
      navBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
    );
  }

  /// 快速设置为浅色背景风格
  void setLightUI({Color? navBarColor}) {
    setSystemUI(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      navBarColor: navBarColor ?? Colors.white,
      navBarIconBrightness: Brightness.dark,
    );
  }

  /// 快速设置为深色背景风格
  void setDarkUI({Color? navBarColor}) {
    setSystemUI(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      navBarColor: navBarColor ?? Colors.black,
      navBarIconBrightness: Brightness.light,
    );
  }
}
