import 'package:flutter/material.dart';
import 'package:heart_days/apis/plan.dart';
import 'package:heart_days/components/app_picker/app_picker.dart';
import 'package:heart_days/components/date_picker/date_picker.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:heart_days/utils/dateUtils.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;

  const Category({required this.name, required this.icon, required this.color});
}

class PlanEditPage extends StatefulWidget {
  final Plan? plan;

  const PlanEditPage({super.key, this.plan});

  @override
  State<PlanEditPage> createState() => _PlanEditPageState();
}

class _PlanEditPageState extends State<PlanEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _remarksController;
  late DateTime _selectedDate;
  late DateTime? _selectedReminderTime;
  late DateTime? _selectedCompletedTime;
  late String _selectedCategory;
  late int _selectedPriority;
  late int _selectedStatus;

  final List<Category> _categories = [
    const Category(name: '工作', icon: Icons.work, color: Color(0xFFFF3B30)),
    const Category(name: '学习', icon: Icons.school, color: Color(0xFF007AFF)),
    const Category(
      name: '健身',
      icon: Icons.fitness_center,
      color: Color(0xFF34C759),
    ),
    const Category(name: '生活', icon: Icons.favorite, color: Color(0xFFFF2D92)),
    const Category(name: '娱乐', icon: Icons.games, color: Color(0xFFFF9500)),
    const Category(
      name: '购物',
      icon: Icons.shopping_cart,
      color: Color(0xFF5856D6),
    ),
    const Category(name: '旅行', icon: Icons.flight, color: Color(0xFF32D74B)),
    const Category(
      name: '其他',
      icon: Icons.more_horiz,
      color: Color(0xFF8E8E93),
    ),
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'value': 0, 'name': '低优先级', 'color': const Color(0xFF34C759)},
    {'value': 1, 'name': '中优先级', 'color': const Color(0xFFFF9500)},
    {'value': 2, 'name': '高优先级', 'color': const Color(0xFFFF3B30)},
  ];

  final List<Map<String, dynamic>> _statuses = [
    {'value': 0, 'name': '待开始', 'color': const Color(0xFFFF9500)},
    {'value': 1, 'name': '进行中', 'color': const Color(0xFF007AFF)},
    {'value': 2, 'name': '已完成', 'color': const Color(0xFF34C759)},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plan?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.plan?.description ?? '',
    );
    _remarksController = TextEditingController(
      text: widget.plan?.remarks ?? '',
    );
    _selectedDate = widget.plan?.date ?? DateTime.now();
    _selectedReminderTime = widget.plan?.reminderAt;
    _selectedCompletedTime = widget.plan?.completedAt;
    _selectedCategory = widget.plan?.category ?? '工作';
    _selectedPriority = widget.plan?.priority ?? 1;
    _selectedStatus = widget.plan?.status ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    AppDatePicker.show(
      context: context,
      mode: AppDatePickerMode.startTime,
      initialDateTime: _selectedDate,
      showLaterTime: true,
      onConfirm: (date) {
        setState(() {
          _selectedDate = date;
        });
      },
    );
  }

  Future<void> _selectDateTime(
    BuildContext context, {
    required bool isReminder,
    String? title,
  }) async {
    AppDatePicker.show(
      context: context,
      title: title,
      mode: AppDatePickerMode.editDate,
      onConfirm: (dateTime) {
        setState(() {
          if (isReminder) {
            _selectedReminderTime = dateTime;
          } else {
            _selectedCompletedTime = dateTime;
          }
        });
      },
    );
  }

  void _clearDateTime({required bool isReminder}) {
    setState(() {
      if (isReminder) {
        _selectedReminderTime = null;
      } else {
        _selectedCompletedTime = null;
      }
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    final planData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'category': _selectedCategory,
      'priority': _selectedPriority,
      'status': _selectedStatus,
      'date': _selectedDate.toIso8601String(),
      'reminder_at': _selectedReminderTime?.toIso8601String(),
      'completed_at': _selectedCompletedTime?.toIso8601String(),
      'remarks': _remarksController.text.trim(),
    };

    try {
      dynamic res;
      if (widget.plan != null) {
        // 更新计划，带上 id 和 user_id
        res = await updatePlan({
          ...planData,
          'id': widget.plan!.id,
          'user_id': widget.plan!.userId,
        });
      } else {
        // 新增计划
        res = await addPlan(planData);
      }

      if (res != null) {
        // 成功后关闭页面并返回服务器响应的数据
        Navigator.pop(context, true); // 只pop当前页面，避免页面栈混乱
      } else {
        // 返回为空，可视需要做处理
        // 例如弹toast提示失败
      }
    } catch (e) {
      ToastUtils.showToast('保存失败，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.plan == null ? '新建计划' : '编辑计划',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _savePlan,
            child: const Text(
              '保存',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoCard(),
              const SizedBox(height: 16),
              _buildCategoryCard(),
              const SizedBox(height: 16),
              _buildPriorityCard(),
              const SizedBox(height: 16),
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildTimeSettingsCard(),
              const SizedBox(height: 16),
              _buildRemarksCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基本信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _titleController,
            label: '计划标题',
            hint: '请输入计划标题',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '请输入计划标题';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: '计划描述',
            hint: '请输入计划描述（可选）',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildDateSelector(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 16),
            filled: true,
            fillColor: const Color(0xFFF2F2F7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '计划日期',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF007AFF),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF8E8E93),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 日期选择器
  Widget _buildCategorySelector() {
    return InkWell(
      onTap: () {
        AppPicker.show<String>(
          context: context,
          options: _categories.map((item) => item.name).toList(),
          title: '选择分类',
          initialValue: _selectedCategory,
          onConfirm: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.category, color: Color(0xFF007AFF), size: 20),
            const SizedBox(width: 16),
            Text(
              _selectedCategory,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择分类',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildCategorySelector(),
          // GridView.builder(
          //   physics: const NeverScrollableScrollPhysics(),
          //   shrinkWrap: true,
          //   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //     crossAxisCount: 2,
          //     crossAxisSpacing: 12,
          //     mainAxisSpacing: 12,
          //     childAspectRatio: 2.5,
          //   ),
          //   itemCount: _categories.length,
          //   itemBuilder: (context, index) {
          //     final category = _categories[index];
          //     final isSelected = _selectedCategory == category.name;
          //     return Material(
          //       color: Colors.transparent,
          //       child: InkWell(
          //         onTap: () {
          //           setState(() {
          //             _selectedCategory = category.name;
          //           });
          //         },
          //         borderRadius: BorderRadius.circular(12),
          //         child: Container(
          //           decoration: BoxDecoration(
          //             color:
          //                 isSelected
          //                     ? category.color.withOpacity(0.1)
          //                     : const Color(0xFFF2F2F7),
          //             borderRadius: BorderRadius.circular(12),
          //             border: Border.all(
          //               color: isSelected ? category.color : Colors.transparent,
          //               width: 2,
          //             ),
          //           ),
          //           child: Row(
          //             mainAxisAlignment: MainAxisAlignment.center,
          //             children: [
          //               Icon(
          //                 category.icon,
          //                 color:
          //                     isSelected
          //                         ? category.color
          //                         : const Color(0xFF8E8E93),
          //                 size: 20,
          //               ),
          //               const SizedBox(width: 8),
          //               Text(
          //                 category.name,
          //                 style: TextStyle(
          //                   fontSize: 14,
          //                   fontWeight: FontWeight.w600,
          //                   color:
          //                       isSelected
          //                           ? category.color
          //                           : const Color(0xFF1A1A1A),
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildPriorityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '优先级',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          ..._priorities.map(
            (priority) => _buildSelectionItem(
              title: priority['name'],
              isSelected: _selectedPriority == priority['value'],
              color: priority['color'],
              onTap: () {
                setState(() {
                  _selectedPriority = priority['value'];
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '状态',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          ..._statuses.map(
            (status) => _buildSelectionItem(
              title: status['name'],
              isSelected: _selectedStatus == status['value'],
              color: status['color'],
              onTap: () {
                setState(() {
                  _selectedStatus = status['value'];
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSettingsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '时间设置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildDateTimeSelector(
            label: '提醒时间',
            selectedDateTime: _selectedReminderTime,
            onTap:
                () =>
                    _selectDateTime(context, isReminder: true, title: "编辑提醒时间"),
            onClear: () => _clearDateTime(isReminder: true),
            icon: Icons.notifications_outlined,
          ),
          const SizedBox(height: 16),
          _buildDateTimeSelector(
            label: '完成时间',
            selectedDateTime: _selectedCompletedTime,
            onTap:
                () => _selectDateTime(
                  context,
                  isReminder: false,
                  title: "编辑完成时间",
                ),
            onClear: () => _clearDateTime(isReminder: false),
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector({
    required String label,
    required DateTime? selectedDateTime,
    required VoidCallback onTap,
    required VoidCallback onClear,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF007AFF), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDateTime != null
                          ? formatDateTime(selectedDateTime)
                          : '点击设置$label',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            selectedDateTime != null
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                  if (selectedDateTime != null)
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(
                        Icons.clear,
                        color: Color(0xFF8E8E93),
                        size: 20,
                      ),
                    )
                  else
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF8E8E93),
                      size: 16,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '备注信息',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _remarksController,
            hint: '请输入备注信息（可选）',
            maxLines: 4,
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionItem({
    required String title,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withOpacity(0.1) : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFF8E8E93),
                    width: 2,
                  ),
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? color : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
