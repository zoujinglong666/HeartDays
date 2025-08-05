import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/common/event_bus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _refreshTokenExpiryKey = 'refresh_token_expiry';

  Timer? _tokenCheckTimer;
  final WidgetRef ref;

  TokenManager(this.ref);

  /// 启动token检查定时器
  void startTokenCheck() {
    stopTokenCheck(); // 先停止之前的定时器

    // 每5分钟检查一次token状态
    _tokenCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkTokenStatus();
    });
  }

  /// 停止token检查定时器
  void stopTokenCheck() {
    _tokenCheckTimer?.cancel();
    _tokenCheckTimer = null;
  }

  /// 检查token状态
  Future<void> _checkTokenStatus() async {
    try {
      final authNotifier = ref.read(authProvider.notifier);

      // 如果没有登录，不需要检查
      if (!authNotifier.isLoggedIn) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final tokenExpiry = prefs.getInt(_tokenExpiryKey);
      final refreshTokenExpiry = prefs.getInt(_refreshTokenExpiryKey);

      final now = DateTime.now().millisecondsSinceEpoch;

      // 检查access token是否即将过期（提前10分钟刷新）
      if (tokenExpiry != null && now + 600000 > tokenExpiry) {
        print('⚠️ Access token即将过期，尝试刷新...');
        await _refreshTokenIfNeeded();
      }

      // 检查refresh token是否已过期
      if (refreshTokenExpiry != null && now > refreshTokenExpiry) {
        print('❌ Refresh token已过期，触发登出');
        eventBus.fire(TokenExpiredEvent());
      }
    } catch (e) {
      print('检查token状态失败: $e');
    }
  }

  /// 刷新token（如果需要）
  Future<void> _refreshTokenIfNeeded() async {
    try {
      final authNotifier = ref.read(authProvider.notifier);

      // 如果正在刷新，跳过
      if (authNotifier.isRefreshing) {
        return;
      }

      final refreshSuccess = await authNotifier.refreshAccessToken();

      if (refreshSuccess) {
        print('✅ Token自动刷新成功');
      } else {
        print('❌ Token自动刷新失败');
        eventBus.fire(TokenExpiredEvent());
      }
    } catch (e) {
      print('Token自动刷新异常: $e');
      eventBus.fire(TokenExpiredEvent());
    }
  }

  /// 保存token过期时间
  Future<void> saveTokenExpiry(
      int accessTokenExpiry,
      int refreshTokenExpiry,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tokenExpiryKey, accessTokenExpiry);
    await prefs.setInt(_refreshTokenExpiryKey, refreshTokenExpiry);
  }

  /// 清除token过期时间
  Future<void> clearTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_refreshTokenExpiryKey);
  }

  /// 检查token是否即将过期
  Future<bool> isTokenExpiringSoon() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tokenExpiry = prefs.getInt(_tokenExpiryKey);

      if (tokenExpiry == null) {
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      // 如果token在10分钟内过期，认为即将过期
      return now + 600000 > tokenExpiry;
    } catch (e) {
      print('检查token过期状态失败: $e');
      return false;
    }
  }

  /// 强制刷新token
  Future<bool> forceRefreshToken() async {
    try {
      final authNotifier = ref.read(authProvider.notifier);
      return await authNotifier.refreshAccessToken();
    } catch (e) {
      print('强制刷新token失败: $e');
      return false;
    }
  }
}
