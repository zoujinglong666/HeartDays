import 'package:heart_days/Consts/index.dart';
import 'package:heart_days/common/helper.dart';

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

  factory ApiResponse.formJsonResponse(Map<String, dynamic> json) {
    return ApiResponse<T>(
      code: json['code'] ?? -1,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  /// 用于判断业务是否处理成功
  bool get success => code == Consts.request.successCode;

  /// 用于判断当前响应的数据谁否是列表
  bool get isArray => !isEmpty && data is Iterable;

  /// 用于判断当时数据是否为空
  bool get isEmpty => Helper.isEmpty(data);


  /// 更方便的构造 Result 对象，
  /// 其中的 message 如果未传递的话，会尝试使用 code 码去本地国际化资源中取值，
  /// 如果依然没有取到，则默认显示 “Unknown” 作为消息内容。
  ApiResponse.of(String message, this.code)
      : data = null,
        message = message ?? "Unknown";

  @override
  String toString() {
    return 'ApiResponse(code: $code, message: $message, data: $data)';
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "message": message,
      "data": data.toString(),
    };
  }
}
