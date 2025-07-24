class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    Function(dynamic)? fromJson,
  ) {
    return ApiResponse<T>(
      code: json['code'] ?? -1,
      message: json['message'] ?? '',
      data:
          fromJson != null && json['data'] != null
              ? fromJson(json['data'])
              : null,
    );
  }

  factory ApiResponse.formJsonTest(Map<String, dynamic> json) {
    return ApiResponse<T>(
      code: json['code'] ?? -1,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  @override
  String toString() {
    return 'ApiResponse(code: $code, message: $message, data: $data)';
  }
}
