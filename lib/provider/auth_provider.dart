import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:heart_days/utils/token_manager.dart';

// ==== 登录状态结构 ====
class AuthState {
  final String? token;
  final String? refreshToken;
  final User? user;
  final bool isInitialized;

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
  notifier.loadFromStorage();
  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  static const _storageKey = 'auth_data';
  final bool _isRefreshing = false;
  AuthNotifier() : super(AuthState());
  User? globalCurrentUser;



  /// 从本地加载登录信息
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw);
        state = AuthState.fromJson(map);

      } catch (e) {
        state = AuthState(isInitialized: true);
      }
    } else {
      print('🆕 无存储的认证数据，初始化空状态');
      state = AuthState(isInitialized: true);
    }
  }

  /// 登录成功，更新状态并存储
  Future<void> login(User user, String token, {String? refreshToken}) async {
    state = AuthState(
      user: user,
      token: token,
      refreshToken: refreshToken,
      isInitialized: true,
    );

    await _saveToStorage();
    globalCurrentUser = user;

    print('✅ 登录成功 - Token: $token, User: ${user.name}');
  }

  Future<void> setLoginUser(User user) async {
    state = AuthState(
      user: user,
      token: state.token,
      refreshToken: state.refreshToken,
      isInitialized: true,
    );
    await _saveToStorage();
  }

  /// 登出
  Future<void> logout() async {

    state = AuthState(isInitialized: true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.clear();
    print('🚪 用户已登出');
  }

  // Getter
  User? get user => state.user;
  String? get token => state.token;
  String? get refreshToken => state.refreshToken;
  bool get isLoggedIn => state.isLoggedIn;
  bool get isRefreshing => _isRefreshing;

  // Setter（并自动同步状态）
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

  /// 封装的本地存储方法
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
    print('💾 保存认证数据到存储');
  }

}
