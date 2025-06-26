import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_days/pages/about_page.dart';
import 'package:heart_days/pages/setting_page.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final nickname = '糖糖宝';
    final signature = '你是我最甜的纪念日';

    // 定义高级感配色
    const Color primaryColor = Color(0xFF5C6BC0); // 主色调：靛蓝色
    const Color secondaryColor = Color(0xFF64B5F6); // 次要色调：蓝色
    const Color accentColor = Color(0xFFFF7043); // 强调色：橙色
    const Color backgroundColor = Color(0xFFF8F9FA); // 背景色：浅灰色
    const Color cardColor = Colors.white; // 卡片色：纯白色

    final List<Map<String, dynamic>> shortcuts = [
      {
        'icon': Icons.calendar_today,
        'label': '纪念日',
        'color': Color(0xFF42A5F5),
      },
      {'icon': Icons.favorite, 'label': '心愿单', 'color': Color(0xFFEC407A)},
      {'icon': Icons.photo_library, 'label': '相册', 'color': Color(0xFF66BB6A)},
      {'icon': Icons.chat, 'label': '聊天', 'color': Color(0xFFFF7043)},
    ];
    // ❌ 错误示例（你目前的写法）：
    // 这段代码会导致 Dart 把箭头函数返回的 {} 当成一个 Set，不是一个真正的函数体：
    //
    // dart
    // 复制
    // 编辑
    // 'onTap': () => {
    // Navigator.push(
    // context,
    // MaterialPageRoute(builder: (_) => const AboutPage()),
    // ),
    // },
    // 这就是导致 child == child 报错的关键原因之一。
    //
    // ✅ 正确示例（标准匿名函数）：
    // 你应该使用花括号包裹 函数体，而不是作为返回值的 Set：
    //
    // dart
    // 复制
    // 编辑
    // 'onTap': () {
    // Navigator.push(
    // context,
    // MaterialPageRoute(builder: (_) => const AboutPage()),
    // );
    final List<Map<String, dynamic>> cells = [
      {
        'icon': Icons.star,
        'label': '我的收藏',
        'color': Color(0xFFFFA726),
        'onTap': () {
          print('跳转到 我的收藏');
        },
      },
      {
        'icon': Icons.notifications,
        'label': '纪念日提醒设置',
        'color': Color(0xFF5C6BC0),
        'onTap': () {
          print('跳转到 提醒设置');
        },
      },
      {
        'icon': Icons.settings,
        'label': '关于我们',
        'color': Color(0xFF78909C),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutPage()),
          );
        },
      },
    ];


    return Scaffold(
      backgroundColor: backgroundColor,
      // 使用自定义滚动视图
      body: CustomScrollView(
        slivers: [
          // 顶部弹性头部
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '个人中心',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF48FB1), // 浅粉色
                      const Color(0xFFCE93D8), // 浅紫色
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
            ],
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),

          // 内容区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 个人资料卡片 - 高级设计
                  buildProfileCard(nickname, signature, cardColor),

                  const SizedBox(height: 24),

                  // 分类标题
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 0),
                    child: Text(
                      '快捷功能',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),

                  // 快捷功能区 - 高级设计
                  buildShortcutsGrid(shortcuts, context),

                  const SizedBox(height: 24),

                  // 分类标题
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 16),
                    child: Text(
                      '更多功能',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),

                  // 功能列表 - 高级设计
                  ...buildCells(cells),

                  const SizedBox(height: 24),

                  // 版本信息
                  Center(
                    child: Text(
                      'Heart Days v1.0.0',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 个人资料卡片
  Widget buildProfileCard(String nickname, String signature, Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // 头像区域
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF64B5F6), Color(0xFF5C6BC0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF5C6BC0).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: const Text('🐻‍', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 8),

          // 个人信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C6BC0),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  signature,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

          // 编辑按钮
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF5C6BC0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton.icon(
              onPressed: () {
                print('编辑资料');
              },
              icon: Icon(Icons.edit, size: 16, color: Color(0xFF5C6BC0)),
              label: Text(
                '编辑',
                style: TextStyle(
                  color: Color(0xFF5C6BC0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget buildShortcutsGrid(
    List<Map<String, dynamic>> shortcuts,
    BuildContext context,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          shortcuts.map((item) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 16 * 2 - 8 * 3) / 4 > 0
            ? (MediaQuery.of(context).size.width - 16 * 2 - 8 * 3) / 4
                : 0,
              height: 80,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => print('跳转到 ${item['label']}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: item['color'] as Color,
                        size: 24,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  // 功能列表项
  List<Widget> buildCells(List<Map<String, dynamic>> cells) {
    return List.generate(cells.length, (index) {
      final item = cells[index];

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => (item['onTap'] as VoidCallback?)?.call(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16), // 统一内边距
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  // 确保图标居中
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 22,
                  ),
                ),
                title: Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
