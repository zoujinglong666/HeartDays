import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final TextEditingController controller = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('添加子任务'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '输入子任务内容...',
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('添加'),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  ref.read(todoProvider.notifier).addChildTodo(parent, controller.text);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
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
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('添加新任务'),
              content: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '输入任务内容...',
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  child: const Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _controller.clear();
                  },
                ),
                TextButton(
                  child: const Text('添加'),
                  onPressed: () {
                    ref.read(todoProvider.notifier).addRootTodo(_controller.text);
                    _controller.clear();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
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