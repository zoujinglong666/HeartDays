import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/components/date_picker/date_picker.dart';
import 'package:heart_days/providers/todo_provider.dart';
import 'package:heart_days/theme/neumorphic_theme.dart';
import 'package:heart_days/widgets/draggable_todo_item.dart';
import 'package:heart_days/widgets/neumorphic_box.dart';
import 'package:reorderables/reorderables.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  final TextEditingController _controller = TextEditingController();
  TodoItem? _draggedItem;
  TodoItem? _targetParent;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    ref.read(todoProvider.notifier).refresh();
  }

  // 显示添加子任务的对话框
  Future<void> _showAddChildDialog(BuildContext context, TodoItem parent) async {
    final TextEditingController titleController = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectReminderAt;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 在显示日期选择器时自动隐藏键盘
            void showDatePicker() {
              // 先隐藏键盘
              FocusScope.of(context).unfocus();

              // 延迟一下再显示日期选择器，确保键盘完全收起
              Future.delayed(const Duration(milliseconds: 100), () {
                AppDatePicker.show(
                  context: context,
                  mode: AppDatePickerMode.editDate,
                  initialDateTime: selectReminderAt,
                  onConfirm: (dateTime) {
                    setState(() {
                      selectReminderAt = dateTime;
                    });
                  },
                );
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 标题
                      Row(
                        children: [
                          const Icon(Icons.add_task, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            '添加子任务',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // 关闭按钮
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 标题输入框
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: '子任务标题',
                          prefixIcon: const Icon(Icons.title, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),

                      // 日期选择按钮
                      InkWell(
                        onTap: showDatePicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectReminderAt != null
                                      ? '${selectReminderAt!.year}/${selectReminderAt!.month.toString().padLeft(2, '0')}/${selectReminderAt!.day.toString().padLeft(2, '0')} '
                                        '${selectReminderAt!.hour.toString().padLeft(2, '0')}:${selectReminderAt!.minute.toString().padLeft(2, '0')}'
                                      : '设置提醒时间（可选）',
                                  style: TextStyle(
                                    color: selectReminderAt != null ? Colors.black87 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 优先级选择
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '优先级',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ...[
                                {'label': '低', 'value': 'low'},
                                {'label': '中', 'value': 'medium'},
                                {'label': '高', 'value': 'high'},
                              ].map((priority) => _buildPriorityOption(
                                context,
                                priority['label']!,
                                priority['value']!,
                                selectedPriority,
                                (val) {
                                  setState(() => selectedPriority = val);
                                },
                              )).toList(),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 操作按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (titleController.text.trim().isNotEmpty) {
                                ref.read(todoProvider.notifier).addChildTodoWithDetails(
                                  parent,
                                  titleController.text.trim(),
                                  selectedPriority,
                                  selectReminderAt,
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('添加'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 开始拖拽
  void _onDragStarted(TodoItem item) {
    setState(() {
      _draggedItem = item;
      _isDragging = true;
    });
  }

  // 接受拖拽
  void _onAccept(TodoItem? newParent) {
    if (_draggedItem != null) {
      // 如果拖到了新的父级，则移动到该父级下
      ref.read(todoProvider.notifier).moveTodoToParent(_draggedItem!, newParent);
      setState(() {
        _draggedItem = null;
        _targetParent = null;
        _isDragging = false;
      });
    }
  }

  // 拖拽进入目标区域
  void _onDragEntered(TodoItem? newParent) {
    if (newParent != null && newParent.id != _draggedItem?.id) {
      setState(() {
        _targetParent = newParent;
        // 自动展开目标节点
        if (!newParent.expanded && newParent.children.isNotEmpty) {
          ref.read(todoProvider.notifier).toggleExpanded(newParent);
        }
      });
    }
  }

  // 拖拽离开目标区域
  void _onDragExited() {
    setState(() {
      _targetParent = null;
    });
  }

  // 显示添加根任务的对话框
  Future<void> _showAddRootTaskDialog(BuildContext context) async {
    final TextEditingController titleController = TextEditingController();
    String selectedPriority = 'medium';
    DateTime? selectReminderAt;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 在显示日期选择器时自动隐藏键盘
            void showDatePicker() {
              // 先隐藏键盘
              FocusScope.of(context).unfocus();

              // 延迟一下再显示日期选择器，确保键盘完全收起
              Future.delayed(const Duration(milliseconds: 100), () {
                AppDatePicker.show(
                  context: context,
                  mode: AppDatePickerMode.editDate,
                  initialDateTime: selectReminderAt,
                  onConfirm: (dateTime) {
                    setState(() {
                      selectReminderAt = dateTime;
                    });
                  },
                );
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 标题
                      Row(
                        children: [
                          const Icon(Icons.add_circle_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            '添加新任务',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          // 关闭按钮
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 标题输入框
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: '任务标题',
                          prefixIcon: const Icon(Icons.title, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),

                      // 日期选择按钮
                      InkWell(
                        onTap: showDatePicker,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade50,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectReminderAt != null
                                      ? '${selectReminderAt!.year}/${selectReminderAt!.month.toString().padLeft(2, '0')}/${selectReminderAt!.day.toString().padLeft(2, '0')} '
                                        '${selectReminderAt!.hour.toString().padLeft(2, '0')}:${selectReminderAt!.minute.toString().padLeft(2, '0')}'
                                      : '设置提醒时间（可选）',
                                  style: TextStyle(
                                    color: selectReminderAt != null ? Colors.black87 : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 优先级选择
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '优先级',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ...[
                                {'label': '低', 'value': 'low'},
                                {'label': '中', 'value': 'medium'},
                                {'label': '高', 'value': 'high'},
                              ].map((priority) => _buildPriorityOption(
                                context,
                                priority['label']!,
                                priority['value']!,
                                selectedPriority,
                                (val) {
                                  setState(() => selectedPriority = val);
                                },
                              )).toList(),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 操作按钮
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (titleController.text.trim().isNotEmpty) {
                                ref.read(todoProvider.notifier).addRootTodoWithDetails(
                                  titleController.text.trim(),
                                  selectedPriority,
                                  selectReminderAt,
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('添加'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 构建优先级选项
  Widget _buildPriorityOption(BuildContext context, String label, String value, 
      String groupValue, Function(String) onChanged) {
    final isSelected = value == groupValue;
    final color = _getPriorityColor(value);
    
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : color.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return NeumorphicTheme.highPriorityColor;
      case 'medium':
        return NeumorphicTheme.mediumPriorityColor;
      case 'low':
      default:
        return NeumorphicTheme.lowPriorityColor;
    }
  }
  // 构建可拖拽的Todo列表
  Widget _buildDraggableTodoList(List<TodoItem> todos) {
    return ReorderableColumn(
      onReorder: (oldIndex, newIndex) {
        ref.read(todoProvider.notifier).reorderTodos(oldIndex, newIndex);
      },
      // 启用拖拽功能
      needsLongPressDraggable: true,
      children: todos.asMap().entries.map((entry) {
        final int index = entry.key;
        final TodoItem item = entry.value;
        return DraggableTodoItem(
          key: ValueKey(item.id),
          item: item,
          onAddChild: _showAddChildDialog,
          index: index, // 传递根项在列表中的索引
        );
      }).toList(),
    );
  }
  // 构建根级拖放区域
  Widget _buildRootDragTarget() {
    return DragTarget<TodoItem>(
      onWillAccept: (data) => data != null && data.parentId != null, // 只接受非根级别的项
      onAccept: (data) => _onAccept(null),
      builder: (context, candidateData, rejectedData) {
        final bool isTargeted = _targetParent == null && _isDragging;
        return AnimatedContainer(
          duration: NeumorphicTheme.dragHighlightDuration,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isTargeted
                ? Border.all(color: NeumorphicTheme.accentColor, width: 2)
                : null,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: isTargeted
                ? Center(
                    child: Text(
                      '拖放到此处移动到根级别',
                      style: TextStyle(color: NeumorphicTheme.accentColor),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todos = ref.watch(todoProvider);
    
    return Scaffold(
      backgroundColor: NeumorphicTheme.background,
      appBar: AppBar(
        title: const Text('待办事项', style: TextStyle(
            color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await ref.read(todoProvider.notifier).refresh();
            },
          )
        ],
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      // 悬浮按钮 - 添加根任务
      floatingActionButton: NeumorphicBox(
        width: 56,
        height: 56,
        borderRadius: 28,
        type: NeumorphicType.convex,
        color: NeumorphicTheme.accentColor.withOpacity(0.1),
        padding: EdgeInsets.zero,
        child: Icon(Icons.add, color: NeumorphicTheme.accentColor),
        onTap: () {
          _showAddRootTaskDialog(context);
        },
      ),
      body: todos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('暂无待办事项',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('点击右下角按钮添加你的第一个待办吧~',
                      style: TextStyle(fontSize: 13, color: Color(0xFFBDBDBD))),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  if (_isDragging) _buildRootDragTarget(),
                  if (_isDragging) const SizedBox(height: 12),
                  Expanded(
                    child: _buildDraggableTodoList(todos),
                  ),
                ],
              ),
            ),
    );
  }
}