import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/api/user.dart';
import 'package:shared_preferences/shared_preferences.dart';


// ==== 登录状态结构 ====
class AuthState {
  final String? token;
  final User? user;
  final bool isInitialized; // ✅ 新增字段

  AuthState({
    this.token,
    this.user,
    this.isInitialized = false,
  });

  bool get isLoggedIn => token != null && user != null;

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user?.toJson(),
  };

  factory AuthState.fromJson(Map<String, dynamic> json) => AuthState(
    token: json['token'],
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

  AuthNotifier() : super(AuthState());

  /// ✅ 从本地加载登录信息
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null) {
      final map = jsonDecode(raw);
      state = AuthState.fromJson(map);
    } else {
      state = AuthState(isInitialized: true);
    }
  }

  /// ✅ 登录成功，更新状态并存储
  Future<void> login(User user, String token) async {
    state = AuthState(
      user: user,
      token: token,
      isInitialized: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<void> setLoginUser(User user) async {
    state = AuthState(
      user: user,
      token: token,
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
  }
//   final auth = ref.read(authProvider.notifier);
//
// // 读取
//   final currentUser = auth.user;
//   final token = auth.token;
//
// // 更新 user
//   auth.user = updatedUser;
//
// // 更新 token
//   auth.token = 'new_token_value';



  // ✅ Getter
  User? get user => state.user;
  String? get token => state.token;
  bool get isLoggedIn => state.isLoggedIn;

  // ✅ Setter（并自动同步状态）
  set user(User? newUser) {
    state = AuthState(
      user: newUser,
      token: state.token,
      isInitialized: true,
    );
    _saveToStorage();
  }

  set token(String? newToken) {
    state = AuthState(
      user: state.user,
      token: newToken,
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


