import 'package:flutter_riverpod/flutter_riverpod.dart';

// 定义Todo项数据结构
class TodoItem {
  String id;
  String title;
  bool done;
  String priority;
  bool expanded;
  List<TodoItem> children;
  String? parentId; // 父级ID，根级项为null

  TodoItem({
    required this.id,
    required this.title,
    this.done = false,
    this.priority = 'medium',
    this.expanded = true,
    this.parentId,
    List<TodoItem>? children,
  }) : children = children ?? [];

  // 创建TodoItem的副本
  TodoItem copyWith({
    String? id,
    String? title,
    bool? done,
    String? priority,
    bool? expanded,
    String? parentId,
    List<TodoItem>? children,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      priority: priority ?? this.priority,
      expanded: expanded ?? this.expanded,
      parentId: parentId ?? this.parentId,
      children: children ?? List.from(this.children),
    );
  }
}

// Todo状态管理类
class TodoNotifier extends StateNotifier<List<TodoItem>> {
  TodoNotifier() : super([]) {
    // 初始化示例数据
    state = [
      TodoItem(
        id: '1',
        title: '完成今日计划',
        done: false,
        priority: 'high',
        children: [
          TodoItem(
            id: '1-1',
            title: '完成Flutter项目',
            done: false,
            priority: 'high',
          ),
          TodoItem(
            id: '1-2',
            title: '准备会议材料',
            done: true,
            priority: 'medium',
          ),
        ],
      ),
      TodoItem(
        id: '2',
        title: '阅读30分钟',
        done: false,
        priority: 'medium',
      ),
      TodoItem(
        id: '3',
        title: '喝8杯水',
        done: true,
        priority: 'low',
      ),
    ];
  }

