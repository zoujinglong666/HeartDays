import 'package:flutter/material.dart';
import 'package:heart_days/pages/main_page.dart';
import 'package:flutter/services.dart';
void main() {
  // 设置沉浸式状态栏和底部导航栏颜色
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 沉浸式状态栏
      statusBarIconBrightness: Brightness.dark, // 深色图标（适合浅色背景）
      systemNavigationBarColor: Color(0xFFFCE4EC), // Android 底部导航栏颜色（粉色）
      systemNavigationBarIconBrightness: Brightness.dark, // 导航栏图标颜色
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});




  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '甜甜纪念日',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.transparent),
      ),
      home: MainPage(),
    );
  }
}

