import 'package:heart_days/http/http_manager.dart';
import 'package:heart_days/http/model/api_response.dart';

class BackendTodoItem {
  final String id;
  final String userId;
  final String title;
  final bool done;
  final PriorityLevel priority;
  final bool expanded;
  final String? parentId;
  final int order;
  final DateTime? reminderAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 关联关系
  final BackendTodoItem? parent;

  BackendTodoItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.done,
    required this.priority,
    required this.expanded,
    this.parentId,
    required this.order,
    this.reminderAt,
    required this.createdAt,
    required this.updatedAt,
    this.parent,
  });

  factory BackendTodoItem.fromJson(Map<String, dynamic> json) {
    return BackendTodoItem(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      done: json['done'],
      priority: PriorityLevel.values[json['priority'] ?? 1],
      expanded: json['expanded'] ?? true,
      parentId: json['parent_id'],
      order: json['order'] ?? 0,
      reminderAt:
          json['reminder_at'] != null
              ? DateTime.parse(json['reminder_at'])
              : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      parent: json['parent'] != null ? BackendTodoItem.fromJson(json['parent']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'done': done,
      'priority': priority.index,
      'expanded': expanded,
      'parent_id': parentId,
      'order': order,
      'reminder_at': reminderAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'parent': parent?.toJson(),
    };
  }
}

enum PriorityLevel { LOW, MEDIUM, HIGH }
// PriorityLevel 转 string
String priorityLevelToString(PriorityLevel level) {
  switch (level) {
    case PriorityLevel.LOW:
      return 'low';
    case PriorityLevel.MEDIUM:
      return 'medium';
    case PriorityLevel.HIGH:
      return 'high';
  }
}
enum Priority { low, medium, high }
// var current = Priority.low;
// print(current.label); // low
//
// current = current.next();
// print(current.label); // medium
//
// print(current.value); // 1
//
// final restored = PriorityExtension.fromLabel('high');
// print(restored); // Priority.high
extension PriorityExtension on Priority {
  /// 获取下一个优先级（循环）
  Priority next() {
    final index = (indexOf(this) + 1) % Priority.values.length;
    return Priority.values[index];
  }

  /// 获取字符串表示（如：'low'）
  String get label => toString().split('.').last;

  /// 获取数据库存储的数值（如：0, 1, 2）
  int get value => indexOf(this);

  /// 通过字符串恢复优先级（如：'medium' → Priority.medium）
  static Priority fromLabel(String label) {
    return Priority.values.firstWhere(
          (e) => e.label == label,
      orElse: () => Priority.low, // 默认值
    );
  }

  /// 通过数值恢复优先级（如：1 → Priority.medium）
  static Priority fromValue(int value) {
    return Priority.values[value.clamp(0, Priority.values.length - 1)];
  }

  static int indexOf(Priority p) => Priority.values.indexOf(p);
}



Future<ApiResponse> addTodoItemApi(Map<String, dynamic> data) async {
  return await HttpManager.post<Map<String, dynamic>>("/todos/add", data: data);
}
Future<ApiResponse<List<BackendTodoItem>>> listTodoApi(Map<String, dynamic>? data) async {
  return await HttpManager.get<List<BackendTodoItem>>(
    "/todos/list",
    queryParameters: data,
    fromJson: (json) {
      final items = json['data'] as List<dynamic>;
      return items
          .map((e) => BackendTodoItem.fromJson(e as Map<String, dynamic>))
          .toList();
    },
  );
}
Future<ApiResponse<void>> deleteTodoApi(Map<String, dynamic>? data) async {
  return await HttpManager.post<List<BackendTodoItem>>(
    "/todos/delete",
    data: data,
  );
}
Future<ApiResponse<void>> updateTodoApi(Map<String, dynamic>? data) async {
  return await HttpManager.post<List<BackendTodoItem>>(
    "/todos/update",
    data: data,
  );
}
Future<ApiResponse<void>> updateOrderTodoApi(Map<String, dynamic>? data) async {
  return await HttpManager.post<List<BackendTodoItem>>(
    "/todos/order",
    data: data,
  );
}




