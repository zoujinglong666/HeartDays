import 'dart:convert';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginUserInfo {
  // 缓存 SharedPreferences 实例，避免重复初始化
  SharedPreferences? _prefs;

  // 私有方法：获取 SharedPreferences 实例（单例模式）
  Future<SharedPreferences> get _prefsInstance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// 获取当前用户的 Token
  Future<String?> getToken() async {
    try {
      final prefs = await _prefsInstance;
      return prefs.getString('token');
    } catch (e) {
      // 实际项目中建议用日志工具（如 logger）记录错误
      print('Error fetching token: $e');
      return null;
    }
  }

  /// 获取当前用户的 ID
  /// 返回 `String?` 类型，可能为 null（如果未登录或数据损坏）
  Future<String?> getUserId() async {
    try {
      final prefs = await _prefsInstance;
      final authDataString = prefs.getString('auth_data');

      if (authDataString == null || authDataString.isEmpty) {
        return null;
      }
      // 安全解析 JSON 数据
      final Map<String, dynamic> authMap = jsonDecode(authDataString);
      final authState = AuthState.fromJson(authMap);

      // 使用空值安全操作符简化代码
      return authState.user?.id;
    } catch (e) {
      print('Error fetching user ID: $e');
      return null;
    }
  }



  Future<User?> getUser() async {
    try {
      final prefs = await _prefsInstance;
      final authDataString = prefs.getString('auth_data');


      final Map<String, dynamic> authMap = jsonDecode(authDataString!);
      final authState = AuthState.fromJson(authMap);
      return authState!.user;
    } catch (e) {
      return null;
    }
  }


  /// 推荐：一次性获取 token、userId、user
  Future<({String? token, String? userId, User? user})> getLoginState() async {
    try {
      final prefs = await _prefsInstance;
      final token = prefs.getString('token');
      final authDataString = prefs.getString('auth_data');

      if (authDataString == null) {
        return (token: token, userId: null, user: null);
      }

      final Map<String, dynamic> authMap = jsonDecode(authDataString);
      final authState = AuthState.fromJson(authMap);
      return (
      token: token,
      userId: authState.user?.id,
      user: authState.user
      );
    } catch (e) {
      print('getLoginState error: $e');
      return (token: null, userId: null, user: null);
    }
  }


}