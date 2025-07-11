import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenInterceptorHandler extends Interceptor {
  SharedPreferences? _prefs;
  final Map<String, bool> _refreshingRequests = {};

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
      Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        if (result == ConnectivityResult.none) {
          ToastUtils.showToast('网络连接已断开');
        }
      });
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
    const authWhitelist = ['/login', '/register', '/auth/refresh'];

    bool isWhitelisted(String path) {
      return authWhitelist.any((api) => path.contains(api));
    }

    if (!isWhitelisted(err.requestOptions.path) &&
        err.response?.statusCode == 401) {
      // print('🔁 Token 过期，处理退出逻辑...');
      print('🔁 Token 过期，处理退出逻辑...,刷新token');

      // 检查是否已经在刷新中
      final requestKey = err.requestOptions.path;
      if (_refreshingRequests[requestKey] == true) {
        print('⚠️ 该请求已在刷新中，直接返回错误');
        handler.next(err);
        return;
      }

      _refreshingRequests[requestKey] == true;
      try {
        // 尝试刷新token

        final p = await prefs;
        final refreshToken = p.getString('refresh_token');
        final refreshSuccess = await refreshTokenApi({
          "refresh_token": refreshToken,
        });

        if (refreshSuccess.code == 200) {
          print('✅ Token刷新成功，重试原请求');
          print(refreshSuccess);
          final p = await prefs;
          // 获取新的token
          final newToken = refreshSuccess.data?["access_token"];
          final newRefreshToken = refreshSuccess.data?["refresh_token"];
          p.setString('token',newToken);
          p.setString('refresh_token',newRefreshToken);
          if (newToken != null) {
            // 更新请求头
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';

            // 重试原请求
            final dio = Dio();
            final response = await dio.fetch(err.requestOptions);
            handler.resolve(response);
            return;
          }
        } else {
          print('❌ Token刷新失败，触发登出');
          // 刷新失败，触发登出
          final p = await prefs;
          await p.remove('token');
          await p.remove('auth_data');
          eventBus.fire(TokenExpiredEvent());
        }
      } catch (e) {
        print('❌ Token刷新异常: $e');
        // 刷新异常，触发登出
        final p = await prefs;
        await p.remove('token');
        await p.remove('auth_data');
        eventBus.fire(TokenExpiredEvent());
      } finally {
        _refreshingRequests[requestKey] = false;
      }

    }
    handler.next(err); // 继续传递错误
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 可以在这里处理响应，比如检查token是否即将过期
    handler.next(response);
  }
}
