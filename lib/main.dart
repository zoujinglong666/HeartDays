import 'package:flutter/material.dart';
import 'package:heart_days/pages/main_page.dart';
import 'package:heart_days/pages/login_page.dart';
import 'package:flutter/services.dart';

void main() {
  // 沉浸状态栏 + 底部导航栏
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent, // 设置为透明
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // // 延迟设置 UI 模式，避免底部保留白条
  // SystemChrome.setEnabledSystemUIMode(
  //   SystemUiMode.edgeToEdge, // 启用沉浸式底部栏
  // );

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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/main': (context) => MainPage(),
      },
    );
  }
}

