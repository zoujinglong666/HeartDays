import 'dart:io';

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

    // 特殊处理 401 错误（如 token 过期）
    if (response?.statusCode == 401) {
      print("⚠️ 检测到 401 错误，跳过提示（由刷新 token 逻辑处理）");
      super.onError(err, handler);
      return;
    }

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
          errorMessage = "发生未知错误";
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
    }

    ToastUtils.showToast(errorMessage);
    super.onError(err, handler);
  }



}
