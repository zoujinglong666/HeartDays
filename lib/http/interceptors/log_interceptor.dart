import 'package:dio/dio.dart';
import 'package:heart_days/utils/ToastUtils.dart';

class LogInterceptorHandler extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print("➡️ 请求: ${options.uri}");
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print("✅ 响应: ${response.data}");
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print("❌ Dio 错误: $err");
    final response = err.response;
    String errorMessage = "请求失败，请稍后重试";

    if (response != null) {
      print("⚠️ 状态码: ${response.statusCode}");
      print("⚠️ 返回体: ${response.data}");

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // 👇 检查外层 message 是嵌套 Map
        final innerMessage = data['message'];
        if (innerMessage is String) {
          errorMessage = innerMessage;
        } else if (innerMessage is Map<String, dynamic>) {
          if (innerMessage.containsKey('message')) {
            errorMessage = innerMessage['message'];
          } else if (innerMessage.containsKey('error')) {
            errorMessage = innerMessage['error'];
          }
        }
      } else if (data is String) {
        errorMessage = data;
      }
    } else {
      errorMessage = err.message ?? "请求失败";
    }

    ToastUtils.showToast(errorMessage);
    super.onError(err, handler);
  }

}
