import 'package:shared_preferences/shared_preferences.dart';
import '../services/UserSwitchHelper.dart';

/// 用户会话管理器
/// 统一管理用户登录状态和WebSocket连接
class UserSessionManager {
  static final UserSessionManager _instance = UserSessionManager._internal();
  factory UserSessionManager() => _instance;
  UserSessionManager._internal();

  final UserSwitchHelper _switchHelper = UserSwitchHelper();
  
  String? _currentUserId;
  String? _currentToken;

  /// 初始化会话管理器
  /// 在应用启动时调用
  Future<void> initialize() async {
    print('🚀 初始化用户会话管理器');
    
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    _currentToken = prefs.getString('token');
    
    if (_currentUserId != null && _currentToken != null) {
      print('📱 发现已登录用户: $_currentUserId');
      await _switchHelper.checkUserSwitch();
    } else {
      print('📱 未发现登录用户');
    }
  }

  /// 用户登录
  Future<void> login(String token, String userId) async {
    print('🔐 用户登录: $userId');
    
    // 检查是否为同一用户
    if (_currentUserId == userId && _currentToken == token) {
      print('✅ 同一用户重复登录，跳过');
      return;
    }
    
    // 如果是不同用户，先处理切换
    if (_currentUserId != null && _currentUserId != userId) {
      print('🔄 检测到用户切换: $_currentUserId -> $userId');
    }
    
    // 更新当前用户信息
    _currentUserId = userId;
    _currentToken = token;
    
    // 保存用户信息
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('token', token);
    

    
    // 处理WebSocket连接
    await _switchHelper.onUserLogin(token, userId);
  }

  /// 用户登出
  Future<void> logout() async {
    print('🚪 用户登出: $_currentUserId');
    
    _currentUserId = null;
    _currentToken = null;
    
    // 清理本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 或者选择性清理特定键
    
    // 处理WebSocket断开
    await _switchHelper.onUserLogout();
  }

  /// 刷新token
  Future<void> refreshToken(String newToken) async {
    if (_currentUserId == null) {
      print('⚠️ 没有当前用户，无法刷新token');
      return;
    }
    
    print('🔄 刷新token: ${newToken.substring(0, 20)}...');
    
    _currentToken = newToken;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', newToken);
    
    // 使用新token重新连接WebSocket
    await _switchHelper.onUserLogin(newToken, _currentUserId!);
  }

  /// 检查登录状态
  bool get isLoggedIn => _currentUserId != null && _currentToken != null;

  /// 获取当前用户ID
  String? get currentUserId => _currentUserId;

  /// 获取当前token
  String? get currentToken => _currentToken;

  /// 验证会话有效性
  Future<bool> validateSession() async {
    if (!isLoggedIn) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('userId');
    final storedToken = prefs.getString('token');
    
    return storedUserId == _currentUserId && storedToken == _currentToken;
  }

  /// 检查并处理用户切换
  /// 在应用启动或关键操作前调用
  Future<void> checkUserSwitch() async {
    await _switchHelper.checkUserSwitch();
  }

  /// 强制刷新连接（调试用）
  Future<void> forceRefresh() async {
    await _switchHelper.forceRefresh();
  }
}