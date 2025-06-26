import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CuteTabBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;



  const CuteTabBar({required this.currentIndex, required this.onTap, super.key});
  @override
  State<CuteTabBar> createState() => _CuteTabBarState();
}

// class _CuteTabBarState extends State<CuteTabBar> with TickerProviderStateMixin {
//   final List<_TabItem> tabs = const [
//     _TabItem(icon: Icons.home_filled, label: '首页'),
//     _TabItem(icon: Icons.favorite, label: '计划'),
//     _TabItem(icon: Icons.person, label: '我的'),
//   ];
//
//   // 记录哪个按钮当前被按下，做缩放反馈
//   int? _pressedIndex;
//
//   final Gradient selectedGradient = const LinearGradient(
//     colors: [
//       Color(0xFFFCE4EC),
//       Color(0xFFF8BBD0),
//     ],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
//
//   // 更柔和的选中颜色
//   final Color selectedColor = const Color(0xFFEC407A); // 更柔和的粉红色
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.pink.withOpacity(0.01),
//             blurRadius: 6,
//             offset: const Offset(0, -2),
//           ),
//         ],
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: List.generate(tabs.length, (index) {
//           final isSelected = index == widget.currentIndex;
//           final isPressed = _pressedIndex == index;
//
//           return GestureDetector(
//             onTapDown: (_) {
//               setState(() => _pressedIndex = index);
//               // HapticFeedback.lightImpact(); // ✨ 按下时震动
//
//
//               HapticFeedback.mediumImpact(); //强震动
//             },
//             onTapUp: (_) {
//               setState(() => _pressedIndex = null);
//               widget.onTap(index);
//             },
//             onTapCancel: () => setState(() => _pressedIndex = null),
//             behavior: HitTestBehavior.translucent,
//             child: AnimatedScale(
//               scale: isPressed ? 0.9 : 1,
//               duration: const Duration(milliseconds: 100),
//               curve: Curves.easeOut,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 350),
//                 padding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: isSelected
//                     ? BoxDecoration(
//                   gradient: selectedGradient,
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.pink.withOpacity(0.15),
//                       blurRadius: 4,
//                       offset: const Offset(0, 1),
//                     )
//                   ],
//                 )
//                     : null,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 350),
//                       child: Icon(
//                         tabs[index].icon,
//                         key: ValueKey<bool>(isSelected),
//                         size: 28,
//                         color: isSelected
//                             ? const Color(0xFFD81B60)
//                             : Colors.pink.shade300,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     AnimatedDefaultTextStyle(
//                       duration: const Duration(milliseconds: 350),
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: isSelected
//                             ? const Color(0xFFD81B60)
//                             : Colors.pink.shade300,
//                         fontFamily: 'HarmonyOSSans',
//                       ),
//                       child: Text(tabs[index].label),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }
class _CuteTabBarState extends State<CuteTabBar> with TickerProviderStateMixin {
  final List<_TabItem> tabs = const [
    _TabItem(icon: Icons.home_filled, label: '首页'),
    _TabItem(icon: Icons.favorite, label: '计划'),
    _TabItem(icon: Icons.note_alt, label: '便签'),
    _TabItem(icon: Icons.person, label: '我的'),
  ];

  // 记录哪个按钮当前被按下，做缩放反馈
  int? _pressedIndex;

  // 更新为蓝色系渐变
  final Gradient selectedGradient = const LinearGradient(
    colors: [
      Color(0xFFE3F2FD),
      Color(0xFFBBDEFB),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 蓝色系选中颜色
  final Color selectedColor = const Color(0xFF42A5F5); // 明亮的蓝色
  final Color unselectedColor = Color(0xFF90CAF9); // 淡蓝色
  @override
  // void initState() {
  //   super.initState();
  //   SystemChrome.setSystemUIOverlayStyle(
  //     const SystemUiOverlayStyle(
  //       systemNavigationBarColor: Colors.white,
  //       systemNavigationBarIconBrightness: Brightness.dark,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8 + MediaQuery.of(context).padding.bottom,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (index) {
          final isSelected = index == widget.currentIndex;
          final isPressed = _pressedIndex == index;

          return GestureDetector(
            onTapDown: (_) {
              setState(() => _pressedIndex = index);
              HapticFeedback.mediumImpact();
            },
            onTapUp: (_) {
              setState(() => _pressedIndex = null);
              widget.onTap(index);
            },
            onTapCancel: () => setState(() => _pressedIndex = null),
            behavior: HitTestBehavior.translucent,
            child: AnimatedScale(
              scale: isPressed ? 0.9 : 1,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: isSelected
                    ? BoxDecoration(
                  gradient: selectedGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
                )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Icon(
                        tabs[index].icon,
                        key: ValueKey<bool>(isSelected),
                        size: 28,
                        color: isSelected ? selectedColor : unselectedColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 350),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? selectedColor : unselectedColor,
                        fontFamily: 'HarmonyOSSans',
                      ),
                      child: Text(tabs[index].label),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
class _TabItem {
  final IconData icon;
  final String label;

  const _TabItem({required this.icon, required this.label});
}
