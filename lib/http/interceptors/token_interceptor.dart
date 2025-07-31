import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:heart_days/http/model/api_response.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenInterceptorHandler extends Interceptor {
  final Dio _dio;
  final AuthNotifier _authNotifier;
  SharedPreferences? _prefs;

  TokenInterceptorHandler(this._dio, this._authNotifier) {
    SharedPreferences.getInstance().then((instance) => _prefs = instance);
  }

  final List<String> authWhitelist = [
    '/login',
    '/register',
    '/auth/refresh',
  ];

  final List<Function(String)> _retryQueue = [];
  final Set<String> _retriedRequests = {};
  static bool _hasNetworkListener = false;
  bool _isRefreshing = false;

  String _cacheKey(RequestOptions options) =>
      "${options.method}:${options.path}:${options.queryParameters}";

  bool _isWhitelisted(String path) =>
      authWhitelist.any((api) => path.contains(api));

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

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
      final token = _authNotifier.token ?? p.getString('token');

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (e) {
      handler.next(options);
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final response = err.response;

    if (response == null || response.data == null) {
      handler.next(err);
      return;
    }

    final apiResponse = ApiResponse.formJsonResponse(response.data);
    final key = _cacheKey(err.requestOptions);

    // token 已失效，直接退出登录
    if (apiResponse.code == 40103) {
      await _logout();
      handler.reject(err);
      return;
    }

    // token 过期，尝试刷新
    if (apiResponse.code == 40100 && !_isWhitelisted(path)) {
      final prefsInstance = await prefs;
      final oldRefreshToken = _authNotifier.refreshToken ?? prefsInstance.getString("refresh_token");
      if (oldRefreshToken == null || oldRefreshToken.isEmpty) {
        print("⚠️ 没有 refresh_token，退出登录");
        await _logout();
        handler.reject(err);
        return;
      }

      // 等待刷新完成后重试当前请求
      if (_isRefreshing) {
        print("⏳ 正在刷新 Token，将请求加入队列等待: $path");
        _retryQueue.add((String newToken) async {
          if (_retriedRequests.contains(key)) return;
          _retriedRequests.add(key);
          try {
            final retryResponse = await _retryRequest(err.requestOptions, newToken);
            handler.resolve(retryResponse);
          } catch (e) {
            handler.reject(err);
          }
        });
        return;
      }

      _isRefreshing = true;

      try {
        print("🔁 开始刷新 Token");
        final refreshResult = await refreshTokenApi({"refresh_token": oldRefreshToken});

        if (refreshResult.code == 200) {
          final newToken = refreshResult.data?['access_token'];
          final newRefreshToken = refreshResult.data?['refresh_token'];

          if (newToken != null && newRefreshToken != null) {
            _authNotifier.token = newToken;
            _authNotifier.refreshToken = newRefreshToken;
            await prefsInstance.setString('token', newToken);
            await prefsInstance.setString('refresh_token', newRefreshToken);
            _dio.options.headers['Authorization'] = 'Bearer $newToken';

            // 等一帧，确保 token 更新完毕
            await Future.delayed(Duration(milliseconds: 10));

            if (!_retriedRequests.contains(key)) {
              _retriedRequests.add(key);
              final retryResponse = await _retryRequest(err.requestOptions, newToken);
              handler.resolve(retryResponse);
            }

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
          retry(""); // 通知失败
        }
        _retryQueue.clear();
      } catch (e) {
        print("❌ 刷新失败异常: $e");
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

  Future<Response> _retryRequest(RequestOptions requestOptions, String newToken) async {
    final headers = Map<String, dynamic>.from(requestOptions.headers)
      ..['Authorization'] = 'Bearer $newToken';

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        contentType: requestOptions.contentType,
        responseType: requestOptions.responseType,
      ),
    );
  }

  Future<void> _logout() async {
    _authNotifier.logout();
    eventBus.fire(TokenExpiredEvent());
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }
}
