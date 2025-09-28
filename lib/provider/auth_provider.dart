// import 'dart:convert';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:heart_days/apis/user.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// // ==== 登录状态结构 ====
// class AuthState {
//   final String? token;
//   final String? refreshToken;
//   final User? user;
//   final bool isInitialized;
//
//   const AuthState({
//     this.token,
//     this.refreshToken,
//     this.user,
//     this.isInitialized = false,
//   });
//
//   bool get isLoggedIn => token != null && user != null;
//
//   Map<String, dynamic> toJson() => {
//     'token': token,
//     'refreshToken': refreshToken,
//     'user': user?.toJson(),
//   };
//
//   factory AuthState.fromJson(Map<String, dynamic> json) => AuthState(
//     token: json['token'],
//     refreshToken: json['refreshToken'],
//     user: json['user'] != null ? User.fromJson(json['user']) : null,
//     isInitialized: true,
//   );
//
//   AuthState copyWith({
//     String? token,
//     String? refreshToken,
//     User? user,
//     bool? isInitialized,
//   }) =>
//       AuthState(
//         token: token ?? this.token,
//         refreshToken: refreshToken ?? this.refreshToken,
//         user: user ?? this.user,
//         isInitialized: isInitialized ?? this.isInitialized,
//       );
// }
//
// // ==== Provider 定义 ====
// final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
//   final notifier = AuthNotifier();
//   notifier.loadFromStorage(); // 启动时加载
//   return notifier;
// });
//
// // ==== Notifier ====
// class AuthNotifier extends StateNotifier<AuthState> {
//   static const _storageKey = 'auth_data';
//
//   AuthNotifier() : super(const AuthState());
//
//   bool _isRefreshing = false;
//   bool get isRefreshing => _isRefreshing;
//
//   // ==== 本地加载 ====
//   Future<void> loadFromStorage() async {
//     final prefs = await SharedPreferences.getInstance();
//     final raw = prefs.getString(_storageKey);
//
//     if (raw != null) {
//       final map = jsonDecode(raw);
//       state = AuthState.fromJson(map);
//     } else {
//       state = const AuthState(isInitialized: true);
//     }
//   }
//
//   // ==== 登录成功 ====
//   Future<void> login(User user, String token, {String? refreshToken}) async {
//     state = AuthState(
//       user: user,
//       token: token,
//       refreshToken: refreshToken,
//       isInitialized: true,
//     );
//     await _saveToStorage();
//   }
//
//   // ==== 更新用户信息 ====
//   Future<void> setLoginUser(User user) async {
//     state = state.copyWith(user: user);
//     await _saveToStorage();
//   }
//
//   // ==== 登出 ====
//   Future<void> logout() async {
//     state = const AuthState(isInitialized: true);
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_storageKey);
//     await prefs.clear();
//   }
//
//   // ==== Getter ====
//   User? get user => state.user;
//   String? get token => state.token;
//   String? get refreshToken => state.refreshToken;
//   bool get isLoggedIn => state.isLoggedIn;
//
//   // ==== Setter（自动保存）====
//   set user(User? newUser) {
//     state = state.copyWith(user: newUser);
//     _saveToStorage();
//   }
//
//   set token(String? newToken) {
//     state = state.copyWith(token: newToken);
//     _saveToStorage();
//   }
//
//   set refreshToken(String? newRefreshToken) {
//     state = state.copyWith(refreshToken: newRefreshToken);
//     _saveToStorage();
//   }
//
//   // ==== 本地存储 ====
//   Future<void> _saveToStorage() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_storageKey, jsonEncode(state.toJson()));
//   }
// }

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/common/toast.dart';
import 'package:heart_days/services/ChatSocketService.dart';
import 'package:heart_days/utils/UserSessionManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ================== AuthState ==================
class AuthState {
  final String? token;
  final String? refreshToken;
  final User? user;
  final bool isInitialized;

  const AuthState({
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

  AuthState copyWith({
    String? token,
    String? refreshToken,
    User? user,
    bool? isInitialized,
  }) => AuthState(
    token: token ?? this.token,
    refreshToken: refreshToken ?? this.refreshToken,
    user: user ?? this.user,
    isInitialized: isInitialized ?? this.isInitialized,
  );
}

// ================== Provider ==================
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier();
  notifier.loadFromStorage();
  return notifier;
});

// ================== Notifier ==================
class AuthNotifier extends StateNotifier<AuthState> {
  static const _storageKey = 'auth_data';
  static const _debounceDuration = Duration(milliseconds: 300);

  AuthNotifier() : super(const AuthState());

  // 防抖用
  Timer? _saveDebounceTimer;

  // token 刷新锁
  bool _isRefreshing = false;

  bool get isRefreshing => _isRefreshing;

  // ---------------- 加载 ----------------
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw != null) {
      state = AuthState.fromJson(jsonDecode(raw));
    } else {
      state = const AuthState(isInitialized: true);
    }
  }

  // ---------------- 登录 ----------------
  Future<void> login(User user, String token, {String? refreshToken}) async {
    state = AuthState(
      user: user,
      token: token,
      refreshToken: refreshToken,
      isInitialized: true,
    );
    _scheduleSave();
    
    // 通知UserSessionManager token已更新
    try {
      final sessionManager = UserSessionManager();
      if (sessionManager.currentToken != token) {
        print('🔄 AuthProvider检测到token变化，通知UserSessionManager');
        await sessionManager.refreshToken(token);
      }
    } catch (e) {
      print('⚠️ AuthProvider通知UserSessionManager失败: $e');
    }
  }

  // ---------------- 更新用户信息 ----------------
  Future<void> setLoginUser(User user) async {
    state = state.copyWith(user: user);
    _scheduleSave();
  }

  // ---------------- 登出 ----------------
  Future<void> logout() async {
    _saveDebounceTimer?.cancel(); // 取消未完成的保存
    state = const AuthState(isInitialized: true);
    await ChatSocketService().destroy();
    await UserSessionManager().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await prefs.remove('token');
    await prefs.remove('refresh_token');
    MyToast.showToast("已退出登录");
  }

  // ---------------- Getter ----------------
  User? get user => state.user;
  String? get token => state.token;
  String? get refreshToken => state.refreshToken;
  bool get isLoggedIn => state.isLoggedIn;

  // ---------------- Setter ----------------
  set user(User? newUser) {
    state = state.copyWith(user: newUser);
    _scheduleSave();
  }

  set token(String? newToken) {
    state = state.copyWith(token: newToken);
    _scheduleSave();
  }

  set refreshToken(String? newRefreshToken) {
    state = state.copyWith(refreshToken: newRefreshToken);
    _scheduleSave();
  }

  // ---------------- 防抖保存 ----------------
  void _scheduleSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_debounceDuration, _saveToStorage);
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  // 释放资源
  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    super.dispose();
  }
}