  // 添加根级Todo
  void addRootTodo(String text) {
    if (text.trim().isEmpty) return;
    state = [
      TodoItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text.trim(),
        done: false,
        priority: 'medium',
      ),
      ...state,
    ];
  }

  // 添加子Todo
  void addChildTodo(TodoItem parent, String text) {
    if (text.trim().isEmpty) return;

    state = state.map((item) => _updateParentRecursive(item, parent.id, text)).toList();
  }

  // 递归查找并更新父节点
  TodoItem _updateParentRecursive(TodoItem item, String parentId, String text) {
    if (item.id == parentId) {
      final newChildren = List<TodoItem>.from(item.children);
      newChildren.add(
        TodoItem(
          id: '${parentId}-${DateTime.now().millisecondsSinceEpoch}',
          title: text.trim(),
          done: false,
          priority: 'medium',
          parentId: parentId, // 设置父级ID
        ),
      );

      return item.copyWith(
        children: newChildren,
        expanded: true, // 确保展开以显示新添加的子项
      );
    } else if (item.children.isNotEmpty) {
      return item.copyWith(
        children: item.children
            .map((child) => _updateParentRecursive(child, parentId, text))
            .toList(),
      );
    }
    return item;
  }

  // 切换Todo完成状态，并级联更新子项
  void toggleDone(TodoItem item) {
    state = state.map((todo) => _updateDoneStatusRecursive(todo, item.id)).toList();
  }

  // 递归更新完成状态
  TodoItem _updateDoneStatusRecursive(TodoItem item, String targetId) {
    if (item.id == targetId) {
      final newDoneStatus = !item.done;
      return _updateItemAndChildren(item, newDoneStatus);
    } else if (item.children.isNotEmpty) {
      return item.copyWith(
        children: item.children
            .map((child) => _updateDoneStatusRecursive(child, targetId))
            .toList(),
      );
    }
    return item;
  }

  // 递归更新所有子项状态
  TodoItem _updateItemAndChildren(TodoItem todo, bool doneStatus) {
    final updatedChildren = todo.children
        .map((child) => _updateItemAndChildren(child, doneStatus))
        .toList();

    return todo.copyWith(
      done: doneStatus,
      children: updatedChildren,
    );
  }

  // 切换展开/折叠状态
  void toggleExpanded(TodoItem item) {
    state = state.map((todo) => _updateExpandedStateRecursive(todo, item.id)).toList();
  }

  // 递归更新展开状态
  TodoItem _updateExpandedStateRecursive(TodoItem item, String targetId) {
    if (item.id == targetId) {
      return item.copyWith(expanded: !item.expanded);
    } else if (item.children.isNotEmpty) {
      return item.copyWith(
        children: item.children
            .map((child) => _updateExpandedStateRecursive(child, targetId))
            .toList(),
      );
    }
    return item;
  }

  // 删除Todo项
  void deleteTodo(TodoItem item) {
    state = _removeItemRecursive(state, item.id);
  }

  // 递归删除项
  List<TodoItem> _removeItemRecursive(List<TodoItem> items, String targetId) {
    // 先检查顶层是否有匹配项
    final int index = items.indexWhere((item) => item.id == targetId);
    if (index != -1) {
      final newList = List<TodoItem>.from(items);
      newList.removeAt(index);
      return newList;
    }

    // 递归检查子项
    return items.map((item) {
      if (item.children.isNotEmpty) {
        return item.copyWith(
          children: _removeItemRecursive(item.children, targetId),
        );
      }
      return item;
    }).toList();
  }

  // 切换优先级
  void togglePriority(TodoItem item) {
    state = state.map((todo) => _updatePriorityRecursive(todo, item.id)).toList();
  }

  // 递归更新优先级
  TodoItem _updatePriorityRecursive(TodoItem item, String targetId) {
    if (item.id == targetId) {
      String newPriority;
      if (item.priority == 'high') {
        newPriority = 'medium';
      } else if (item.priority == 'medium') {
        newPriority = 'low';
      } else {
        newPriority = 'high';
      }
      return item.copyWith(priority: newPriority);
    } else if (item.children.isNotEmpty) {
      return item.copyWith(
        children: item.children
            .map((child) => _updatePriorityRecursive(child, targetId))
            .toList(),
      );
    }
    return item;
  }
  
  // 重新排序Todo项
  void reorderTodos(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final List<TodoItem> newList = List.from(state);
    final TodoItem item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    state = newList;
  }
  
  // 移动Todo项到新的父级
  void moveTodoToParent(TodoItem item, TodoItem? newParent) {
    // 创建一个新的item副本，更新parentId
    TodoItem updatedItem = item.copyWith(
      parentId: newParent?.id, // 如果是移动到根级别，parentId为null
    );
    
    // 如果newParent为null，则移动到根级别
    if (newParent == null) {
      // 先从原位置删除
      final List<TodoItem> newState = _removeItemRecursive(state, item.id);
      // 添加到根级别
      state = [updatedItem, ...newState];
      return;
    }
    
    // 从原位置删除
    final List<TodoItem> newState = _removeItemRecursive(state, item.id);
    // 添加到新父级
    state = newState.map((todo) => _addToParentRecursive(todo, newParent.id, updatedItem)).toList();
  }
  
  // 递归添加到新父级
  TodoItem _addToParentRecursive(TodoItem item, String parentId, TodoItem newChild) {
    if (item.id == parentId) {
      final newChildren = List<TodoItem>.from(item.children);
      // 确保newChild的parentId已设置为当前item的id
      TodoItem childWithParentId = newChild.copyWith(parentId: parentId);
      newChildren.add(childWithParentId);
      return item.copyWith(
        children: newChildren,
        expanded: true, // 确保展开以显示新添加的子项
      );
    } else if (item.children.isNotEmpty) {
      return item.copyWith(
        children: item.children
            .map((child) => _addToParentRecursive(child, parentId, newChild))
            .toList(),
      );
    }
    return item;
  }
  
  // 重新排序子Todo项
  void reorderChildTodos(TodoItem parent, int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // 创建父项的子列表副本
    final List<TodoItem> newChildrenList = List.from(parent.children);
    // 移除旧位置的项并插入到新位置
    final TodoItem childItem = newChildrenList.removeAt(oldIndex);
    newChildrenList.insert(newIndex, childItem);
    
    // 创建更新后的父项
    final updatedParent = parent.copyWith(children: newChildrenList);
    
    // 更新状态
    state = state.map((todo) => 
      todo.id == parent.id ? updatedParent : _updateChildrenRecursive(todo, parent.id, newChildrenList)
    ).toList();
  }
  
  // 递归更新子项列表
  TodoItem _updateChildrenRecursive(TodoItem item, String parentId, List<TodoItem> newChildren) {
    if (item.id == parentId) {
      return item.copyWith(children: newChildren);
    } else if (item.children.isNotEmpty) {
      return item.copyWith(
        children: item.children
            .map((child) => _updateChildrenRecursive(child, parentId, newChildren))
            .toList(),
      );
    }
    return item;
  }
  
  // 更新Todo项
  void updateTodo(String id, String title, String priority) {
    state = state.map((todo) => _updateTodoRecursive(todo, id, title, priority)).toList();
  }
  
  // 递归更新Todo项
  TodoItem _updateTodoRecursive(TodoItem item, String id, String title, String priority) {
    if (item.id == id) {
      return item.copyWith(title: title, priority: priority);
    } else if (item.children.isNotEmpty) {
      return item.copyWith(
        children: item.children
            .map((child) => _updateTodoRecursive(child, id, title, priority))
            .toList(),
      );
    }
    return item;
  }
}

// 创建Provider
final todoProvider = StateNotifierProvider<TodoNotifier, List<TodoItem>>((ref) {
  return TodoNotifier();
});