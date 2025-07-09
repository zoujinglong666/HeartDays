import 'dart:ui';

import 'package:heart_days/http/http_manager.dart';
import 'package:heart_days/http/model/api_response.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  /// 颜色解析函数
  static Color? parseColor(dynamic colorValue) {
    if (colorValue == null) return null;
    if (colorValue is int) return Color(colorValue);
    if (colorValue is String) {
      if (colorValue.startsWith('#')) {
        colorValue = colorValue.substring(1);
      }
      try {
        return Color(int.parse(colorValue, radix: 16) + 0xFF000000);
      } catch (e) {
        print("❌ 颜色解析失败: $colorValue");
      }
    }
    return null;
  }

  /// 日期解析函数，兼容 'yyyy-MM-dd HH:mm:ss' 格式
  static DateTime parseDateTime(dynamic input) {
    if (input == null) return DateTime(2000);
    if (input is DateTime) return input;

    final str = input.toString();

    // 优先标准 ISO 格式
    try {
      return DateTime.parse(str).toLocal();
    } catch (_) {}

    // 使用 intl 解析 yyyy-MM-dd HH:mm:ss 格式为 UTC 再转本地
    try {
      final formatter = DateFormat("yyyy-MM-dd HH:mm:ss");
      return formatter.parseUtc(str).toLocal();
    } catch (e) {
      print("❌ 日期解析失败: $str");
    }

    return DateTime(2000);
  }

  factory Anniversary.fromJson(Map<String, dynamic> json) {
    return Anniversary(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: parseDateTime(json['date']),
      icon: json['icon'] ?? '',
      color: parseColor(json['color']),
      type: json['type'] ?? '',
      isPinned: json['is_pinned'] ?? json['isPinned'] ?? false,
      isHighlighted: json['is_highlighted'] ?? json['isHighlighted'] ?? false,
      repetitiveType: json['repetitive_type'] ?? '',
      userId: json['user_id']?.toString(),
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    String? serializeColor(Color? color) {
      if (color == null) return null;
      return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    }

    String? serializeDate(DateTime? date) {
      if (date == null) return null;
      return date.toIso8601String(); // 你也可以换成 yyyy-MM-dd HH:mm:ss 格式
    }

    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      'title': title,
      'description': description,
      'date': serializeDate(date),
      'icon': icon,
      'color': serializeColor(color),
      'type': type,
      'is_pinned': isPinned,
      'is_highlighted': isHighlighted,
      'repetitive_type': repetitiveType,
      'user_id': userId,
      'created_at': serializeDate(createdAt),
      'updated_at': serializeDate(updatedAt),
    };
  }
}



/// 获取指定 ID 的纪念日
Future<Anniversary> fetchById(int id) async {
  final res = await HttpManager.get('/anniversaries/$id');
  if (res.code != 200 || res.data == null) throw Exception(res.message);
  return Anniversary.fromJson(res.data);
}

Future<ApiResponse<Anniversary>> createAnniversary(
  Map<String, dynamic> data,
) async {
  return await HttpManager.post<Anniversary>(
    "/anniversaries/create",
    data: data,
    fromJson: (json) => Anniversary.fromJson(json), // ✅ 保持一致
  );
}

/// 更新纪念日
Future<ApiResponse<Anniversary>> updateAnniversary(
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
Future<ApiResponse> anniversaryDeleteById(int id) async {
  return await HttpManager.delete('/anniversaries/$id');
}

/// 获取指定用户的纪念日列表
Future<ApiResponse<List<Anniversary>>> fetchAnniversaryListByUserId(String userId) async {
  try {
    final res = await HttpManager.get<List<Anniversary>>(
      "/anniversaries/user/$userId",
      fromJson: (json) => (json as List)
          .map((e) => Anniversary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return res;
  } catch (e) {
    return ApiResponse<List<Anniversary>>(
      code: 500,
      message: "获取数据失败: $e",
      data: [],
    );
  }
}


/// 获取当前登录用户的纪念日
Future<List<Anniversary>> fetchMyAnniversaries() async {
  final res = await HttpManager.get('/anniversaries/my');
  if (res.code != 200 || res.data == null) throw Exception(res.message);
  return (res.data as List).map((e) => Anniversary.fromJson(e)).toList();
}
