
import 'package:dio/dio.dart';
import 'package:heart_days/http/model/api_response.dart';

class AdapterInterceptorHandler extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 200) { // Http 状态码
      final apiResponse = ApiResponse.formJsonResponse(response.data);
      // 无论HTTP状态码如何，都使用业务状态码
      // 记录详细请求信息用于调试
      // 根据业务状态码处理响应
      if (apiResponse.code == 200) {
        // // 成功情况，直接使用data字段
        // response.data = apiResponse.data;
      } else {
        final result = ApiResponse(
            code: apiResponse.code, message: apiResponse.message);
        print("业务异常");
        // 业务异常（请求是正常的，Result 的 code 不是正常码）
        // 此处是将所有业务码为非正常值的统一归置到异常一类中
        // 这样，我们就可以在统一的通过 catchError 的来捕获这些信息了
        return handler.reject(DioException(
          response: response,
          requestOptions: response.requestOptions,
          error: result,
          message: result.message,
        ));
      }
    }
    super.onResponse(response, handler);
  }
}
