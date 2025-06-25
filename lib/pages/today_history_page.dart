import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class TodayHistoryPage extends StatefulWidget {
  const TodayHistoryPage({super.key});

  @override
  State<TodayHistoryPage> createState() => _TodayHistoryPageState();
}

class _TodayHistoryPageState extends State<TodayHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;

  // 定义古风配色方案
  static const Color primaryColor = Color(0xFF8D6E63); // 古铜棕色
  static const Color secondaryColor = Color(0xFFD7CCC8); // 淡米色
  static const Color accentColor = Color(0xFFBF360C); // 赤红色
  static const Color backgroundColor = Color(0xFFF5F5F5); // 米白色

  // 历史事件分类
  final List<String> _categories = ['全部', '科技', '文化', '战争', '人物', '灾难', '发明'];

  // 模拟历史数据 - 实际应用中应从API获取
  final List<Map<String, dynamic>> _historyEvents = [
    {
      "year": 1969,
      "title": "阿波罗11号登月",
      "description": "美国宇航员尼尔·阿姆斯特朗成为第一个踏上月球的人类，他说出了著名的一句话：这是我个人的一小步，却是人类的一大步。",
      "category": "科技",
      "imageUrl": " https://upload.wikimedia.org/wikipedia/commons/d/d8/C-54landingattemplehof.jpg/apollo11.jpg",
    },
    {
      "year": 1945,
      "title": "第二次世界大战结束",
      "description": "日本宣布无条件投降，第二次世界大战正式结束，这场战争造成了约6000万人死亡。",
      "category": "战争",
      "imageUrl": " https://upload.wikimedia.org/wikipedia/commons/d/d8/C-54landingattemplehof.jpg/wwii.jpg",
    },
    {
      "year": 1989,
      "title": "柏林墙倒塌",
      "description": "柏林墙倒塌，标志着冷战的结束和德国统一进程的开始。",
      "category": "文化",
      "imageUrl": " https://upload.wikimedia.org/wikipedia/commons/d/d8/C-54landingattemplehof.jpg/berlin_wall.jpg",
    },
    {
      "year": 1912,
      "title": "泰坦尼克号沉没",
      "description": "被誉为永不沉没的泰坦尼克号在首航中与冰山相撞沉没，造成1500多人死亡。",
      "category": "灾难",
      "imageUrl": " https://upload.wikimedia.org/wikipedia/commons/d/d8/C-54landingattemplehof.jpg/titanic.jpg",
    },
    {
      "year": 1876,
      "title": "贝尔发明电话",
      "description": "亚历山大·格雷厄姆·贝尔获得了电话专利，这一发明彻底改变了人类的通信方式。",
      "category": "发明",
      "imageUrl": " https://upload.wikimedia.org/wikipedia/commons/d/d8/C-54landingattemplehof.jpg/telephone.jpg",
    },
    {
      "year": 1955,
      "title": "爱因斯坦逝世",
      "description": "物理学家阿尔伯特·爱因斯坦在美国普林斯顿逝世，享年76岁。他的相对论理论彻底改变了人类对宇宙的认识。",
      "category": "人物",
      "imageUrl": " https://upload.wikimedia.org/wikipedia/commons/d/d8/C-54landingattemplehof.jpg/einstein.jpg",
    },
    {
      "year": 1997,
      "title": "香港回归",
      "description": "中国恢复对香港行使主权，结束了156年的英国殖民统治。",
      "category": "文化",
      "imageUrl": " https://upload.wikimedia.org/wikipedia/commons/d/d8/C-54landingattemplehof.jpg/hongkong.jpg",
    },
    {
      "year": 1903,
      "title": "莱特兄弟首次飞行",
      "description": "奥维尔和威尔伯·莱特在北卡罗来纳州基蒂霍克成功进行了人类历史上第一次动力飞行。",
      "category": "发明",
      "imageUrl": " https://upload.wikimedia.org/wikipedia/commons/d/d8/C-54landingattemplehof.jpg/wright.jpg",
    },
    {
      "year": 1963,
      "title": "肯尼迪遇刺",
      "description": "美国第35任总统约翰·F·肯尼迪在德克萨斯州达拉斯遭到枪击身亡。",
      "category": "人物",
      "imageUrl": " https://upload.wikimedia.org/wikipedia/commons/d/d8/C-54landingattemplehof.jpg/kennedy.jpg",
    },
    {
      "year": 2001,
      "title": "9/11恐怖袭击",
      "description": "恐怖分子劫持飞机撞击美国纽约世贸中心双塔和五角大楼，造成近3000人死亡。",
      "category": "灾难",
      "imageUrl": " https://upload.wikimedia.org/wikipedia/commons/d/d8/C-54landingattemplehof.jpg/911.jpg",
    },
  ];

  String _selectedCategory = '全部';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);

    // 监听滚动位置以显示/隐藏回到顶部按钮
    _scrollController.addListener(() {
      setState(() {
        _showBackToTopButton = _scrollController.offset > 200;
      });
    });
  }


  Future<List<Map<String, dynamic>>> getHistoryToDay() async {
    final response = await Dio().get(
      'https://jkapi.com/api/history',
      options: Options(
        responseType: ResponseType.plain,
        headers: {'Accept': 'text/plain'},
        sendTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 10),
      ),
    );

    List<Map<String, dynamic>> parseTodayHistoryText(String rawText) {
      final lines = rawText.trim().split('\n');
      final events = <Map<String, dynamic>>[];

      for (var line in lines) {
        final match = RegExp(r'^(\d{4})\s+(.+)$').firstMatch(line.trim());
        if (match != null) {
          events.add({
            'year': int.parse(match.group(1)!),
            'event': match.group(2)!,
          });
        }
      }

      return events;
    }

    final list = parseTodayHistoryText(response.data.toString());
    return list;
  }
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 根据选择的分类筛选历史事件
  List<Map<String, dynamic>> get filteredEvents {
    if (_selectedCategory == '全部') {
      return _historyEvents;
    } else {
      return _historyEvents.where((event) => event['category'] == _selectedCategory).toList();
    }
  }
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy年MM月dd日').format(today);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  "历史上的今天",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black38, offset: Offset(1, 1), blurRadius: 2)
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 古风背景
                    Image.network(
                      "https://upload.wikimedia.org/wikipedia/commons/7/7e/Mao_Zedong_in_1957_%28cropped%29.jpg", // 替换为您的古风背景图
                      fit: BoxFit.cover,
                    ),
                    // 渐变遮罩
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    // 日期显示
                    Positioned(
                      bottom: 60,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: secondaryColor.withOpacity(0.5), width: 1),
                        ),
                        child: Text(
                          todayStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              systemOverlayStyle: SystemUiOverlayStyle.light,
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: accentColor,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: accentColor,
                  indicatorWeight: 2.0,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                  tabs: _categories.map((category) => Tab(text: category)).toList(),
                  onTap: (index) {
                    setState(() {
                      _selectedCategory = _categories[index];
                    });
                  },
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            return _buildHistoryEventsList();
          }).toList(),
        ),
      ),
      // 回到顶部按钮
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
        mini: true,
        backgroundColor: primaryColor,
        child: const Icon(Icons.arrow_upward),
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      )
          : null,
    );
  }

  // 构建历史事件列表
  Widget _buildHistoryEventsList() {
    if (filteredEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "暂无${_selectedCategory}类历史事件",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      itemCount: filteredEvents.length,
      itemBuilder: (context, index) {
        final event = filteredEvents[index];
        return _buildHistoryEventCard(event, index);
      },
    );
  }

  // 构建单个历史事件卡片
  Widget _buildHistoryEventCard(Map<String, dynamic> event, int index) {
    return AnimatedBuilder(
      animation: Listenable.merge([]),
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 500 + (index * 100)),
          curve: Curves.easeOutQuad,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              // 古风纸张质感
              image: const DecorationImage(
                image: NetworkImage(
                  "https://img.zcool.cn/community/01639e5cb6d910a8012141685a6e29.jpg@1280w_1l_2o_100sh.jpg", // 替换为您的纸张纹理图
                ),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
            child: InkWell(
              onTap: () => _showEventDetails(event),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 年份和分类标签
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            "${event['year']}年",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(event['category']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            event['category'],
                            style: TextStyle(
                              color: _getCategoryColor(event['category']),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 事件标题
                    Text(
                      event['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E342E), // 深棕色
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 事件描述
                    Text(
                      event['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // 查看更多按钮
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _showEventDetails(event),
                        style: TextButton.styleFrom(
                          foregroundColor: accentColor,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "查看详情",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: accentColor,
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 12, color: accentColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 显示事件详情对话框
  void _showEventDetails(Map<String, dynamic> event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            // 古风纸张质感
            image: DecorationImage(
              image: NetworkImage(
                "https://img.zcool.cn/community/01639e5cb6d910a8012141685a6e29.jpg@1280w_1l_2o_100sh.jpg", // 替换为您的纸张纹理图
              ),
              fit: BoxFit.cover,
              opacity: 0.1,
            ),
          ),
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              // 拖动条
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 内容区域
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  children: [
                    // 标题和年份
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            event['title'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4E342E), // 深棕色
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            "${event['year']}年",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 分类标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(event['category']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        event['category'],
                        style: TextStyle(
                          color: _getCategoryColor(event['category']),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 图片（如果有）
                    if (event['imageUrl'] != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          event['imageUrl'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 40),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // 详细描述
                    const Text(
                      "事件详情",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E342E), // 深棕色
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: secondaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: secondaryColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        event['description'],
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 相关历史事件（模拟数据）
                    const Text(
                      "相关历史事件",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E342E), // 深棕色
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRelatedEvents(event),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建相关事件列表
  Widget _buildRelatedEvents(Map<String, dynamic> currentEvent) {
    // 获取同类别的其他事件
    final relatedEvents = _historyEvents
        .where((e) => e['category'] == currentEvent['category'] && e != currentEvent)
        .take(3)
        .toList();

    if (relatedEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text("暂无相关事件", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      children: relatedEvents.map((event) => _buildRelatedEventItem(event)).toList(),
    );
  }

  // 构建单个相关事件项
  Widget _buildRelatedEventItem(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => _showEventDetails(event),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            "${event['year']}",
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          event['title'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          event['description'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
      ),
    );
  }

  // 获取分类对应的颜色
  Color _getCategoryColor(String category) {
    switch (category) {
      case '科技':
        return Colors.blue.shade700;
      case '文化':
        return Colors.purple.shade700;
      case '战争':
        return Colors.red.shade700;
      case '人物':
        return Colors.green.shade700;
      case '灾难':
        return Colors.orange.shade700;
      case '发明':
        return Colors.teal.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}

// 用于实现固定的TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}