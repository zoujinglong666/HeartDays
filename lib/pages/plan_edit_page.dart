import 'package:flutter/material.dart';

class PlanEditPage extends StatefulWidget {
  final Map<String, dynamic>? plan;

  const PlanEditPage({super.key, this.plan});

  @override
  State<PlanEditPage> createState() => _PlanEditPageState();
}

class _PlanEditPageState extends State<PlanEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _selectedPriority;
  late String _selectedStatus;

  final List<Map<String, dynamic>> _categories = [
    {'name': '工作', 'icon': Icons.work, 'color': const Color(0xFFFF3B30)},
    {'name': '学习', 'icon': Icons.school, 'color': const Color(0xFF007AFF)},
    {'name': '健身', 'icon': Icons.fitness_center, 'color': const Color(0xFF34C759)},
    {'name': '生活', 'icon': Icons.favorite, 'color': const Color(0xFFFF2D92)},
  ];

  final List<Map<String, dynamic>> _priorities = [
    {'value': 'low', 'name': '低优先级', 'color': const Color(0xFF34C759)},
    {'value': 'medium', 'name': '中优先级', 'color': const Color(0xFFFF9500)},
    {'value': 'high', 'name': '高优先级', 'color': const Color(0xFFFF3B30)},
  ];

  final List<Map<String, dynamic>> _statuses = [
    {'value': 'pending', 'name': '待开始', 'color': const Color(0xFFFF9500)},
    {'value': 'in_progress', 'name': '进行中', 'color': const Color(0xFF007AFF)},
    {'value': 'completed', 'name': '已完成', 'color': const Color(0xFF34C759)},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.plan?['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.plan?['description'] ?? '');
    _selectedDate = widget.plan?['date'] ?? DateTime.now();
    _selectedCategory = widget.plan?['category'] ?? '工作';
    _selectedPriority = widget.plan?['priority'] ?? 'medium';
    _selectedStatus = widget.plan?['status'] ?? 'pending';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF007AFF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _savePlan() {
    if (_formKey.currentState!.validate()) {
      final planData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'status': _selectedStatus,
        'date': _selectedDate,
      };
      Navigator.pop(context, planData);
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
          padding: const EdgeInsets.all(20),
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
            hintStyle: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 16,
            ),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1A1A1A),
          ),
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
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category['name'];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? category['color'].withOpacity(0.1)
                          : const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? category['color']
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category['icon'],
                          color: isSelected 
                              ? category['color']
                              : const Color(0xFF8E8E93),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          category['name'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? category['color']
                                : const Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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
          ..._priorities.map((priority) => _buildSelectionItem(
            title: priority['name'],
            isSelected: _selectedPriority == priority['value'],
            color: priority['color'],
            onTap: () {
              setState(() {
                _selectedPriority = priority['value'];
              });
            },
          )),
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
          ..._statuses.map((status) => _buildSelectionItem(
            title: status['name'],
            isSelected: _selectedStatus == status['value'],
            color: status['color'],
            onTap: () {
              setState(() {
                _selectedStatus = status['value'];
              });
            },
          )),
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
            color: isSelected 
                ? color.withOpacity(0.1)
                : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? color
                  : Colors.transparent,
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
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected 
                      ? color
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 