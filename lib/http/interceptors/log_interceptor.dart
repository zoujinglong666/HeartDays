import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:heart_days/http/model/api_response.dart';
import 'package:heart_days/utils/ToastUtils.dart';

class LogInterceptorHandler extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    super.onRequest(options, handler);
  }


  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    String errorMessage = "请求失败，请稍后重试";
    // 💥 处理 Dio 类型错误（如超时、断网、服务器无响应等）
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = "服务器连接超时，请稍后再试";
        break;

      case DioExceptionType.unknown:
        if (err.error is SocketException) {
          errorMessage = "无法连接服务器，请检查网络或稍后重试";
        } else {
          errorMessage = "";
        }
        break;

      case DioExceptionType.cancel:
        errorMessage = "请求已取消";
        break;

      case DioExceptionType.badCertificate:
        errorMessage = "服务器证书验证失败";
        break;

      case DioExceptionType.connectionError:
        errorMessage = "网络连接异常，请检查网络";
        break;

      default:
        errorMessage = err.message ?? "请求异常";
    }

    // 💡 如果服务器有响应，尝试提取 message
    if (response != null) {
      final apiResponse = ApiResponse.formJsonResponse(response!.data);
      print('❌ 服务器返回: $apiResponse');
      errorMessage = apiResponse.message;
    }

  ToastUtils.showToast(errorMessage);
    super.onError(err, handler);
  }
}
