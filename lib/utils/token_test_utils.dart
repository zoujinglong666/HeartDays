import 'package:heart_days/http/interceptors/token_interceptor.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Token测试工具类
/// 用于验证token更新机制是否正常工作
class TokenTestUtils {
  
  /// 测试token更新流程
  static Future<void> testTokenUpdate() async {
    print('=== Token Update Test Started ===');
    
    try {
      // 1. 检查SharedPreferences中的token
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('token');
      final storedRefreshToken = prefs.getString('refresh_token');
      
      print('Stored token: ${storedToken?.substring(0, 20)}...');
      print('Stored refresh token: ${storedRefreshToken?.substring(0, 20)}...');
      
      // 2. 触发强制刷新
      print('Triggering force refresh...');
      TokenInterceptorHandler.forceRefreshToken();
      
      // 3. 等待一段时间确保更新完成
      await Future.delayed(Duration(milliseconds: 500));
      
      print('=== Token Update Test Completed ===');
      
    } catch (e) {
      print('Token test error: $e');
    }
  }
  
  /// 验证token格式
  static bool validateTokenFormat(String? token) {
    if (token == null || token.isEmpty) {
      print('Token validation failed: Token is null or empty');
      return false;
    }
    
    if (!token.startsWith('eyJ')) {
      print('Token validation failed: Invalid JWT format');
      return false;
    }
    
    final parts = token.split('.');
    if (parts.length != 3) {
      print('Token validation failed: JWT should have 3 parts');
      return false;
    }
    
    print('Token validation passed');
    return true;
  }
  
  /// 比较两个token是否相同
  static bool compareTokens(String? token1, String? token2) {
    if (token1 == null && token2 == null) return true;
    if (token1 == null || token2 == null) return false;
    
    final isSame = token1 == token2;
    print('Token comparison: ${isSame ? "Same" : "Different"}');
    
    if (!isSame) {
      print('Token1: ${token1.substring(0, 20)}...');
      print('Token2: ${token2.substring(0, 20)}...');
    }
    
    return isSame;
  }
}