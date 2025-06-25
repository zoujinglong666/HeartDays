import 'dart:convert';

import 'package:chinese_lunar_calendar/chinese_lunar_calendar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:heart_days/components/AnimatedCardWrapper.dart';
import 'package:heart_days/components/SwiperCardView.dart';
import 'package:heart_days/http/model/Anniversary.dart';
import 'package:heart_days/pages/add_anniversary.dart';
import 'package:heart_days/pages/today_history_page.dart';
import 'package:heart_days/utils/Notifier.dart';
import 'package:heart_days/utils/SafeNavigator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/BaseInfoCard.dart';

class AnniversaryAddedEvent {
  final Map<String, dynamic> data;

  AnniversaryAddedEvent(this.data);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Anniversary> anniversaries = [];
  String oneSentenceContent = "";


  List<Map<String, dynamic>> getBuiltinAnniversaries() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 离本周六
    final daysToSaturday = (DateTime.saturday - now.weekday) % 7;
    final saturday = today.add(Duration(days: daysToSaturday));

    // 发工资：每月15号
    DateTime salaryDate = DateTime(now.year, now.month, 15);
    if (!salaryDate.isAfter(today)) {
      salaryDate = DateTime(now.year, now.month + 1, 15);
    }

    // 计算春节（支持判断是否已过）
    final lunarCalendar = LunarCalendar.from(utcDateTime: now);
    final thisYearSpringFestival = lunarCalendar.chineseNewYear;
    final nextSpringFestival = (today.isAfter(thisYearSpringFestival))
        ? LunarCalendar.from(utcDateTime: DateTime(now.year + 1, 1, 1)).chineseNewYear
        : thisYearSpringFestival;

