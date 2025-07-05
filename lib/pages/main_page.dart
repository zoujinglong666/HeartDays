import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_days/components/CuteTabBar.dart';
import 'package:heart_days/pages/home_page.dart';
import 'package:heart_days/pages/mine_page.dart';
import 'package:heart_days/pages/node_page.dart';
import 'package:heart_days/pages/plan_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const int pageCount = 4;
  int selectIndex = 0;

  // nullable 页面数组（懒加载）
  late final List<Widget?> pages;

  @override
  void initState() {
    super.initState();

    pages = List<Widget?>.filled(pageCount, null, growable: false);
    pages[0] = const HomePage(); // 首页立即构建

    // 设置导航栏样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFFFFFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // 👇 页面初始加载完成后，延迟预热其他页面
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          pages[1] ??= const PlanPage();
          pages[2] ??= const NodePage();
          pages[3] ??= const MinePage();
        });
      });
    });
  }

  void changeTabbar(int index) {
    if (selectIndex == index) return;

    setState(() {
      selectIndex = index;

      // 👇 懒加载当前页面
      pages[index] ??= _buildPage(index);
    });
  }

  // 页面构建工厂
  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const PlanPage();
      case 2:
        return const NodePage();
      case 3:
        return const MinePage();
      default:
        return const HomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: selectIndex,
        children: List.generate(
          pageCount,
              (i) => pages[i] ?? const SizedBox(), // 未构建页面用空占位，防止卡顿
        ),
      ),
      bottomNavigationBar: CuteTabBar(
        currentIndex: selectIndex,
        onTap: changeTabbar,
      ),
    );
  }
}
