import 'package:dio/dio.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:heart_days/utils/navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenInterceptorHandler extends Interceptor {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final p = await prefs;
      final token = p.getString('token');

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        print('✅ 附带 Token 请求: $token');
      } else {
        print('⚠️ 无 Token，跳过 Authorization 设置');
      }

      handler.next(options);
    } catch (e) {
      print('❌ TokenInterceptor 错误: $e');
      handler.next(options); // 继续请求
    }
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    const authWhitelist = [
      '/login',
      '/register',
    ];

    bool isWhitelisted(String path) {
      return authWhitelist.any((api) => path.contains(api));
    }
    if (!isWhitelisted(err.requestOptions.path) && err.response?.statusCode == 401) {
      print('🔁 Token 过期，处理退出逻辑...');
      final p = await prefs;
      await p.remove('token');
      await p.remove('auth_data');
      eventBus.fire(TokenExpiredEvent());
      NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);

    }
    handler.next(err); // 继续传递错误
  }
}
