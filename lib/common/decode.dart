List<T> Function(dynamic json) decodeList<T>(
  T Function(Map<String, dynamic>) fromJsonFn,
) {
  return (dynamic json) {
    if (json is List) {
      return json.map((e) => fromJsonFn(e as Map<String, dynamic>)).toList();
    }
    throw Exception("期望是 List 格式，实际是: ${json.runtimeType}");
  };
}
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
  /// ✅ 派生字段：是否还有更多数据（推荐使用）
  bool get hasMore => current < pages;
  factory PaginatedData.empty() => PaginatedData<T>(
    total: 0,
    size: 10,
    current: 1,
    pages: 1,
    hasNext: false,
    hasPrev: false,
    records: [],
  );

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'total': total,
      'size': size,
      'current': current,
      'pages': pages,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
      'records': records.map((e) => toJsonT(e)).toList(),
    };
  }


}



