import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkUtils {
  /// 检查设备是否有网络连接
  static Future<bool> isConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('网络连接检查失败: $e');
      return false; // 发生错误时默认返回无连接
    }
  }

  /// 检查是否是WiFi连接
  static Future<bool> isWifiConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      print('WiFi连接检查失败: $e');
      return false;
    }
  }

  /// 检查是否是移动数据连接
  static Future<bool> isMobileDataConnected() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.mobile;
    } catch (e) {
      print('移动数据连接检查失败: $e');
      return false;
    }
  }

  /// 获取当前网络连接类型
  static Future<String> getNetworkType() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return '移动数据';
        case ConnectivityResult.none:
          return '无网络';
        default:
          return '未知网络';
      }
    } catch (e) {
      print('获取网络类型失败: $e');
      return '获取失败';
    }
  }
}