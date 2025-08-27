import 'package:dio/dio.dart';

class LoadingInterceptorHandler extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 可添加 Loading 显示逻辑
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 关闭 Loading
    super.onResponse(response, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    // 错误处理
    super.onError(err, handler);
  }
}