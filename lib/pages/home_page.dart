import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:chinese_lunar_calendar/chinese_lunar_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:heart_days/apis/anniversary.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:heart_days/components/AnimatedCardWrapper.dart';
import 'package:heart_days/components/AnniversaryCard.dart';
import 'package:heart_days/components/SwiperCardView.dart';
import 'package:heart_days/pages/add_anniversary.dart';
import 'package:heart_days/pages/today_history_page.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/utils/SafeNavigator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/BaseInfoCard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<Anniversary> anniversaries = [];
  String oneSentenceContent = "";
  bool _isAscending = true; // 控制升序/降序
  // 添加布局模式状态
  bool _isStackLayout = false; // false: 列表模式, true: 堆叠模式
  int _currentStackIndex = 0;
  Offset _dragOffset = Offset.zero;
  late final AnimationController _animationController;
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
    final nextSpringFestival =
        (today.isAfter(thisYearSpringFestival))
            ? LunarCalendar.from(
              utcDateTime: DateTime(now.year + 1, 1, 1),
            ).chineseNewYear
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

  void _sortAnniversariesByDate() {
    setState(() {
      anniversaries.sort(
        (a, b) =>
            _isAscending ? a.date.compareTo(b.date) : b.date.compareTo(a.date),
      );
      _isAscending = !_isAscending; // 每次点击切换排序方向
    });
  }

  Future<void> loadAnniversariesFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authDataString = prefs.getString('auth_data');
      print(authDataString);
      if (authDataString == null) {
        setState(() => anniversaries = []);
        return;
      }
      final Map<String, dynamic> authMap = jsonDecode(authDataString);
      final authState = AuthState.fromJson(authMap);
      if (authState.user?.id == null) {
        setState(() => anniversaries = []);
        return;
      }
      final response = await fetchAnniversaryListByUserId(authState.user!.id);
      if (response.code == 200 && response.data != null) {
        setState(() => anniversaries = response.data!);
      } else {
        setState(() => anniversaries = []);
      }
    } catch (e) {
      setState(() => anniversaries = []);
    }
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
  StreamSubscription? _anniversarySubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(); // 循环动画
    _loadData();
    // ✅ 监听纪念日列表更新事件
    _anniversarySubscription = eventBus.on<AnniversaryListUpdated>().listen((
      event,
    ) {
      _loadData(); // 🔄 刷新
    });
  }



  Future<void> _loadData() async {
    if (!mounted) return; // 避免 setState 报错
    try {
      await loadAnniversariesFromLocal();

    } catch (e) {
      print("❌ 加载纪念日数据失败: $e");
    }
  }

  @override
  void dispose() {
    // 清理事件监听器，避免内存泄漏
    _anniversarySubscription?.cancel();
    _animationController.dispose();
    super.dispose();
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

          // 标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: // 在排序按钮的Row中添加布局切换按钮
                Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "特别时刻",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6487A6), // 适配浅蓝风格的深灰蓝标题
                  ),
                ),

                // 按钮组
                Row(
                  children: [
                    // 布局切换按钮
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isStackLayout = !_isStackLayout;
                          if (_isStackLayout) {
                            _currentStackIndex = 0;
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFE6F0FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isStackLayout ? Icons.view_list : Icons.layers,
                              size: 16,
                              color: const Color(0xFF64A6D9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isStackLayout ? "列表" : "堆叠",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64A6D9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 排序按钮
                    InkWell(
                      onTap: _sortAnniversariesByDate,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFE6F0FA), // ✅ 浅蓝背景
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Transform.rotate(
                              angle: _isAscending ? 0 : 3.14, // 旋转箭头以表示方向
                              child: Icon(
                                Icons.sort,
                                size: 16,
                                color: const Color(0xFF64A6D9),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "排序",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64A6D9), // ✅ 浅蓝文字
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 纪念日列表 - 添加下拉刷新功能
          // 替换原来的列表显示部分
          Expanded(
            child:
                anniversaries.isEmpty
                    ? RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3,
                          ),
                          Center(
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
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    : _isStackLayout
                    ? _buildStackLayout()
                    : _buildListLayout(),
          ),
        ],
      ),
      // 添加纪念日按钮 - 改进设计
      floatingActionButton: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: FloatingActionButton(
          heroTag: 'home_fab',
          // 唯一tag，防止Hero冲突
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

  // 列表布局（原来的布局）
  Widget _buildListLayout() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: Listenable.merge([]),
            builder: (context, child) {
              return AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(milliseconds: 500 + (index * 100)),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: buildAnniversaryCard(anniversaries[index]),
                ),
              );
            },
          );
        },
        itemCount: anniversaries.length,
      ),
    );
  }

  // 堆叠布局（新的卡片堆叠布局）
  Widget _buildStackLayout() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          // 堆叠卡片区域 - 增加高度和居中
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 背景卡片（显示后面的卡片）- 最多显示3层
                  ...List.generate(math.min(4, anniversaries.length), (index) {
                    final cardIndex =
                        (_currentStackIndex + index) % anniversaries.length;

                    // 缩放比例（第 4 层更小）
                    final scale =
                        1.0 - (index * 0.08); // [1.0, 0.92, 0.84, 0.76]
                    final verticalOffset = index * 12.0;
                    final horizontalOffset = index * 6.0;

                    // 透明度递减：第一张1.0，第二张0.7，第三张0.4，第四张0.2
                    final opacity = switch (index) {
                      0 => 1.0,
                      1 => 0.7,
                      2 => 0.4,
                      3 => 0.2,
                      _ => 0.0,
                    };

                    return Positioned(
                      top: verticalOffset,
                      left: horizontalOffset,
                      right: horizontalOffset,
                      child: Transform.scale(
                        scale: scale,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: opacity,
                          child: _buildStackCard(
                            anniversaries[cardIndex],
                            index == 0,
                            index,
                          ),
                        ),
                      ),
                    );
                  }).reversed,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackCard(Anniversary item, bool isTopCard, int stackIndex) {
    final isCurrent = isTopCard;
    final dragDx = _dragOffset.dx;

    // 旋转角度范围（左右滑动最大 ±10 度）
    final rotation = isCurrent ? dragDx / 300 * 0.2 : 0.0;

    // 缩放 + Y 偏移，让卡片形成层叠视觉（后面的卡片越小、越低）
    final scale = 1.0 - (0.05 * stackIndex);
    final offsetY = 12.0 * stackIndex;

    Widget card = AnniversaryCard(anniversary: item);

    // 包裹缩放和偏移
    card = Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: card,
      ),
    );

    if (isCurrent) {
      // AnimatedBuilder 实现旋转动画 + 拖拽
      card = AnimatedBuilder(
        animation: Listenable.merge([_animationController]),
        builder: (_, child) {
          return Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(angle: rotation, child: child),
          );
        },
        child: card,
      );

      // 包裹手势
      card = GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _dragOffset += details.delta;
          });
        },
        onPanEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond.dx;
          const threshold = 300.0;

          if (velocity < -threshold &&
              _currentStackIndex < anniversaries.length - 1) {
            setState(() {
              _currentStackIndex++;
              _dragOffset = Offset.zero;
            });
          } else if (velocity > threshold && _currentStackIndex > 0) {
            setState(() {
              _currentStackIndex--;
              _dragOffset = Offset.zero;
            });
          } else {
            // 回弹动画
            setState(() {
              _dragOffset = Offset.zero;
            });
          }
        },
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddAnniversaryPage(anniversaryItem: item),
            ),
          );
        },
        child: card,
      );
    }

    return card;
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
      key: Key(item.date.toString()),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddAnniversaryPage(anniversaryItem: item),
                    ),
                  );
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
                    if (item.id != null) {
                      setState(() {
                        anniversaries.removeWhere(
                          (element) => element.id == item.id,
                        );
                      });
                      await anniversaryDeleteById(int.parse(item.id as String));
                      // 发送删除成功事件
                      eventBus.fire(AnniversaryListUpdated());
                    }
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AddAnniversaryPage(anniversaryItem: item),
                      ),
                    );
                    print("查看详情");
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
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
                                item.title,
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
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
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
      subtitle: "每日一句",
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

  Widget _buildPreviewCard(Anniversary item) {
    final daysLeft = item.date.difference(DateTime.now()).inDays;
    final isInFuture = daysLeft >= 0;
    final daysText = isInFuture ? "还有 ${daysLeft + 1} 天" : "已过去 ${-daysLeft} 天";
    final color = (item.color ?? Colors.black);
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddAnniversaryPage(anniversaryItem: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          // 只保留纯色渐变背景
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ✅ 放内容
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('yyyy年MM月dd日').format(item.date),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
