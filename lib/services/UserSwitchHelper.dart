import 'package:shared_preferences/shared_preferences.dart';
import 'ChatSocketService.dart';

/// 用户切换辅助类
/// 用于处理用户登录/切换时的WebSocket连接管理
class UserSwitchHelper {
  static final UserSwitchHelper _instance = UserSwitchHelper._internal();
  factory UserSwitchHelper() => _instance;
  UserSwitchHelper._internal();

  final ChatSocketService _chatService = ChatSocketService();

  /// 用户登录时调用
  /// [token] 新用户的认证token
  /// [userId] 新用户的ID
  Future<void> onUserLogin(String token, String userId) async {
    print('👤 用户登录: $userId');
    
    // 保存新用户信息到本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userId', userId);
    
    // 安全切换WebSocket连接
    await _chatService.safeUserSwitch(token, userId);
  }

  /// 用户登出时调用
  Future<void> onUserLogout() async {
    print('👤 用户登出');
    
    // 清理本地存储
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    
    // 重置WebSocket服务
    _chatService.reset();
  }

  /// 检查并处理用户切换
  /// 在应用启动或关键操作前调用
  Future<void> checkUserSwitch() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token');
    final storedUserId = prefs.getString('userId');
    
    if (storedToken == null || storedUserId == null) {
      print('⚠️ 没有找到存储的用户信息');
      return;
    }
    
    // 检查当前WebSocket连接的用户是否与存储的用户一致
    if (!_chatService.isCurrentUser(storedUserId)) {
      print('🔄 检测到用户不一致，执行切换');
      await _chatService.safeUserSwitch(storedToken, storedUserId);
    } else {
      print('✅ 用户信息一致');
      // 检查token是否需要更新
      _chatService.checkAndUpdateToken();
    }
  }

  /// 强制刷新连接（调试用）
  Future<void> forceRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');
    
    if (token != null && userId != null) {
      print('🔧 强制刷新连接');
      await _chatService.safeUserSwitch(token, userId);
    }
  }
}