import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_days/http/model/Anniversary.dart';
import 'package:heart_days/utils/Notifier.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddAnniversaryPage extends StatefulWidget {
  final Anniversary? anniversaryItem;

  const AddAnniversaryPage({super.key, this.anniversaryItem});

  @override
  State<AddAnniversaryPage> createState() => _AddAnniversaryPageState();
}

class _AddAnniversaryPageState extends State<AddAnniversaryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedIcon = "💖";
  String _selectedType = "纪念日"; // 默认类型为纪念日
  bool _isYearly = false;
  bool _isMonthly = false;
  bool _isWeekly = false;
  bool _isDaily = false;
  bool _isPinned = false; // 是否置顶
  bool _isHighlighted = false; // 是否高亮
  Color _selectedColor = const Color(0xFF90CAF9);

  // 预设类型列表
  final List<String> _typeOptions = ["纪念日", "倒数日", "生活", "工作", "学习"];

  // 预设图标列表 - 按分类组织
  final Map<String, List<String>> _categorizedIcons = {
    "情感": ["💖", "💕", "💓", "💗", "💘", "💝", "💑", "👩‍❤️‍👨", "💍", "🌹"],
    "庆祝": ["🎂", "🎉", "🎊", "🎁", "🎈", "🎆", "🎇", "✨", "🎀", "🏆"],
    "生活": ["🏠", "🛌", "🛁", "🚗", "🍽️", "👕", "👟", "💰", "📱", "⏰"],
    "工作": ["💼", "💻", "📊", "📈", "📝", "✏️", "📌", "📁", "🔍", "🔧"],
    "学习": ["📚", "🎓", "✍️", "🔬", "🔭", "🧮", "🎯", "📖", "🧠", "🎨"],
    "旅行": ["✈️", "🏝️", "🏔️", "🗺️", "🧳", "🏕️", "🚆", "🚢", "🚶", "🧭"],
    "健康": ["🏃", "🏋️", "🧘", "🍎", "💊", "🩺", "💉", "🥗", "💧", "🌿"],
    "娱乐": ["🎵", "🎬", "🎮", "🎭", "🎧", "📺", "🎪", "🎤", "🎸", "🎲"],
  };

  // 当前选中的图标分类
  String _currentIconCategory = "情感";

  // 获取当前分类的图标列表
  List<String> get _currentCategoryIcons =>
      _categorizedIcons[_currentIconCategory] ?? [];

  // 预设颜色列表
  final List<Color> _colorOptions = [
    const Color(0xFFF48FB1), // 粉色
    const Color(0xFFCE93D8), // 紫色
    const Color(0xFF90CAF9), // 蓝色
    const Color(0xFF80DEEA), // 青色
    const Color(0xFFA5D6A7), // 绿色
    const Color(0xFFFFCC80), // 橙色
    const Color(0xFFFFAB91), // 橘红色
    const Color(0xFFE6EE9C), // 黄绿色
    const Color(0xFF9FA8DA), // 靛蓝色
    const Color(0xFFB39DDB), // 深紫色
    const Color(0xFFFFAB40), // 琥珀色
    const Color(0xFF4DB6AC), // 蓝绿色
  ];

  Future<void> saveAnniversaryToLocal(
    Map<String, dynamic> newAnniversary,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'anniversaries';

    // 获取已存的数据
    final String? rawList = prefs.getString(key);
    List<Map<String, dynamic>> anniversaryList = [];

    if (rawList != null) {
      final List<dynamic> decoded = json.decode(rawList);
      anniversaryList = decoded.cast<Map<String, dynamic>>();
    }

    // 添加新数据
    anniversaryList.add(newAnniversary);

    // 保存
    await prefs.setString(key, json.encode(anniversaryList));
  }

  @override
  void initState() {
    super.initState();

    // 初始化标题
    _titleController = TextEditingController(
      text: widget.anniversaryItem?.title ?? '',
    );

    // 初始化描述
    _descriptionController.text = widget.anniversaryItem?.description ?? '';

    // 初始化日期
    _selectedDate = widget.anniversaryItem?.date ?? DateTime.now();

    // 初始化图标
    _selectedIcon = widget.anniversaryItem?.icon ?? '💖';

    // 初始化类型
    _selectedType = widget.anniversaryItem?.selectedType ?? '纪念日';


    // 初始化置顶 & 高亮
    _isPinned = widget.anniversaryItem?.isPinned ?? false;
    _isHighlighted = widget.anniversaryItem?.isHighlighted ?? false;

    // 初始化颜色
    _selectedColor = widget.anniversaryItem?.color ?? const Color(0xFF90CAF9);

    // 如果图标有分类，尝试反推分类（可选）
    for (final entry in _categorizedIcons.entries) {
      if (entry.value.contains(_selectedIcon)) {
        _currentIconCategory = entry.key;
        break;
      }
    }
  }


  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 选择日期
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 设置为true，让Scaffold自动调整大小以避免键盘遮挡
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _selectedType == "倒数日" ? "添加倒数日" : "添加纪念日",
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),

        actions: [
          TextButton.icon(
            onPressed: () async {
              if (_titleController.text.trim() == "") {
                _titleController.text = "";
                ToastUtils.showToast("请输入标题");
                return;
              }

              if (_formKey.currentState!.validate()) {
                final newAnniversary = Anniversary(
                  id: widget.anniversaryItem?.id ?? DateTime.now().millisecondsSinceEpoch.toString(), // ✅ 若为编辑，则保留原 id
                  title: _titleController.text,
                  date: _selectedDate,
                  selectedType: _selectedType,
                  icon: _selectedIcon,
                  description: _descriptionController.text,
                  color: _selectedColor,
                  type: _selectedType,
                  isPinned: _isPinned,
                  isHighlighted: _isHighlighted,
                  repetitiveType: "",
                );

                final prefs = await SharedPreferences.getInstance();
                final raw = prefs.getString('anniversaries');
                List<Map<String, dynamic>> list = [];

                if (raw != null) {
                  final decoded = json.decode(raw) as List;
                  list = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
                }

                // ✅ 判断是新增还是编辑
                if (widget.anniversaryItem != null) {
                  // 编辑：找到并替换原数据
                  final index = list.indexWhere((e) => e['id'] == widget.anniversaryItem!.id);
                  if (index != -1) {
                    list[index] = newAnniversary.toJson();
                  }
                } else {
                  // 新增：直接添加
                  list.add(newAnniversary.toJson());
                }

                await prefs.setString('anniversaries', json.encode(list));

                ToastUtils.showToast("保存成功");
                notifier.value = 'anniversary_added';
                Navigator.of(context).pop();
              }

            },
            label: Text(
              "保存",
              style: TextStyle(
                color: _selectedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                // padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // 底部留出保存按钮的空间
                children: [
                  // 顶部预览卡片
                  _buildPreviewCard(),
                  const SizedBox(height: 24),

                  // 类型选择
                  _buildSectionTitle("类型"),
                  _buildTypeSelector(),
                  const SizedBox(height: 20),

                  // 标题输入
                  _buildSectionTitle("标题"),
                  _buildTextField(
                    controller: _titleController,
                    hintText:
                        _selectedType == "倒数日"
                            ? " 例如：距离考试还有、距离生日还有"
                            : "例如：恋爱纪念日、结婚纪念日 ",
                    prefixIcon: Icons.title,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "请输入标题";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // 日期选择
                  _buildSectionTitle("日期"),
                  _buildDateSelector(),
                  const SizedBox(height: 20),

                  // 图标分类选择
                  _buildSectionTitle("选择图标"),
                  _buildIconCategorySelector(),
                  const SizedBox(height: 10),
                  _buildIconSelector(),
                  const SizedBox(height: 20),

                  // 颜色选择
                  _buildSectionTitle("选择颜色"),
                  _buildColorSelector(),
                  const SizedBox(height: 20),

                  // 描述输入
                  _buildSectionTitle("描述（可选）"),
                  _buildTextField(
                    controller: _descriptionController,
                    hintText: "添加一些描述...",
                    prefixIcon: Icons.description,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // 置顶选项
                  _buildToggleOption(
                    title: "置顶",
                    icon: Icons.push_pin,
                    value: _isPinned,
                    onChanged: (value) {
                      setState(() {
                        _isPinned = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // 高亮选项
                  _buildToggleOption(
                    title: "高亮显示",
                    icon: Icons.highlight,
                    value: _isHighlighted,
                    onChanged: (value) {
                      setState(() {
                        _isHighlighted = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // 重复选项
                  _buildSectionTitle("重复"),
                  _buildRepeatOptions(),
                  const SizedBox(height: 80), // 为底部按钮留出空间
                ],
              ),

              // 固定在底部的保存按钮
              // Positioned(
              //   left: 0,
              //   right: 0,
              //   bottom: 20,
              //   child: Container(
              //     decoration: BoxDecoration(color: Colors.white),
              //     padding: const EdgeInsets.symmetric(vertical: 10),
              //     child: _buildSaveButton(),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // 预览卡片
  Widget _buildPreviewCard() {
    final daysLeft = _selectedDate.difference(DateTime.now()).inDays;
    final isInFuture = daysLeft >= 0;
    final daysText = isInFuture ? "还有 ${daysLeft + 1} 天" : "已过去 ${-daysLeft} 天";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_selectedColor.withOpacity(0.7), _selectedColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                  _selectedIcon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleController.text.isEmpty
                          ? "标题"
                          : _titleController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('yyyy年MM月dd日').format(_selectedDate),
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
          if (_descriptionController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _descriptionController.text,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ],
          if (_isPinned ||
              _isHighlighted ||
              _isYearly ||
              _isMonthly ||
              _isWeekly ||
              _isDaily) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isPinned) _buildTagChip("置顶", Icons.push_pin),
                if (_isHighlighted) _buildTagChip("高亮", Icons.highlight),
                if (_isDaily) _buildTagChip("每天", Icons.repeat),
                if (_isWeekly) _buildTagChip("每周", Icons.repeat),
                if (_isMonthly) _buildTagChip("每月", Icons.repeat),
                if (_isYearly) _buildTagChip("每年", Icons.repeat),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 标签小组件
  Widget _buildTagChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 小节标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // 文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(prefixIcon, color: _selectedColor),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  // 类型选择器
  Widget _buildTypeSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        itemCount: _typeOptions.length,
        itemBuilder: (context, index) {
          final type = _typeOptions[index];
          final isSelected = type == _selectedType;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedType = type;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? _selectedColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: _selectedColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
                border:
                    isSelected ? null : Border.all(color: Colors.grey.shade200),
              ),
              alignment: Alignment.center,
              child: Text(
                type,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 日期选择器
  Widget _buildDateSelector() {
    return InkWell(
      onTap: () => _selectDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: _selectedColor),
            const SizedBox(width: 16),
            Text(
              DateFormat('yyyy年MM月dd日').format(_selectedDate),
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

  // 图标分类选择器
  Widget _buildIconCategorySelector() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        itemCount: _categorizedIcons.keys.length,
        itemBuilder: (context, index) {
          final category = _categorizedIcons.keys.elementAt(index);
          final isSelected = category == _currentIconCategory;

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentIconCategory = category;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? _selectedColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: _selectedColor.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
                border:
                    isSelected ? null : Border.all(color: Colors.grey.shade200),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 图标选择器
  Widget _buildIconSelector() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        itemCount: _currentCategoryIcons.length,
        itemBuilder: (context, index) {
          final icon = _currentCategoryIcons[index];
          final isSelected = icon == _selectedIcon;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIcon = icon;
              });
            },
            child: Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? _selectedColor : Colors.white,
                shape: BoxShape.circle,
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: _selectedColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
                border:
                    isSelected ? null : Border.all(color: Colors.grey.shade200),
              ),
              alignment: Alignment.center,
              child: Text(icon, style: TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }

  // 颜色选择器
  Widget _buildColorSelector() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        itemCount: _colorOptions.length,
        itemBuilder: (context, index) {
          final color = _colorOptions[index];
          final isSelected = color == _selectedColor;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedColor = color;
              });
            },
            child: Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border:
                    isSelected
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
              ),
            ),
          );
        },
      ),
    );
  }

  // 开关选项
  Widget _buildToggleOption({
    required String title,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: _selectedColor),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _selectedColor,
          ),
        ],
      ),
    );
  }

  // 重复选项
  Widget _buildRepeatOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildRepeatOption("每天重复", _isDaily, (value) {
            setState(() {
              _isDaily = value;
              // 如果选择了每天，其他选项自动取消
              if (value) {
                _isWeekly = false;
                _isMonthly = false;
                _isYearly = false;
              }
            });
          }),
          const Divider(height: 24),
          _buildRepeatOption("每周重复", _isWeekly, (value) {
            setState(() {
              _isWeekly = value;
              // 如果选择了每周，其他选项自动取消
              if (value) {
                _isDaily = false;
                _isMonthly = false;
                _isYearly = false;
              }
            });
          }),
          const Divider(height: 24),
          _buildRepeatOption("每月重复", _isMonthly, (value) {
            setState(() {
              _isMonthly = value;
              // 如果选择了每月，其他选项自动取消
              if (value) {
                _isDaily = false;
                _isWeekly = false;
                _isYearly = false;
              }
            });
          }),
          const Divider(height: 24),
          _buildRepeatOption("每年重复", _isYearly, (value) {
            setState(() {
              _isYearly = value;
              // 如果选择了每年，其他选项自动取消
              if (value) {
                _isDaily = false;
                _isWeekly = false;
                _isMonthly = false;
              }
            });
          }),
        ],
      ),
    );
  }

  // 单个重复选项
  Widget _buildRepeatOption(
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Icon(Icons.repeat, color: _selectedColor),
        const SizedBox(width: 16),
        Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const Spacer(),
        Switch(value: value, onChanged: onChanged, activeColor: _selectedColor),
      ],
    );
  }

  // 保存按钮
  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          final newAnniversary = Anniversary(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: _titleController.text,
            selectedType: _selectedType,
            date: _selectedDate,
            icon: _selectedIcon,
            description: _descriptionController.text,
            color: _selectedColor,
            type: _selectedType,
            isPinned: _isPinned,
            isHighlighted: _isHighlighted,
            repetitiveType: "",
          );

          // 🔸 保存到本地
          await saveAnniversaryToLocal(newAnniversary.toJson());

          // 添加成功后发出事件
          notifier.value = 'anniversary_added';
          // 返回上一页
          ToastUtils.showToast("保存成功");

          Navigator.of(context).pop();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        minimumSize: const Size(double.infinity, 56), // 确保按钮足够高
      ),
      child: const Text(
        "保存",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
