import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heart_days/apis/plan.dart';
import 'package:heart_days/pages/todo_page.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  List<Plan> _plans = [];
  bool _isRefreshing = false;

  final List<Map<String, dynamic>> _quickTools = [
    {
      'icon': Icons.event_note,
      'label': '添加计划',
      'color': const Color(0xFFFF6B6B),
      'onTap': () {},
    },
    {
      'icon': Icons.check_circle_outline,
      'label': '待办事项',
      'color': const Color(0xFF4ECDC4),
    },
    {'icon': Icons.timer, 'label': '专注计时', 'color': const Color(0xFF45B7D1)},
    {
      'icon': Icons.insert_chart,
      'label': '统计分析',
      'color': const Color(0xFF96CEB4),
    },
  ];


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 刷新数据
  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    await _loadData();
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authDataString = prefs.getString('auth_data');
      if (authDataString == null) {
        setState(() => _plans = []);
        return;
      }
      final Map<String, dynamic> authMap = jsonDecode(authDataString);
      final authState = AuthState.fromJson(authMap);
      if (authState.user?.id == null) {
        setState(() => _plans = []);
        return;
      }

      final response = await fetchPlanListByUserId({
        "page": 1,
        "pageSize": 10,
        "userId": authState.user?.id,
      });
      setState(() => _plans = response.data!.records);
    } catch (e) {
      setState(() => _plans = []);
    }
  }

  // 获取状态颜色
  Color _getStatusColor(PlanStatus status) {
    switch (status) {
      case PlanStatus.pending:
        return Colors.orange;
      case PlanStatus.inProgress:
        return Colors.blue;
      case PlanStatus.completed:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 获取优先级颜色
  Color _getPriorityColor(PlanPriority priority) {
    switch (priority) {
      case PlanPriority.high:
        return Colors.red;
      case PlanPriority.medium:
        return Colors.orange;
      case PlanPriority.low:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // 获取状态文本
  String _getStatusText(PlanStatus status) {
    switch (status) {
      case PlanStatus.pending:
        return '待开始';
      case PlanStatus.inProgress:
        return '进行中';
      case PlanStatus.completed:
        return '已完成';
      default:
        return '未知';
    }
  }

  // 切换计划状态
  Future<void> _togglePlanStatus(Plan plan) async {
    final res = await updatePlanStatus({"id": plan.id, "status": plan.status});
    setState(() {
      final planIndex = _plans.indexWhere((item) => item.id == plan.id);
      if (planIndex != -1) {
        _plans[planIndex] = res.data!;
      }
    });
  }

  // 打开计划详情页面
  void _openPlanDetail(Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlanDetailPage(plan: plan)),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        if (result['action'] == 'delete') {
          _deletePlan(result['planId']);
          ToastUtils.showToast('已删除"${plan.title}"');
        }
      }
    });
  }

  // 添加新计划
  void _addNewPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlanEditPage()),
    ).then((result) {
      if (result != null) {
        setState(() {});
      }
    });
  }

  // 删除计划
  Future<void> _deletePlan(int planId) async {
    setState(() {
      _plans.removeWhere((plan) => plan.id == planId);
    });
    await planDeleteById(planId);
  }


  String priorityLabelFromInt(int value) {
    switch (intToPriority(value)) {
      case PlanPriority.high:
        return '高';
      case PlanPriority.medium:
        return '中';
      case PlanPriority.low:
      default:
        return '低';
    }
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
                _buildGlassCard(child: _buildPlanListWithRefresh()),
              ],
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
          gradient: const LinearGradient(
            colors: [Color(0xFFF48FB1), Color(0xFFCE93D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF48FB1).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        selectedDecoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF64B5F6), Color(0xFF5C6BC0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64B5F6).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        todayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        markersMaxCount: 3,
        markerDecoration: BoxDecoration(
          color: const Color(0xFFE8C4C4),
          shape: BoxShape.circle,
        ),
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
                  } else if (index == 1) {
                    // 待办事项
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TodoPage()),
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
                        radius: 24,
                        backgroundColor: tool['color'],
                        child: Icon(tool['icon'], color: Color(0xFFFFFFFF)),
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

  Widget _buildPlanListWithRefresh() {
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
            Row(
              children: [
                Text(
                  '${_plans.length} 个计划',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isRefreshing ? null : _refreshData,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        _isRefreshing
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            )
                            : const Icon(
                              Icons.refresh,
                              size: 16,
                              color: Colors.blue,
                            ),
                  ),
                ),
              ],
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
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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
                  key: Key(plan.id.toString()),
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
                            Icon(Icons.delete, color: Colors.white, size: 24),
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
                      builder:
                          (context) => AlertDialog(
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
                              '确定要删除"${plan.title}"吗？',
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
                    _deletePlan(plan.id);
                    ToastUtils.showToast('已删除"${plan.title}"');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
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
                                  color: _getStatusColor(
                                    intToStatus(plan.status),
                                  ),
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
                                            plan.title,
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
                                            color: _getPriorityColor(
                                              intToPriority(plan.priority),
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            priorityLabelFromInt(plan.priority),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _getPriorityColor(
                                                intToPriority(plan.priority),
                                              ),
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            plan.category as String,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${plan.date.month}/${plan.date.day}',
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
                                            color: _getStatusColor(
                                              intToStatus(plan.status),
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusText(
                                              intToStatus(plan.status),
                                            ),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _getStatusColor(
                                                intToStatus(plan.status),
                                              ),
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
                                  onTap: () => _togglePlanStatus(plan),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getStatusColor(
                                        intToStatus(plan.status),
                                      ).withOpacity(0.1),
                                      border: Border.all(
                                        color: _getStatusColor(
                                          intToStatus(plan.status),
                                        ).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      intToStatus(plan.status) ==
                                              PlanStatus.completed
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: _getStatusColor(
                                        intToStatus(plan.status),
                                      ),
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
