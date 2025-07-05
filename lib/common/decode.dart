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
