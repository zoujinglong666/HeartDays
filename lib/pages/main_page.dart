import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_days/pages/node_page.dart';
import '../components/CuteTabBar.dart';
import 'home_page.dart';
import 'mine_page.dart';
import 'plan_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}


class _MainPageState extends State<MainPage> {
  int selectIndex = 0;

  final List<Widget> pages = [
    const HomePage(),
    const PlanPage(),
    const NodePage(),
    const MinePage(),
  ];

  void changeTabbar(int index) {
    setState(() {
      selectIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Color(0xFFFFFFFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: selectIndex, children: pages),
      bottomNavigationBar: CuteTabBar(
        currentIndex: selectIndex,
        onTap: changeTabbar,
      ),
    );
  }
}
