import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/todo_items_api.dart';
import 'package:heart_days/common/toast.dart';

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
    _initData();
  }

  Future<void> _initData() async {
    final apiResp = await listTodoApi({});
    if (apiResp.success) {
      List<BackendTodoItem>? flatList = apiResp.data;
      List<TodoItem> tree = convertToUITree(flatList!);
      state = tree;
    } else {
      state = [];
    }
  }
  void printTodoTree(List<TodoItem> items, {int depth = 0, String prefix = ''}) {
    final indentUnit = '  ';
    for (var i = 0; i < items.length; i++) {
      final isLast = i == items.length - 1;
      final connector = isLast ? '└─' : '├─';
      final newPrefix = prefix + (depth > 0 ? (isLast ? '   ' : '│  ') : '');

      final item = items[i];
      print('$prefix$connector ${item.title} (id: ${item.id}, done: ${item.done}), priority: ${item.priority},');

      if (item.children.isNotEmpty) {
        printTodoTree(item.children, depth: depth + 1, prefix: newPrefix);
      }
    }
  }


  List<TodoItem> convertToUITree(List<BackendTodoItem> apiList) {
    // 1. 构造 ID => UI 对象映射
    final Map<String, TodoItem> map = {
      for (var b in apiList)
        b.id: TodoItem(
          id: b.id,
          title: b.title,
          done: b.done,
          priority: priorityLevelToString(b.priority),
          expanded: false,
          parentId: b.parentId,
        ),
    };

    // 2. 建立父子关系（直接引用子节点，无需 copyWith）
    final List<TodoItem> roots = [];
    for (final item in map.values) {
      final pid = item.parentId;
      if (pid != null && map.containsKey(pid)) {
        map[pid]!.children.add(item); // ✅ 直接添加引用
      } else {
        roots.add(item); // ✅ 根节点
      }
    }

    // 3. 修正展开状态
    void fixExpanded(TodoItem item) {
      item.expanded = item.children.isNotEmpty;
      for (final child in item.children) {
        fixExpanded(child);
      }
    }

    for (final root in roots) {
      fixExpanded(root);
    }

    // ✅ 打印结构
    printTodoTree(roots);
    return roots;
  }


  /// 统一的添加入口：parentId == null 时为根节点
  Future<void> addTodo(String title, {String? parentId}) async {
    if (title
        .trim()
        .isEmpty) return;

    final res = await addTodoItemApi({
      'title': title.trim(),
      if (parentId != null) 'parent_id': parentId,
    });

    if (!res.success) {
      MyToast.showError('add todo failed');
      return;
    }

    MyToast.showSuccess('add todo success');
    await _initData(); // 重新拉取
  }
  // 添加根级Todo
  Future<void> addRootTodo(String text) async {
    addTodo(text);
  }

  // 添加子Todo
  Future<void> addChildTodo(TodoItem todoItem, String text) async {
    if (text.trim().isEmpty) return;
    addTodo(text, parentId: todoItem.id);
    state = state.map((item) => _updateParentRecursive(item, todoItem.id, text))
        .toList();
  }

  // 递归查找并更新父节点
  TodoItem _updateParentRecursive(TodoItem item, String parentId, String text) {
    if (item.id == parentId) {
      final newChildren = List<TodoItem>.from(item.children);
      newChildren.add(
        TodoItem(
          id: item.children.length.toString(),
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
    updateTodoFields(item.id,{
      'done': !item.done,
    });
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

  Future<void> _deleteTodoItem(TodoItem item) async {
    try {
      final res = await deleteTodoApi({
        "id": item.id
      });
      if (res.success) {
        MyToast.showSuccess('delete todo success');
        _initData();
      }
    } catch (e) {
      MyToast.showError('delete todo error');
    }
  }
  // 删除Todo项
  void deleteTodo(TodoItem item) {
    _deleteTodoItem(item);
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
    String newPriority;
    if (item.priority == 'high') {
      newPriority = 'medium';
    } else if (item.priority == 'medium') {
      newPriority = 'low';
    } else {
      newPriority = 'high';
    }
    final priorityMap = {
      'low': 0,
      'medium': 1,
      'high': 2,
    };
    updateTodoFields(item.id,{
      'priority':priorityMap[newPriority]
    });
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

  String nextPriority(String currentPriority) {
    const priorities = ['0', '1', '2'];
    final currentIndex = priorities.indexOf(currentPriority);
    final nextIndex = (currentIndex + 1) % priorities.length;
    return priorities[nextIndex];
  }


  // 更新Todo项
  Future<void> updateTodoFields(String id, Map<String, dynamic> fields) async {
    try {
      final payload = {
        "id": id,
        ...fields, // 合并需要更新的字段
      };

      final res = await updateTodoApi(payload);
      if (res.success) {
        MyToast.showSuccess('保存成功');
        _initData();
      }
    } catch (e) {
      MyToast.showError('保存失败');
    }
  }

  // 更新Todo项
  Future<void> updateTodo(String id, String title, String priority) async {
    final priorityMap = {
      'low': 0,
      'medium': 1,
      'high': 2,
    };
    updateTodoFields(id, {
      "title": title,
      "priority": priorityMap[priority],
    });
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

  /* ---------- 查（刷新） ---------- */
  Future<void> refresh() => _initData();
}

// 创建Provider
final todoProvider = StateNotifierProvider<TodoNotifier, List<TodoItem>>((ref) {
  return TodoNotifier();
});