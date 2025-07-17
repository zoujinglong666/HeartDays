import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenInterceptorHandler extends Interceptor {
  SharedPreferences? _prefs;
  final Dio _dio;

  TokenInterceptorHandler(this._dio);

  final List<String> authWhitelist = [
    '/login',
    '/register',
    '/auth/refresh',
  ];

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  bool _isRefreshing = false;
  final List<Function(String)> _retryQueue = [];

  /// 保存已重试请求的 key，防止重复 retry
  final Set<String> _retriedRequests = {};

  /// 缓存 key：用于判断请求唯一性（路径+方法）
  String _cacheKey(RequestOptions options) =>
      "${options.method}:${options.path}:${options.queryParameters.toString()}";

  /// 网络监听只注册一次
  static bool _hasNetworkListener = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      if (!_hasNetworkListener) {
        _hasNetworkListener = true;
        Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
          if (result == ConnectivityResult.none) {
            ToastUtils.showToast('网络连接已断开');
          }
        });
      }

      final p = await prefs;
      final token = p.getString('token');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (e) {
      handler.next(options);
    }
  }

  bool _isWhitelisted(String path) {
    return authWhitelist.any((api) => path.contains(api));
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final key = _cacheKey(err.requestOptions);

    if (err.response?.statusCode == 401 && !_isWhitelisted(path)) {
      final prefsInstance = await prefs;
      final oldRefreshToken = prefsInstance.getString("refresh_token");

      // ✅ 如果没有 refresh_token，直接退出登录
      if (oldRefreshToken == null || oldRefreshToken.isEmpty) {
        print("⚠️ 无有效 Refresh Token，退出登录");
        await _logout();
        handler.reject(err); // 拒绝当前请求
        return;
      }
      if (_isRefreshing) {
        print("⏳ 正在刷新 Token，将请求加入队列等待: $path");
        _retryQueue.add((String token) async {
          try {
            if (_retriedRequests.contains(key)) return;
            _retriedRequests.add(key);
            final clonedRequest = await _retryRequest(err.requestOptions, token);
            handler.resolve(clonedRequest);
          } catch (e) {
            handler.reject(e as DioException);
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

            // 当前请求也一起重试
            if (!_retriedRequests.contains(key)) {
              _retriedRequests.add(key);
              final retryResponse = await _retryRequest(err.requestOptions, newToken);
              handler.resolve(retryResponse);
            }

            // 队列中所有请求
            for (var retry in _retryQueue) {
              retry(newToken);
            }
            _retryQueue.clear();

            print("✅ Token刷新成功，所有请求已重试");
            return;
          }
        }

        print("❌ Token刷新失败");
        await _logout();

        handler.reject(err);
        for (var retry in _retryQueue) {
          retry("");
        }
        _retryQueue.clear();
      } catch (e) {
        print("❌ 刷新异常: $e");
        await _logout();

        handler.reject(err);
        for (var retry in _retryQueue) {
          retry("");
        }
        _retryQueue.clear();
      } finally {
        _isRefreshing = false;
        _retriedRequests.clear();
      }
    } else {
      handler.next(err);
    }
  }

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

  Future<void> _logout() async {
    final prefsInstance = await prefs;
    await prefsInstance.remove('token');
    await prefsInstance.remove('refresh_token');
    await prefsInstance.remove('auth_data');
    eventBus.fire(TokenExpiredEvent());
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }
}
