import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

class DeviceUtils {
  static const String _deviceIdKey = 'device_id';
  static const String _deviceInfoKey = 'device_info';
  
  /// 获取或生成设备唯一标识
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);
    
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = await _generateDeviceId();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    
    return deviceId;
  }
  
  /// 生成设备唯一标识
  static Future<String> _generateDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = '${androidInfo.brand}_${androidInfo.model}_${androidInfo.id}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = '${iosInfo.name}_${iosInfo.model}_${iosInfo.identifierForVendor}';
      } else {
        // 其他平台使用随机ID
        deviceId = 'unknown_${Random().nextInt(999999)}';
      }
      
      // 添加时间戳确保唯一性
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(1000);
      
      return '${deviceId}_$timestamp$random';
    } catch (e) {
      print('生成设备ID失败: $e');
      // 降级方案：使用随机ID
      return 'device_${Random().nextInt(999999)}_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  /// 获取设备信息
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      Map<String, dynamic> info = {};
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info = {
          'platform': 'android',
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info = {
          'platform': 'ios',
          'name': iosInfo.name,
          'model': iosInfo.model,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
        };
      }
      
      return info;
    } catch (e) {
      print('获取设备信息失败: $e');
      return {'platform': 'unknown'};
    }
  }
  
  /// 保存设备信息到本地
  static Future<void> saveDeviceInfo() async {
    try {
      final deviceInfo = await getDeviceInfo();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deviceInfoKey, jsonEncode(deviceInfo));
    } catch (e) {
      print('保存设备信息失败: $e');
    }
  }
  
  /// 获取本地保存的设备信息
  static Future<Map<String, dynamic>?> getLocalDeviceInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final infoStr = prefs.getString(_deviceInfoKey);
      if (infoStr != null) {
        return jsonDecode(infoStr) as Map<String, dynamic>;
      }
    } catch (e) {
      print('获取本地设备信息失败: $e');
    }
    return null;
  }
} 