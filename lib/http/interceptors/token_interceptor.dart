import 'package:dio/dio.dart';

class TokenInterceptorHandler extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 模拟添加 Token
    options.headers['Authorization'] = 'Bearer YOUR_TOKEN';
    super.onRequest(options, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    // 模拟 Token 过期处理
    if (err.response?.statusCode == 401) {
      print("🔁 Token 过期，尝试续租...");
      // 添加你的 token 续租逻辑
    }
    super.onError(err, handler);
  }
}