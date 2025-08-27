import 'dart:io';

import 'package:dio/dio.dart';
import 'package:heart_days/http/model/api_response.dart';
import 'package:heart_days/utils/ToastUtils.dart';

class LogInterceptorHandler extends Interceptor {
  /// 处理 token 相关错误 (40101-40109)
  /// 返回 true 表示已处理，false 表示需要继续处理
  bool _handleTokenError(ApiResponse apiResponse) {
    if (apiResponse.code >= 40100 && apiResponse.code <= 40109) {
      return true;
    }
    return false;
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    final apiResponse = ApiResponse.formJsonResponse(response?.data);
    // 40101-40109 都表示 token 相关问题
    // 特殊处理 401 错误（如 token 过期）
    // 这个逻辑很重要 不能删除 留给下一个错误 拦截器 去处理
    if (apiResponse.code >= 40101 && apiResponse.code <= 40109) {
      print("⚠️ 检测到 401 错误，跳过提示（由刷新 token 逻辑处理）");
      super.onError(err, handler);
      return;
    }

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
      print('❌ 服务器返回: $apiResponse');
      errorMessage = apiResponse.message;
    }
    bool isMsgTip = _handleTokenError(apiResponse);
    if (!isMsgTip) {
      ToastUtils.showToast(errorMessage);
    }

    super.onError(err, handler);
  }
}
