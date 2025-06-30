import 'package:flutter/material.dart';
import 'package:heart_days/pages/todo_page.dart';
import 'package:table_calendar/table_calendar.dart';
import 'plan_detail_page.dart';
import 'plan_edit_page.dart';
import 'pomodoro_timer_page.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final Color morandiPink = const Color(0xFFFBEFF1);
  final Color morandiBlue = const Color(0xFFE6ECF7);
  final Color morandiGreen = const Color(0xFFD5E4C3);
  final Color morandiYellow = const Color(0xFFF1E0C5);
  final Color morandiGrey = const Color(0xFFE0E0E0);

  // 模拟计划数据
  List<Map<String, dynamic>> _plans = [
    {
      'id': '1',
      'title': '完成项目文档',
      'description': '需要完成项目的技术文档和用户手册',
      'category': '工作',
      'status': 'pending',
      'priority': 'high',
      'date': DateTime.now().add(const Duration(days: 2)),
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'id': '2',
      'title': '健身锻炼',
      'description': '进行30分钟的有氧运动和力量训练',
      'category': '健身',
      'status': 'in_progress',
      'priority': 'medium',
      'date': DateTime.now(),
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'id': '3',
      'title': '学习Flutter',
      'description': '学习Flutter框架的新特性和最佳实践',
      'category': '学习',
      'status': 'completed',
      'priority': 'high',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
    },
  ];

  final List<Map<String, dynamic>> _quickTools = [
    {'icon': Icons.event_note, 'label': '添加计划', 'color': const Color(0xFFFF6B6B),'onTap':(){

    }},
    {
      'icon': Icons.check_circle_outline,
      'label': '待办事项',
      'color': const Color(0xFF4ECDC4),
    },
    {'icon': Icons.timer, 'label': '专注计时', 'color': const Color(0xFF45B7D1)},
    {'icon': Icons.insert_chart, 'label': '统计分析', 'color': const Color(0xFF96CEB4)},
  ];

  final List<Map<String, dynamic>> _planCategories = [
    {'icon': Icons.work, 'label': '工作', 'color': Color(0xFFE74C3C), 'bgColor': Color(0xFFFFEBEE)},
    {'icon': Icons.school, 'label': '学习', 'color': Color(0xFF3498DB), 'bgColor': Color(0xFFE3F2FD)},
    {'icon': Icons.fitness_center, 'label': '健身', 'color': Color(0xFF27AE60), 'bgColor': Color(0xFFE8F5E8)},
    {'icon': Icons.favorite, 'label': '生活', 'color': Color(0xFFE67E22), 'bgColor': Color(0xFFFFF3E0)},
  ];

  // 刷新数据
  Future<void> _refreshData() async {
    // 模拟网络请求延迟
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      // 这里可以重新加载数据
    });
  }

  // 获取状态颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // 获取优先级颜色
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 获取状态文本
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return '待开始';
      case 'in_progress':
        return '进行中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return '未知';
    }
  }

  // 切换计划状态
  void _togglePlanStatus(String planId) {
    setState(() {
      final planIndex = _plans.indexWhere((plan) => plan['id'] == planId);
      if (planIndex != -1) {
        final currentStatus = _plans[planIndex]['status'];
        String newStatus;
        
        switch (currentStatus) {
          case 'pending':
            newStatus = 'in_progress';
            break;
          case 'in_progress':
            newStatus = 'completed';
            break;
          case 'completed':
            newStatus = 'pending';
            break;
          default:
            newStatus = 'pending';
        }
        
        _plans[planIndex]['status'] = newStatus;
      }
    });
  }

  // 打开计划详情页面
  void _openPlanDetail(Map<String, dynamic> plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlanDetailPage(plan: plan),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        if (result['action'] == 'delete') {
          _deletePlan(result['planId']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已删除"${plan['title']}"'),
              backgroundColor: const Color(0xFF34C759),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    });
  }

  // 添加新计划
  void _addNewPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlanEditPage(),
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          _plans.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            ...result,
            'createdAt': DateTime.now(),
          });
        });
      }
    });
  }

  // 删除计划
  void _deletePlan(String planId) {
    setState(() {
      _plans.removeWhere((plan) => plan['id'] == planId);
    });
  }

  // 获取分类计划数量
  int _getCategoryCount(String category) {
    return _plans.where((plan) => plan['category'] == category).length;
  }

  // 获取分类计划数量（按状态）
  int _getCategoryCountByStatus(String category, String status) {
    return _plans.where((plan) => 
      plan['category'] == category && plan['status'] == status
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [morandiPink, morandiBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildGlassCard(child: _buildCalendar()),
                  const SizedBox(height: 16),
                  _buildGlassCard(child: _buildQuickTools()),
                  const SizedBox(height: 16),
                  _buildGlassCard(child: _buildPlanCategories()),
                  const SizedBox(height: 16),
                  _buildGlassCard(child: _buildPlanList()),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPlan,
        backgroundColor: const Color(0xFFE8C4C4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '我的计划',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C2C2C),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              // 显示搜索提示
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('搜索功能开发中...'),
                  backgroundColor: const Color(0xFF007AFF),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: morandiPink.withOpacity(1),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: morandiBlue,
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
      ),
      headerStyle: const HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuickTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷工具',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _quickTools.length,
            itemBuilder: (context, index) {
              final tool = _quickTools[index];
              return GestureDetector(
                onTap: () {
                  if (index == 0) {
                    _addNewPlan();
                  } else if (index == 2) {
                    // 专注计时
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PomodoroTimerPage(),
                      ),
                    );
                  }else if(index==1){
                    // 专注计时
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TodoPage(),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: tool['color'],
                        child: Icon(tool['icon'], color:Color(0xFFFFFFFF)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tool['label'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '计划分类',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _planCategories.length,
          itemBuilder: (context, index) {
            final category = _planCategories[index];
            final categoryCount = _getCategoryCount(category['label']);
            
            return Container(
              decoration: BoxDecoration(
                color: category['bgColor'],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: category['color'].withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: category['color'].withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // 可以添加分类筛选功能
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: category['color'].withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            category['icon'], 
                            color: category['color'], 
                            size: 24
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category['label'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: category['color'],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$categoryCount 个计划',
                          style: TextStyle(
                            fontSize: 12,
                            color: category['color'].withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlanList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '我的计划',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              '${_plans.length} 个计划',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _plans.isEmpty
            ? Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.event_note_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '暂无计划',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _plans.length,
                itemBuilder: (context, index) {
                  final plan = _plans[index];
                  return Dismissible(
                    key: Key(plan['id']),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '删除',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            '确认删除',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          content: Text(
                            '确定要删除"${plan['title']}"吗？',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF666666),
                              height: 1.5,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                '取消',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF8E8E93),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                '删除',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFFF3B30),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      _deletePlan(plan['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('已删除"${plan['title']}"'),
                          backgroundColor: const Color(0xFF34C759),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openPlanDetail(plan),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(plan['status']),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              plan['title'],
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPriorityColor(plan['priority']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              plan['priority'] == 'high' ? '高' : 
                                              plan['priority'] == 'medium' ? '中' : '低',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _getPriorityColor(plan['priority']),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              plan['category'],
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${plan['date'].month}/${plan['date'].day}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(plan['status']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getStatusText(plan['status']),
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _getStatusColor(plan['status']),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _togglePlanStatus(plan['id']),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getStatusColor(plan['status']).withOpacity(0.1),
                                        border: Border.all(
                                          color: _getStatusColor(plan['status']).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        plan['status'] == 'completed' 
                                            ? Icons.check_circle 
                                            : Icons.radio_button_unchecked,
                                        color: _getStatusColor(plan['status']),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}
