import 'dart:ui';

class Anniversary {
  final String id;
  final String title;
  final DateTime date;
  final String icon;
  final String description;
  final Color color;
  final String type;
  final bool isPinned;
  final bool isHighlighted;
  final String repetitiveType;
  final String selectedType;


  Anniversary({
    required this.id,
    required this.title,
    required this.date,
    required this.icon,
    required this.description,
    required this.color,
    required this.type,
    required this.isPinned,
    required this.isHighlighted,
    required this.repetitiveType,
     required this.selectedType
  });

  /// JSON 转对象
  factory Anniversary.fromJson(Map<String, dynamic> json) {
    return Anniversary(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: DateTime.tryParse(json['date']) ?? DateTime.now(),
      icon: json['icon'] ?? '',
      description: json['description'] ?? '',
      color: Color(json['color'] ?? 0xFF000000),
      type: json['type'] ?? '',
      isPinned: json['isPinned'] ?? false,
      isHighlighted: json['isHighlighted'] ?? false,
      repetitiveType: json['repetitiveType'] ?? '', selectedType: '',
    );
  }

  /// 对象转 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'icon': icon,
      'description': description,
      'color': color.value,
      'type': type,
      'isPinned': isPinned,
      'isHighlighted': isHighlighted,
      'repetitiveType': repetitiveType,
      'selectedType':''
    };
  }
}
