import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heart_days/utils/token_manager.dart';
import 'package:heart_days/common/event_bus.dart';

// ==== 登录状态结构 ====
class AuthState {
  final String? token;
  final String? refreshToken; // 新增refreshToken字段
  final User? user;
  final bool isInitialized; // ✅ 新增字段

  AuthState({
    this.token,
    this.refreshToken,
    this.user,
    this.isInitialized = false,
  });

  bool get isLoggedIn => token != null && user != null;
  Map<String, dynamic> toJson() => {
    'token': token,
    'refreshToken': refreshToken,
    'user': user?.toJson(),
  };

  factory AuthState.fromJson(Map<String, dynamic> json) => AuthState(
    token: json['token'],
    refreshToken: json['refreshToken'],
    user: json['user'] != null ? User.fromJson(json['user']) : null,
    isInitialized: true,
  );
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier();
  notifier.loadFromStorage(); // 👈 启动时加载
  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  static const _storageKey = 'auth_data';
  bool _isRefreshing = false; // 防止重复刷新
  AuthNotifier() : super(AuthState());
  User? globalCurrentUser;



  /// ✅ 从本地加载登录信息
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null) {
      final map = jsonDecode(raw);
      state = AuthState.fromJson(map);

      // 如果已登录，启动token检查
      if (state.isLoggedIn) {
        // tokenManager?.startTokenCheck();
      }
    } else {
      state = AuthState(isInitialized: true);
    }
  }

  /// ✅ 登录成功，更新状态并存储
  Future<void> login(User user, String token, {String? refreshToken}) async {
    state = AuthState(
      user: user,
      token: token,
      refreshToken: refreshToken,
      isInitialized: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    globalCurrentUser=user;
    // 启动token检查
    // _tokenManager?.startTokenCheck();
  }

  /// 刷新token
  Future<bool> refreshAccessToken() async {
    if (_isRefreshing || state.refreshToken == null) {
      return false;
    }

    _isRefreshing = true;

    try {
      // 使用正确的函数调用
      final response = await refreshTokenApi!({
        "refresh_token": state.refreshToken,
      });

      if (response.code == 200 && response.data != null) {
        final data = response.data!;
        final newAccessToken = data['accessToken'] as String?;
        final newRefreshToken = data['refreshToken'] as String?;
        final accessTokenExpiry = data['accessTokenExpiry'] as int?;
        final refreshTokenExpiry = data['refreshTokenExpiry'] as int?;
        if (newAccessToken != null && newRefreshToken != null) {
          // 更新token
          state = AuthState(
            user: state.user,
            token: newAccessToken,
            refreshToken: newRefreshToken,
            isInitialized: true,
          );

          // 保存到本地
          await _saveToStorage();

          // 保存token过期时间
          if (accessTokenExpiry != null && refreshTokenExpiry != null) {
            // await _tokenManager?.saveTokenExpiry(accessTokenExpiry, refreshTokenExpiry);
          }

          // 触发刷新成功事件
          eventBus.fire(TokenRefreshSuccessEvent(
            newAccessToken: newAccessToken,
            newRefreshToken: newRefreshToken,
          ));

          print('✅ Token 刷新成功');
          return true;
        }
      }

      // 刷新失败，触发失败事件
      eventBus.fire(TokenRefreshFailedEvent(reason: response.message ?? '刷新失败'));
      print('❌ Token 刷新失败: ${response.message}');
      return false;

    } catch (e) {
      print('❌ Token 刷新异常: $e');
      eventBus.fire(TokenRefreshFailedEvent(reason: e.toString()));
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> setLoginUser(User user) async {
    state = AuthState(
      user: user,
      token: token,
      refreshToken: state.refreshToken,
      isInitialized: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  /// ✅ 登出
  Future<void> logout() async {
    state = AuthState(isInitialized: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove('token');
    await prefs.remove('refreshToken');
  }

  // ✅ Getter
  User? get user => state.user;
  String? get token => state.token;
  String? get refreshToken => state.refreshToken;
  bool get isLoggedIn => state.isLoggedIn;
  bool get isRefreshing => _isRefreshing;

  // ✅ Setter（并自动同步状态）
  set user(User? newUser) {
    state = AuthState(
      user: newUser,
      token: state.token,
      refreshToken: state.refreshToken,
      isInitialized: true,
    );
    _saveToStorage();
  }

  set token(String? newToken) {
    state = AuthState(
      user: state.user,
      token: newToken,
      refreshToken: state.refreshToken,
      isInitialized: true,
    );
    _saveToStorage();
  }

  set refreshToken(String? newRefreshToken) {
    state = AuthState(
      user: state.user,
      token: state.token,
      refreshToken: newRefreshToken,
      isInitialized: true,
    );
    _saveToStorage();
  }

  /// ✅ 封装的本地存储方法
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }
}


