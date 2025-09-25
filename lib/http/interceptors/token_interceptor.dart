import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:heart_days/http/model/api_response.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/services/ChatSocketService.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenInterceptorHandler extends Interceptor {
  final Dio _dio;
  final AuthNotifier _authNotifier;
  SharedPreferences? _prefs;
  static TokenInterceptorHandler? _instance;

  TokenInterceptorHandler(this._dio, this._authNotifier) {
    SharedPreferences.getInstance().then((instance) => _prefs = instance);
    _instance = this;
  }

  // 静态方法：强制刷新token，用于登录后立即更新
  static Future<void> forceRefreshToken() async {
    if (_instance != null) {
      try {
        print('🔄 强制刷新Token开始');

        final prefsInstance = await _instance!.prefs;

        // 获取最新的token和refresh_token
        final currentToken = prefsInstance.getString('token');
        final currentRefreshToken = prefsInstance.getString('refresh_token');

        print('📱 当前存储的token: ${currentToken?.substring(0, 20) ??
            'null'}...');
        print('📱 当前存储的refresh_token: ${currentRefreshToken?.substring(
            0, 20) ?? 'null'}...');

        // 验证token格式
        if (currentToken != null && currentToken.startsWith('eyJ')) {
          print('✅ Token格式正确');
        } else {
          print('⚠️ Token格式可能有问题');
        }

        // 确保内存和存储同步
        if (currentToken != null && currentToken.isNotEmpty) {
          _instance!._authNotifier.token = currentToken;
          print('🔄 同步token到内存');
        }

        if (currentRefreshToken != null && currentRefreshToken.isNotEmpty) {
          _instance!._authNotifier.refreshToken = currentRefreshToken;
          print('🔄 同步refresh_token到内存');
        }

        print('✅ 强制刷新Token完成');
      } catch (e) {
        print('❌ 强制刷新Token失败: $e');
      }
    } else {
      print(
          'TokenInterceptor: Warning - No instance available for force refresh');
    }
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

      // 请求路径
      final String path = options.path;
      final List<String> noTokenList = ['/login'];
      final bool isNoTokenRequired = noTokenList.any((noTokenPath) =>
          path.contains(noTokenPath));

      final p = await prefs;
      String? token = p.getString('token');
      print('TokenInterceptor: [${isNoTokenRequired
          ? 'NO TOKEN'
          : 'WITH TOKEN'}] ${path} → ${token?.substring(0, 20) ?? 'null'}...');

      // 只对需要 token 的接口加 Authorization 头
      if (!isNoTokenRequired && token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (e) {
      print('TokenInterceptor error: $e');
      handler.next(options);
    }
  }


  // 重试请求的方法
  Future<Response> _retryRequest(RequestOptions requestOptions,
      String newToken) async {
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

  Future<void> _clearData() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
    await p.remove('auth_data');
    await p.remove('refresh_token');
  }
  // 登出方法
  Future<void> _logout() async {
    _authNotifier.logout();
    _clearData();
    eventBus.fire(TokenExpiredEvent());
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
    // if (apiResponse.code == 40103 || apiResponse.code == 40102 ||
    //     apiResponse.code == 40104 || apiResponse.code == 40105) {
    //   print('TokenInterceptor: Token expired (40103), logging out user');
    //   print('TokenInterceptor: Request path: $path');
    //   print('TokenInterceptor: Current token: ${_authNotifier.token?.substring(
    //       0, 20)}...');
    //   await _logout();
    //   handler.reject(err);
    //   return;
    // }

    // token 过期，尝试刷新
    if (apiResponse.code == 40100 && !_isWhitelisted(path)) {
      final prefsInstance = await prefs;
      // 优先使用内存中的refresh_token
      String? oldRefreshToken = _authNotifier.refreshToken;
      if (oldRefreshToken == null || oldRefreshToken.isEmpty) {
        oldRefreshToken = prefsInstance.getString('refresh_token');
      }
      
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
        print("🔄 使用refresh_token: ${oldRefreshToken.substring(0, 20)}...");

        // 直接使用Dio实例调用刷新API，避免循环调用
        final refreshResult = await _dio.post(
          '/auth/refresh',
          data: {"refresh_token": oldRefreshToken},
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              // 刷新token请求不需要Authorization header
            },
          ),
        );

        // 检查HTTP状态码和业务状态码
        if (refreshResult.statusCode == 200) {
          final responseData = refreshResult.data;
          final businessCode = responseData['code'];

          if (businessCode == 200) {
            final newToken = responseData['data']?['access_token'];
            final newRefreshToken = responseData['data']?['refresh_token'];

            if (newToken != null && newRefreshToken != null) {
              // 立即更新内存中的token
              _authNotifier.token = newToken;
              _authNotifier.refreshToken = newRefreshToken;

              // 立即更新Dio实例的headers
              _dio.options.headers['Authorization'] = 'Bearer $newToken';

              // 保存到本地存储
              await prefsInstance.setString('token', newToken);
              await prefsInstance.setString('refresh_token', newRefreshToken);

              print("✅ Token已更新: ${newToken.substring(0, 20)}...");

              // 通知 WebSocket 服务更新连接
              try {
                ChatSocketService().refreshConnection();
                print("🔄 已通知 WebSocket 服务刷新连接");
              } catch (e) {
                print("⚠️ 通知 WebSocket 刷新失败: $e");
              }

              // 等一帧，确保 token 更新完毕
              await Future.delayed(Duration(milliseconds: 10));

              if (!_retriedRequests.contains(key)) {
                _retriedRequests.add(key);
                final retryResponse = await _retryRequest(
                    err.requestOptions, newToken);
                handler.resolve(retryResponse);
              }

              for (var retry in _retryQueue) {
                retry(newToken);
              }
              _retryQueue.clear();
              print("✅ Token刷新成功，所有请求已重试");
              return;
            }
          } else {
            print("❌ Token刷新失败，业务状态码: $businessCode");
          }
        } else {
          print("❌ Token刷新失败，HTTP状态码: ${refreshResult.statusCode}");
        }

        print("❌ Token刷新失败，退出登录");
        await _logout();
        handler.reject(err);
        for (var retry in _retryQueue) {
          retry(""); // 通知失败
        }
        _retryQueue.clear();
      } catch (e) {
        print("❌ 刷新失败异常: $e");

        // 如果是401错误，说明refresh_token也过期了
        if (e is DioException && e.response?.statusCode == 401) {
          print("❌ Refresh token也已过期，需要重新登录");

          await _logout();
        } else {
          print("❌ 其他刷新错误，尝试重新登录");
          await _logout();
        }
        
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

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }
}
