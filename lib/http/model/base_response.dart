class BaseResponse<T> {
  final int code;
  final String message;
  final T? data;

  BaseResponse({
    required this.code,
    required this.message,
    this.data,
  });

  factory BaseResponse.fromJson(
      Map<String, dynamic> json,
      Function(Map<String, dynamic>)? fromJson,
      ) {
    return BaseResponse<T>(
      code: json['code'] ?? -1,
      message: json['message'] ?? '',
      data: fromJson != null && json['data'] != null
          ? fromJson(json['data'])
          : null,
    );
  }
}
