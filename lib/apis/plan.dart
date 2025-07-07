import 'dart:core';

import 'package:heart_days/http/http_manager.dart';
import 'package:heart_days/http/model/api_response.dart';

enum PlanStatus { pending, inProgress, completed, cancelled }

enum PlanPriority { low, medium, high }

/// 将 PlanStatus 枚举转换为整型
int statusToInt(PlanStatus status) => status.index;

/// 将整型转换为 PlanStatus 枚举
PlanStatus intToStatus(int i) => PlanStatus.values[i];

/// 将 PlanPriority 枚举转换为整型
int priorityToInt(PlanPriority priority) => priority.index;

/// 将整型转换为 PlanPriority 枚举
PlanPriority intToPriority(int i) => PlanPriority.values[i];

class PaginatedData<T> {
  final int total;
  final int size;
  final int current;
  final int pages;
  final bool hasNext;
  final bool hasPrev;
  final List<T> records;

  PaginatedData({
    required this.total,
    required this.size,
    required this.current,
    required this.pages,
    required this.hasNext,
    required this.hasPrev,
    required this.records,
  });

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    try {
      List<T> records = [];
      if (json['records'] != null) {
        if (json['records'] is List) {
          records =
              (json['records'] as List)
                  .map((e) => fromJsonT(e as Map<String, dynamic>))
                  .toList();
        } else {
          print('❌ records 不是 List 类型: ${json['records']}');
        }
      }

      return PaginatedData<T>(
        total: json['total'] ?? 0,
        size: json['size'] ?? 10,
        current: json['current'] ?? 1,
        pages: json['pages'] ?? 1,
        hasNext: json['hasNext'] ?? false,
        hasPrev: json['hasPrev'] ?? false,
        records: records,
      );
    } catch (e) {
      print('❌ PaginatedData.fromJson 解析错误: $e');
      print('❌ JSON 数据: $json');
      rethrow;
    }
  }

  factory PaginatedData.empty() => PaginatedData<T>(
    total: 0,
    size: 10,
    current: 1,
    pages: 1,
    hasNext: false,
    hasPrev: false,
    records: [],
  );
}

Future<ApiResponse<PaginatedData<Plan>>> fetchPlanListByUserId(
  Map<String, dynamic> params,
) async {
  try {
    return await HttpManager.get<PaginatedData<Plan>>(
      "/plans/my/list",
      queryParameters: params,
      fromJson: (json) {
        print('🔍 解析 PaginatedData: $json');
        return PaginatedData<Plan>.fromJson(json, (e) => Plan.fromJson(e));
      },
    );
  } catch (e) {
    print('❌ fetchPlanListByUserId 错误: $e');
    return ApiResponse<PaginatedData<Plan>>(
      code: 500,
      message: "获取失败: $e",
      data: PaginatedData<Plan>.empty(),
    );
  }
}

Future<ApiResponse<Plan>> updatePlanStatus(Map<String, dynamic> data) async {
  return await HttpManager.post<Plan>(
    "/plans/update/status",
    data: data,
    fromJson: (json) => Plan.fromJson(json),
  );
}

Future<ApiResponse<Plan>> addPlan(Map<String, dynamic> data) async {
  return await HttpManager.post<Plan>(
    "/plans/create",
    data: data,
    fromJson: (json) => Plan.fromJson(json), // ✅ 保持一致
  );
}

Future<ApiResponse<Plan>> updatePlan(
    Map<String, dynamic> data,
    ) async {
  // 从 data 中提取 id，然后创建一个不包含 id 的新 Map
  final id = data['id'];
  final dataWithoutId = Map<String, dynamic>.from(data)..remove('id');
  return await HttpManager.patch<Plan>(
    "/plans/update/$id",
    data: dataWithoutId, // ✅ 不包含 id
    fromJson: (json) => Plan.fromJson(json),
  );
}

Future<ApiResponse> planDeleteById(int id) async {
  return await HttpManager.delete('/plans/delete/$id');
}

class Plan {
  int id;
  final String userId;
  final String title;
  final String description;
  final String? category;
  late final int status;
  final int priority;
  final DateTime date;
  final DateTime? reminderAt;
  final DateTime? completedAt;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  Plan({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.category,
    this.status = 0,
    this.priority = 1,
    required this.date,
    this.reminderAt,
    this.completedAt,
    this.remarks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    try {
      print('Plan.fromJson 输入: $json'); // 打印所有字段
      final createdAt = DateTime.tryParse(json['created_at'] ?? '');
      final updatedAt = DateTime.tryParse(json['updated_at'] ?? '');
      if (createdAt == null || updatedAt == null) {
        throw Exception('created_at 或 updated_at 字段缺失或格式错误: $json');
      }
      return Plan(
        id:
            json['id'] is int
                ? json['id']
                : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        userId: json['user_id']?.toString() ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        category: json['category'],
        status:
            json['status'] is int
                ? json['status']
                : int.tryParse(json['status']?.toString() ?? '0') ?? 0,
        priority:
            json['priority'] is int
                ? json['priority']
                : int.tryParse(json['priority']?.toString() ?? '1') ?? 1,
        date:
            json['date'] != null
                ? DateTime.parse(json['date'])
                : DateTime.now(),
        reminderAt:
            json['reminder_at'] != null
                ? DateTime.tryParse(json['reminder_at'])
                : null,
        completedAt:
            json['completed_at'] != null
                ? DateTime.tryParse(json['completed_at'])
                : null,
        remarks: json['remarks'] as String?,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: DateTime.parse(json['updated_at']),
      );
    } catch (e) {
      print('❌ Plan.fromJson 解析错误: $e');
      print('❌ JSON 数据: $json');
      rethrow;
    }
  }
}
