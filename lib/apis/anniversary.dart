import 'dart:ui';

import 'package:heart_days/http/http_manager.dart';
import 'package:heart_days/http/model/base_response.dart';

class Anniversary {
  final String? id;
  final String title;
  final String description;
  final DateTime date;
  final String icon;
  final Color? color;
  final String type;
  final bool isPinned;
  final bool isHighlighted;
  final String? repetitiveType;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Anniversary({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    this.color,
    required this.type,
    this.isPinned = false,
    this.isHighlighted = false,
    this.repetitiveType,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory Anniversary.fromJson(Map<String, dynamic> json) {
    // 处理颜色字段
    Color? parseColor(dynamic colorValue) {
      if (colorValue == null) return null;
      if (colorValue is int) return Color(colorValue);
      if (colorValue is String) {
        // 处理十六进制颜色字符串
        if (colorValue.startsWith('#')) {
          colorValue = colorValue.substring(1);
        }
        try {
          return Color(int.parse(colorValue, radix: 16) + 0xFF000000);
        } catch (e) {
          print("❌ 颜色解析失败: $colorValue");
          return null;
        }
      }
      return null;
    }

    return Anniversary(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      date: DateTime.tryParse(json['date']) ?? DateTime.now(),
      icon: json['icon'] ?? '',
      description: json['description'] ?? '',
      color: parseColor(json['color']),
      type: json['type'] ?? '',
      isPinned: json['is_pinned'] ?? json['isPinned'] ?? false,
      isHighlighted: json['is_highlighted'] ?? json['isHighlighted'] ?? false,
      repetitiveType: json['repetitive_type'] ?? '',
      userId: json['user_id']?.toString(),
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    // 处理颜色序列化
    String? serializeColor(Color? color) {
      if (color == null) return null;
      return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    }

    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'icon': icon,
      'color': serializeColor(color),
      'type': type,
      'is_pinned': isPinned,
      'is_highlighted': isHighlighted,
      'repetitive_type': repetitiveType,
      'user_id': userId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// 获取所有纪念日
Future<List<Anniversary>> fetchAnniversaryAll() async {
  final res = await HttpManager.get('/anniversaries');
  if (res.code != 200 || res.data == null) throw Exception(res.message);
  return (res.data as List).map((e) => Anniversary.fromJson(e)).toList();
}

/// 获取指定 ID 的纪念日
Future<Anniversary> fetchById(int id) async {
  final res = await HttpManager.get('/anniversaries/$id');
  if (res.code != 200 || res.data == null) throw Exception(res.message);
  return Anniversary.fromJson(res.data);
}

Future<BaseResponse<Anniversary>> createAnniversary(
  Map<String, dynamic> data,
) async {
  return await HttpManager.post<Anniversary>(
    "/anniversaries/create",
    data: data,
    fromJson: (json) => Anniversary.fromJson(json), // ✅ 保持一致
  );
}

/// 更新纪念日
Future<BaseResponse<Anniversary>> updateAnniversary(
    Map<String, dynamic> data,
    ) async {
  // 从 data 中提取 id，然后创建一个不包含 id 的新 Map
  final id = data['id'];
  final dataWithoutId = Map<String, dynamic>.from(data)..remove('id');

  return await HttpManager.patch<Anniversary>(
    "/anniversaries/update/$id",
    data: dataWithoutId, // ✅ 不包含 id
    fromJson: (json) => Anniversary.fromJson(json),
  );
}


/// 删除纪念日
Future<BaseResponse> anniversaryDeleteById(int id) async {
  return await HttpManager.delete('/anniversaries/$id');
}

/// 获取指定用户的纪念日列表
Future<BaseResponse<List<Anniversary>>> fetchByUserId(String userId) async {
  try {
    final res = await HttpManager.get<List<Anniversary>>(
      "/anniversaries/user/$userId",
      fromJson: (json) {
        // 处理不同的数据格式
        if (json is List) {
          return json.map((e) => Anniversary.fromJson(e)).toList();
        } else if (json is Map<String, dynamic> && json.containsKey('data')) {
          // 如果后端返回的是包装在data字段中的列表
          final data = json['data'];
          if (data is List) {
            return data.map((e) => Anniversary.fromJson(e)).toList();
          }
        }
        return <Anniversary>[];
      },
    );
    return res;
  } catch (e) {
    // 返回一个空的响应
    return BaseResponse<List<Anniversary>>(
      code: 500,
      message: "获取数据失败: $e",
      data: <Anniversary>[],
    );
  }
}

/// 获取当前登录用户的纪念日
Future<List<Anniversary>> fetchMyAnniversaries() async {
  final res = await HttpManager.get('/anniversaries/my');
  if (res.code != 200 || res.data == null) throw Exception(res.message);
  return (res.data as List).map((e) => Anniversary.fromJson(e)).toList();
}
