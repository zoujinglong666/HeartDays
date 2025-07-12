import 'package:dio/dio.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/common/event_bus.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;

  bool _isRefreshing = false;
  List<Function(String)> _retryQueue = []; // 持有失败请求的处理器

  AuthInterceptor(this._dio);

  final List<String> authWhitelist = [
    '/login',
    '/register',
    '/auth/refresh',
  ];

  get prefs => null;

  bool _isWhitelisted(String path) {
    return authWhitelist.any((api) => path.contains(api));
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;

    if (err.response?.statusCode == 401 && !_isWhitelisted(path)) {
      final prefsInstance = await prefs;
      final oldRefreshToken = prefsInstance.getString("refresh_token");

      // ✅ 如果正在刷新，就把当前请求放到等待队列里
      if (_isRefreshing) {
        print("⏳ 正在刷新 Token，将请求加入队列等待");
        _retryQueue.add((String token) async {
          try {
            final clonedRequest = await _retryRequest(err.requestOptions, token);
            handler.resolve(clonedRequest as Response);
          } catch (e) {
            handler.reject(e as DioError);
          }
        });
        return;
      }

      _isRefreshing = true;

      try {
        print("🔁 开始刷新 Token");
        final refreshSuccess = await refreshTokenApi({
          "refresh_token": oldRefreshToken,
        });

        if (refreshSuccess.code == 200) {
          final newToken = refreshSuccess.data?['access_token'];
          final newRefreshToken = refreshSuccess.data?['refresh_token'];

          if (newToken != null) {
            await prefsInstance.setString('token', newToken);
            await prefsInstance.setString('refresh_token', newRefreshToken);

            _dio.options.headers['Authorization'] = 'Bearer $newToken';

            // 先重试当前请求
            final retryResponse = await _retryRequest(err.requestOptions, newToken);
            handler.resolve(retryResponse as Response);

            // 再处理等待队列
            for (var retry in _retryQueue) {
              retry(newToken);
            }
            _retryQueue.clear();

            print("✅ 刷新成功，所有请求已重试");
            return;
          }
        }

        print("❌ Token刷新失败");
        await _logout();

        handler.reject(err); // 当前请求失败
        for (var retry in _retryQueue) {
          retry(""); // 通知失败
        }
        _retryQueue.clear();
      } catch (e) {
        print("❌ 刷新异常: $e");
        await _logout();

        handler.reject(err); // 当前请求失败
        for (var retry in _retryQueue) {
          retry(""); // 通知失败
        }
        _retryQueue.clear();
      } finally {
        _isRefreshing = false;
      }

    } else {
      handler.next(err); // 非 401 或白名单请求
    }
  }

  /// 尝试重新请求
  Future<Response> _retryRequest(RequestOptions requestOptions, String token) async {
    final options = Options(
      method: requestOptions.method,
      headers: Map<String, dynamic>.from(requestOptions.headers)
        ..['Authorization'] = 'Bearer $token',
    );

    return await _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  /// 退出登录逻辑
  Future<void> _logout() async {
    final prefsInstance = await prefs;
    await prefsInstance.remove('token');
    await prefsInstance.remove('refresh_token');
    await prefsInstance.remove('auth_data');
    eventBus.fire(TokenExpiredEvent());
  }
}
