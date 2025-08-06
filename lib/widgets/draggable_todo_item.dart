import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:heart_days/providers/todo_provider.dart';
import 'package:heart_days/theme/neumorphic_theme.dart';
import 'package:heart_days/widgets/neumorphic_box.dart';
import 'package:heart_days/widgets/reorderable_column.dart';

class DraggableTodoItem extends ConsumerWidget {
  final TodoItem item;
  final double leftPadding;
  final Function(BuildContext, TodoItem) onAddChild;
  final bool isDragging;

  const DraggableTodoItem({
    super.key,
    required this.item,
    this.leftPadding = 0,
    required this.onAddChild,
    this.isDragging = false,
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
                            _buildNeumorphicIconButton(
                              icon: Icons.drag_handle,
                              onTap: null,
                            ),
                          ],
                        ),
                        onLongPress: () => todoNotifier.togglePriority(item),
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
                needsLongPressDraggable: false,
                children: item.children.asMap().entries.map((entry) {
                  final index = entry.key;
                  final child = entry.value;
                  return Padding(
                    key: ValueKey('${item.id}-child-${child.id}'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DraggableTodoItem(
                      item: child,
                      leftPadding: leftPadding + 20,
                      onAddChild: onAddChild,
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
  
  // 显示编辑对话框
  void _showEditDialog(BuildContext context, WidgetRef ref, TodoItem item) {
    final TextEditingController titleController = TextEditingController(text: item.title);
    String selectedPriority = item.priority;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑待办事项'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '标题'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setState) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPriorityOption(context, '低', 'low', selectedPriority, (val) {
                    setState(() => selectedPriority = val);
                  }),
                  _buildPriorityOption(context, '中', 'medium', selectedPriority, (val) {
                    setState(() => selectedPriority = val);
                  }),
                  _buildPriorityOption(context, '高', 'high', selectedPriority, (val) {
                    setState(() => selectedPriority = val);
                  }),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                ref.read(todoProvider.notifier).updateTodo(
                  item.id,
                  titleController.text.trim(),
                  selectedPriority,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
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