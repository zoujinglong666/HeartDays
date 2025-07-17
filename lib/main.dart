import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:heart_days/pages/SplashPage.dart';
import 'package:heart_days/pages/main_page.dart';
import 'package:heart_days/pages/login_page.dart';
import 'package:flutter/services.dart';
import 'package:heart_days/utils/navigation_service.dart';
void main() {
  // 沉浸状态栏 + 底部导航栏
  // SystemChrome.setSystemUIOverlayStyle(
  //   const SystemUiOverlayStyle(
  //     statusBarColor: Colors.transparent,
  //     statusBarIconBrightness: Brightness.dark,
  //     systemNavigationBarColor: Colors.transparent, // 设置为透明
  //     systemNavigationBarIconBrightness: Brightness.dark,
  //   ),
  // );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white, // 白色背景
      statusBarIconBrightness: Brightness.dark, // 状态栏图标颜色：深色
      statusBarBrightness: Brightness.light, // iOS状态栏文字颜色，和Android相反
      systemNavigationBarColor: Colors.white, // 导航栏白色（可选）
      systemNavigationBarIconBrightness: Brightness.dark, // 导航栏图标深色（可选）
    ),
  );

  // // 延迟设置 UI 模式，避免底部保留白条
  // SystemChrome.setEnabledSystemUIMode(
  //   SystemUiMode.edgeToEdge, // 启用沉浸式底部栏
  // );
  // 注册拦截器

  // ✅ 监听 Token 过期事件
  eventBus.on<TokenExpiredEvent>().listen((event) {
    print("📢 Token 过期事件触发，跳转登录页");
    NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );
  });


  runApp(
    ProviderScope( // ✅ 必须包裹全应用
      child: MyApp(), // 或 App()
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '甜甜纪念日',
      navigatorKey: NavigationService.navigatorKey, // ✅ 设置全局跳转控制器
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const SplashPage(), // ✅ 设置启动页为判断页
      routes: {
        '/login': (context) => const LoginPage(),
        '/main': (context) => MainPage(),
      },
    );
  }
}

