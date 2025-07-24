import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:heart_days/pages/SplashPage.dart';
import 'package:heart_days/pages/main_page.dart';
import 'package:heart_days/pages/login_page.dart';
import 'package:heart_days/pages/startup_debug_page.dart';
import 'package:heart_days/utils/navigation_service.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  // ✅ 监听 Token 过期事件
  eventBus.on<TokenExpiredEvent>().listen((event) {
    print("📢 Token 过期事件触发，跳转登录页");
    NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  });

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}
final botToastBuilder = BotToastInit();
class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '甜甜纪念日',
      navigatorKey: NavigationService.navigatorKey,
      navigatorObservers: [BotToastNavigatorObserver()], // 第二步：注册路由观察器
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          error: Colors.red,
        ),
      ),
      home: const SplashPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/main': (context) => MainPage(),
        '/startup_debug': (context) => const StartupDebugPage(),
      },
      builder: (context, child) {
        child = botToastBuilder(context, child);
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
    );
  }
}