    return [
      {
        'title': '离本周六还有',
        'date': saturday,
        'color': const Color(0xFFB5C6E0),
        'type': 'system',
      },
      {
        'title': '离发工资还有',
        'date': salaryDate,
        'color': const Color(0xFFD5E4C3),
        'type': 'system',
      },
      {
        'title': '距离春节还有',
        'date': nextSpringFestival,
        'color': const Color(0xFFE8C4C4),
        'type': 'system',
      },
    ];
  }

  Future<List<Anniversary>> loadAnniversariesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('anniversaries');
    if (raw == null) return [];
    final List<dynamic> decoded = json.decode(raw);
    return decoded.map((item) => Anniversary.fromJson(item)).toList();
  }

  // 定义应用配色方案
  static const Color primaryColor = Color(0xFF5C6BC0); // 靛蓝色作为主色调
  static const Color accentColor = Color(0xFFFF7043); // 橙色作为强调色

  // 卡片渐变色
  static const List<List<Color>> cardGradients = [
    [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // 蓝色系
    [Color(0xFFE8EAF6), Color(0xFFC5CAE9)], // 靛蓝系
    [Color(0xFFF3E5F5), Color(0xFFE1BEE7)], // 紫色系
    [Color(0xFFE0F7FA), Color(0xFFB2EBF2)], // 青色系
  ];

  // 获取随机渐变色
  List<Color> getRandomGradient() {
    final random = DateTime.now().millisecondsSinceEpoch % cardGradients.length;
    return cardGradients[random];
  }

  // 根据日期获取固定渐变色（确保同一纪念日始终使用相同颜色）
  List<Color> getGradientByDate(DateTime date) {
    final index = date.day % cardGradients.length;
    return cardGradients[index];
  }

  String getTodayStr() {
    final now = DateTime.now();
    final weekdayMap = ['日', '一', '二', '三', '四', '五', '六'];
    return '${DateFormat('yyyy年MM月dd日').format(now)} 星期${weekdayMap[now.weekday % 7]}';
  }

  int getDaysLeft(DateTime date) {
    final today = DateTime.now();
    return date.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  // 这是 Dart 的生命周期 & 异步使用问题 —— initState() 不能是 async 函数，也不能直接 await。你需要把 await 操作放到 initState() 中调用的另一个函数里。
  @override
  void initState() {
    super.initState();
    _loadData();

    // 监听事件
    notifier.addListener(() {
      if (notifier.value == 'anniversary_added') {
        _loadData(); // 🔄 刷新
        notifier.value = null; // 重置事件，防止重复触发
      }
    });
  }

  Future<String> getOneSentencePerDay() async {
    try {
      final response = await Dio().get(
        'https://api.xygeng.cn/openapi/one',
        options: Options(
          headers: {
            'Referer': 'https://api.codelife.cc/',
            'Origin': 'https://api.codelife.cc/',
            'Accept': 'application/json',
          },
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['data'] is Map) {
        return response.data['data']['content'] ?? '';
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }


  Future<void> _loadData() async {
    final list = await loadAnniversariesFromLocal();

    if (!mounted) return; // 避免 setState 报错
    final oneSentenceStr = await getOneSentencePerDay();

    setState(() => {anniversaries = list});
    setState(() => {oneSentenceContent = oneSentenceStr});
  }

  @override
  Widget build(BuildContext context) {
    final container = Theme.of(context).colorScheme.primaryContainer;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: container,
        surfaceTintColor: container,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwiperCardView(
            cards: [
              AnimatedCardWrapper(child: buildTodayCard()),
              AnimatedCardWrapper(child: buildReminderCard()),
              AnimatedCardWrapper(child: buildHistoryTodayCard()),
              AnimatedCardWrapper(child: buildQuoteCard()),
              AnimatedCardWrapper(child: buildSignatureCard()),
            ],
          ),

          // 功能模块入口
          // buildFeatureModules(),
          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "我的纪念日",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD81B60),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sort, size: 16, color: Colors.pink.shade400),
                      const SizedBox(width: 4),
                      Text(
                        "排序",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.pink.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 纪念日列表 - 添加动画效果
          Expanded(
            child:
                anniversaries.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.celebration_outlined,
                            size: 64,
                            color: Colors.pink.shade200,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '暂无纪念日，点击右下角添加吧~',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        // 添加列表项动画
                        return AnimatedBuilder(
                          animation: Listenable.merge([
                            // 如果有滚动控制器，可以在这里添加
                          ]),
                          builder: (context, child) {
                            return AnimatedOpacity(
                              opacity: 1.0,
                              duration: Duration(
                                milliseconds: 500 + (index * 100),
                              ),
                              child: AnimatedPadding(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  bottom: 4,
                                ),
                                child: buildAnniversaryCard(
                                  anniversaries[index],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      itemCount: anniversaries.length,
                    ),
          ),
        ],
      ),
      // 添加纪念日按钮 - 改进设计
      floatingActionButton: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: FloatingActionButton(
          onPressed: () async {
            SafeNavigator.pushOnce(context, AddAnniversaryPage());
          },
          backgroundColor: const Color(0xFF90CAF9),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  // 顶部今日卡片 - 全新设计
  Widget buildTodayCard() {
    final now = DateTime.now();
    final weekdayMap = ['日', '一', '二', '三', '四', '五', '六'];
    final weekday = weekdayMap[now.weekday % 7];

    return Container(
      width: double.infinity,
      height: 120,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶部日期显示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF90CAF9), // 淡蓝色
                  const Color(0xFF64B5F6), // 蓝色
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text("📅", style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${now.year}年${now.month}月${now.day}日",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "星期$weekday",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 底部天气和农历信息（可选）
          // Padding(
          //   padding: const EdgeInsets.all(16),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //     children: [
          //       Row(
          //         children: [
          //           Icon(Icons.wb_sunny, color: Colors.orange.shade400),
          //           const SizedBox(width: 8),
          //           Text(
          //             "晴 23°C", // 这里可以接入天气API
          //             style: TextStyle(
          //               fontSize: 14,
          //               color: Colors.grey.shade700,
          //             ),
          //           ),
          //         ],
          //       ),
          //       Text(
          //         "农历六月初六", // 这里可以接入农历转换
          //         style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // 功能模块小组件
  Widget buildFeatureModules() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(left: 8, bottom: 8)),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildFeatureItem("生日提醒", Icons.cake, const Color(0xFF42A5F5)),
              _buildFeatureItem(
                "纪念相册",
                Icons.photo_album,
                const Color(0xFF66BB6A),
              ),
              _buildFeatureItem("情侣游戏", Icons.games, const Color(0xFFEC407A)),
              _buildFeatureItem(
                "心愿清单",
                Icons.favorite,
                const Color(0xFFFF7043),
              ),
              _buildFeatureItem("共享日记", Icons.book, const Color(0xFF5C6BC0)),
              _buildFeatureItem(
                "恋爱计算",
                Icons.calculate,
                const Color(0xFF8D6E63),
              ),
              _buildFeatureItem(
                "情侣壁纸",
                Icons.wallpaper,
                const Color(0xFF26A69A),
              ),
              _buildFeatureItem(
                "更多功能",
                Icons.more_horiz,
                const Color(0xFF78909C),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 单个功能模块项
  Widget _buildFeatureItem(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: 跳转到对应功能
        print("打开功能: $title");
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.01),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget buildAnniversaryCard(Anniversary item) {
    final daysLeft = getDaysLeft(item.date);
    final isFuture = daysLeft >= 0;
    final tagText = isFuture ? '还有 $daysLeft 天' : '已过去 ${-daysLeft} 天';
    final bool isNearby = isFuture && daysLeft <= 7; // 判断是否临近

    // 使用多样化的配色
    final cardColors = getGradientByDate(item.date);

    // 侧滑删除和编辑功能
    return Dismissible(
      key: Key(item.date?.toString() ?? DateTime.now().toString()),
      // 确保每个卡片有唯一的key
      direction: DismissDirection.endToStart,
      // 从右向左滑动
      confirmDismiss: (direction) async {
        // 显示操作菜单而不是直接删除
        return false;
      },
      background: Container(),
      // 空背景，因为我们使用secondaryBackground
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
      ),
      onDismissed: null,
      // 我们不使用这个回调，因为confirmDismiss返回false
      child: GestureDetector(
        onTap: () {
          // TODO: 跳转到详情页
          print("查看详情: ${item.title}");
        },
        child: Slidable(
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            extentRatio: 0.55, // 控制操作按钮区域的宽度比例
            children: [
              // 编辑按钮
              CustomSlidableAction(
                onPressed: (context) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddAnniversaryPage(anniversaryItem: item)));
                },
                backgroundColor: Colors.blue.shade50,
                foregroundColor: primaryColor,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_outlined, size: 22),
                    Text('编辑', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              // 删除按钮
              CustomSlidableAction(
                onPressed: (context) async {
                  // 显示确认对话框
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('确认删除'),
                          content: Text('确定要删除「${item.title}」吗？'),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('取消'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('删除'),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    // 从列表中移除该项
                    setState(() {
                      anniversaries.removeWhere(
                        (element) => element.title == item.title,
                      );

                    });
                    // 更新本地存储
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString(
                      'anniversaries',
                      json.encode(anniversaries.map((a) => a.toJson()).toList()),
                    );
                  }
                },
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                borderRadius: BorderRadius.circular(8),
                padding: const EdgeInsets.all(0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, size: 22),
                    const SizedBox(height: 4),
                    Text('删除', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          child: Container(
            // margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  splashColor: cardColors[0].withOpacity(0.3),
                  highlightColor: cardColors[0].withOpacity(0.1),
                  onTap: () {
                    // TODO: 跳转到详情页
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddAnniversaryPage(anniversaryItem: item)));
                    print("查看详情");
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // 左侧图标 - 使用多样化的颜色
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: cardColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cardColors[1].withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            item.icon ?? '🎉',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // 中间文本信息
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title ,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor, // 使用主色调
                                ),
                                maxLines: 1, // 限制最多显示1行
                                overflow: TextOverflow.ellipsis, // 超出部分显示省略号
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('yyyy年MM月dd日').format(item.date),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 右侧剩余天数 - 改进为更醒目的设计
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isNearby
                                    ? accentColor.withOpacity(0.15) // 使用强调色
                                    : cardColors[0].withOpacity(0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            tagText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  isNearby
                                      ? accentColor // 使用强调色
                                      : primaryColor, // 使用主色调
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHistoryTodayCard() {
    return BaseInfoCard(
      emoji: "📖",
      title: "历史上的今天",
      subtitle: "2002年：巴西第五次夺得世界杯冠军",
      gradientColors: [Color(0xFFFFF176), Color(0xFFFFD54F)],
      // 柠檬黄
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (_) => TodayHistoryPage()),
        );
      },
    );
  }

  Widget buildReminderCard() {
    return BaseInfoCard(
      emoji: "⏰",
      title: "今日提醒",
      subtitle: "15:00 和ta一起看日落",
      gradientColors: [Color(0xFFFFAB91), Color(0xFFFF8A65)], // 橙红渐变
    );
  }

  Widget buildQuoteCard() {
    return BaseInfoCard(
      emoji: "💡",
      title: "每日一句",
      subtitle: oneSentenceContent,
      gradientColors: [Color(0xFFAED581), Color(0xFF81C784)], // 阳光绿
    );
  }

  Widget buildSignatureCard() {
    return BaseInfoCard(
      emoji: "💌",
      title: "糖糖宝",
      subtitle: "你是我最甜的纪念日",
      gradientColors: [Color(0xFFF48FB1), Color(0xFFCE93D8)], // 粉+紫
    );
  }
}
