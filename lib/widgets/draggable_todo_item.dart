import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:heart_days/components/date_picker/date_picker.dart';
import 'package:heart_days/providers/todo_provider.dart';
import 'package:heart_days/theme/neumorphic_theme.dart';
import 'package:heart_days/widgets/neumorphic_box.dart';
import 'package:heart_days/widgets/reorderable_column.dart';

class DraggableTodoItem extends ConsumerWidget {
  final TodoItem item;
  final double leftPadding;
  final Function(BuildContext, TodoItem) onAddChild;
  final bool isDragging;
  final int? index; // 在父项子列表中的索引

  const DraggableTodoItem({
    super.key,
    required this.item,
    this.leftPadding = 0,
    required this.onAddChild,
    this.isDragging = false,
    this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoNotifier = ref.read(todoProvider.notifier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Todo项
        AnimatedOpacity(
          opacity: isDragging ? 0.6 : 1.0,
          duration: NeumorphicTheme.dragHighlightDuration,
          child: Slidable(
            // 左滑动作 - 完成和优先级
            startActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.5,
              children: [
                SlidableAction(
                  onPressed: (_) => todoNotifier.toggleDone(item),
                  backgroundColor: item.done 
                    ? NeumorphicTheme.mediumPriorityColor.withOpacity(0.2)
                    : NeumorphicTheme.highPriorityColor.withOpacity(0.2),
                  foregroundColor: item.done 
                    ? NeumorphicTheme.mediumPriorityColor
                    : NeumorphicTheme.highPriorityColor,
                  icon: item.done ? Icons.replay : Icons.check_circle_outline,
                  label: item.done ? '撤销' : '完成',
                  flex: 1,
                ),
                SlidableAction(
                  onPressed: (_) => todoNotifier.togglePriority(item),
                  backgroundColor: _getPriorityColor(item.priority).withOpacity(0.2),
                  foregroundColor: _getPriorityColor(item.priority),
                  icon: Icons.flag,
                  label: '优先级',
                  flex: 1,
                ),
              ],
            ),
            // 右滑动作 - 删除和编辑
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.5,
              children: [
                SlidableAction(
                  onPressed: (_) => todoNotifier.deleteTodo(item),
                  backgroundColor: NeumorphicTheme.highPriorityColor.withOpacity(0.2),
                  foregroundColor: NeumorphicTheme.highPriorityColor,
                  icon: Icons.delete_outline,
                  label: '删除',
                  flex: 1,
                ),
                SlidableAction(
                  onPressed: (_) => _showEditDialog(context, ref, item),
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  foregroundColor: Colors.blue,
                  icon: Icons.edit,
                  label: '编辑',
                  flex: 1,
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.only(left: leftPadding),
              width: MediaQuery.of(context).size.width,
              child: NeumorphicBox(
                type: item.done ? NeumorphicType.pressed : NeumorphicType.flat,
                color: NeumorphicTheme.background,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: NeumorphicCheckbox(
                          value: item.done,
                          onChanged: (_) => todoNotifier.toggleDone(item),
                          activeColor: NeumorphicTheme.getPriorityColor(item.priority),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: item.done ? Colors.grey : Colors.black87,
                            decoration: item.done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 优先级标签
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: NeumorphicTheme.getPriorityGradient(item.priority),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.priority == 'high' ? '高' : item.priority == 'medium' ? '中' : '低',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 添加子任务按钮
                            _buildNeumorphicIconButton(
                              icon: Icons.add,
                              onTap: () => onAddChild(context, item),
                            ),
                            // 展开/折叠按钮（仅当有子项时显示）
                            if (item.children.isNotEmpty)
                              _buildNeumorphicIconButton(
                                icon: item.expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                onTap: () => todoNotifier.toggleExpanded(item),
                              ),
                            // 拖拽手柄
                            _buildDragHandle(context),
                          ],
                        ),
                        // onLongPress: () => todoNotifier.togglePriority(item),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 子项（如果展开）
        if (item.expanded && item.children.isNotEmpty)
          AnimatedSize(
            duration: NeumorphicTheme.expandDuration,
            curve: NeumorphicTheme.expandCurve,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ReorderableColumn(
                onReorder: (oldIndex, newIndex) {
                  // 子项之间的重新排序
                  final todoNotifier = ref.read(todoProvider.notifier);
                  todoNotifier.reorderChildTodos(item, oldIndex, newIndex);
                },
                // 启用拖拽功能
                needsLongPressDraggable: true,
                children: item.children.asMap().entries.map((entry) {
                  final childIndex = entry.key;
                  final child = entry.value;
                  return Padding(
                    key: ValueKey('${item.id}-child-${child.id}'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DraggableTodoItem(
                      item: child,
                      leftPadding: leftPadding + 20,
                      onAddChild: onAddChild,
                      index: childIndex, // 传递子项在列表中的索引
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
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

  Widget _buildNeumorphicIconButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: NeumorphicBox(
        width: 32,
        height: 32,
        borderRadius: 8,
        padding: EdgeInsets.zero,
        type: NeumorphicType.flat,
        onTap: onTap,
        child: Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
  
  // 构建可拖拽手柄
  Widget _buildDragHandle(BuildContext context) {
    // 获取索引，如果没有传入则默认为0
    int itemIndex = index ?? 0;
    
    // 使用自定义的CustomDragStartListener提高拖拽灵敏度
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: CustomDragStartListener(
        index: itemIndex,
        child: NeumorphicBox(
          width: 32,
          height: 32,
          borderRadius: 8,
          padding: EdgeInsets.zero,
          type: NeumorphicType.flat,
          child: Icon(
            Icons.drag_handle,
            size: 18,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
  
  // 显示编辑对话框
  void _showEditDialog(BuildContext context, WidgetRef ref, TodoItem item) {
    final todoNotifier = ref.read(todoProvider.notifier); // ✅ 在外部获取一次
    final TextEditingController titleController = TextEditingController(text: item.title);
    String selectedPriority = item.priority;
    DateTime? selectReminderAt = item.reminderAt;

    // 在显示日期选择器时自动隐藏键盘
    void showDatePicker() {
      // 先隐藏键盘
      FocusScope.of(context).unfocus();

      // 延迟一下再显示日期选择器，确保键盘完全收起
      Future.delayed(const Duration(milliseconds: 100), () {
        AppDatePicker.show(
          context: context,
          mode: AppDatePickerMode.editDate,
          initialDateTime: item.reminderAt,
          onConfirm: (dateTime) {
            selectReminderAt = dateTime;
            item.reminderAt = dateTime;
            // 通知StatefulBuilder更新UI
            (context as Element).markNeedsBuild();
          },
        );
      });
    }

    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
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
                      const Icon(Icons.edit, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        '编辑待办事项',
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
                      labelText: '标题',
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
                        borderSide: const BorderSide(
                            color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),

                  // 日期选择按钮
                  StatefulBuilder(
                    builder: (context, setState) =>
                        InkWell(
                          onTap: showDatePicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors
                                    .blue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectReminderAt != null
                                        ? '${selectReminderAt!
                                        .year}/${selectReminderAt!.month
                                        .toString().padLeft(
                                        2, '0')}/${selectReminderAt!.day
                                        .toString().padLeft(2, '0')} '
                                        '${selectReminderAt!.hour.toString()
                                        .padLeft(2, '0')}:${selectReminderAt!
                                        .minute.toString().padLeft(2, '0')}'
                                        : '设置提醒时间',
                                    style: TextStyle(
                                      color: selectReminderAt != null ? Colors
                                          .black87 : Colors.grey.shade600,
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
                      StatefulBuilder(
                        builder: (context, setState) =>
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ...[
                                  {'label': '低', 'value': 'low'},
                                  {'label': '中', 'value': 'medium'},
                                  {'label': '高', 'value': 'high'},
                                ].map((priority) =>
                                    _buildPriorityOption(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (titleController.text
                              .trim()
                              .isNotEmpty) {
                            todoNotifier.updateTodoFields(
                                item.id,
                                {
                                  "title": titleController.text.trim(),
                                  "reminder_at": selectReminderAt,
                                  "priority": selectedPriority,
                                }
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
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
}

// 自定义拖拽监听器，提高拖拽灵敏度
class CustomDragStartListener extends ReorderableDelayedDragStartListener {
  const CustomDragStartListener({
    super.key,
    required super.child,
    required super.index,
    super.enabled,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return DelayedMultiDragGestureRecognizer(
      delay: const Duration(milliseconds: 0), // 默认是500ms，现在改为100ms提高灵敏度
      debugOwner: this,
    );
  }
}

class CustomSlidableAction extends StatelessWidget {
  final Function(BuildContext) onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String label;
  final int flex;

  const CustomSlidableAction({
    Key? key,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    this.flex = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SlidableAction(
        label: label,
        backgroundColor: Colors.transparent,
        foregroundColor: foregroundColor,
        icon: icon,
        flex: flex,
        onPressed: (context) => onPressed(context),
      ),
    );
  }
}