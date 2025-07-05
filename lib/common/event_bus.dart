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
