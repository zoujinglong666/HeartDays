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

    // 👇 如果是 401，说明有 token 过期处理，不提示 toast
    if (response?.statusCode == 401) {
      print("⚠️ 检测到 401 错误，跳过提示（由刷新 token 逻辑处理）");
      super.onError(err, handler); // 继续传递给后续逻辑（如刷新 token）
      return;
    }

    if (response != null) {
      print("⚠️ 状态码: ${response.statusCode}");
      print("⚠️ 返回体: ${response.data}");

      final data = response.data;
      if (data is Map<String, dynamic>) {
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
