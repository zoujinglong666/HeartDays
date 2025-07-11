import 'package:event_bus/event_bus.dart';

final EventBus eventBus = EventBus();
// class TokenExpiredEvent {
//   final String reason;
//   TokenExpiredEvent({required this.reason});
// }
//
// // 使用
// eventBus.fire(TokenExpiredEvent(reason: 'token refresh failed'));
//
// // 监听
// eventBus.on<TokenExpiredEvent>().listen((event) {
// print("Token 过期原因: ${event.reason}");
// });

/// Token 过期事件
class TokenExpiredEvent {}

/// 设备登录冲突事件
class DeviceLoginConflictEvent {
  final String deviceInfo;
  final DateTime loginTime;

  DeviceLoginConflictEvent({required this.deviceInfo, required this.loginTime});
}

/// Token 刷新成功事件
class TokenRefreshSuccessEvent {
  final String newAccessToken;
  final String newRefreshToken;

  TokenRefreshSuccessEvent({
    required this.newAccessToken,
    required this.newRefreshToken,
  });
}

/// Token 刷新失败事件
class TokenRefreshFailedEvent {
  final String reason;

  TokenRefreshFailedEvent({required this.reason});
}

/// 首页纪念日列表刷新 事件
class AnniversaryListUpdated {}
