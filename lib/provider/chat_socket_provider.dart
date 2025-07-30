import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heart_days/common/helper.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

typedef SocketEventCallback = void Function(dynamic data);

class ChatSocketProvider extends ChangeNotifier {
  late IO.Socket _socket;
  bool _connected = false;
  String _userId = '';
  String _token = '';
  Timer? _heartbeatTimer;
  int _retryCount = 0;
  final int _maxRetry = 5;

  final Map<String, List<SocketEventCallback>> _listeners = {};

  bool get isConnected => _connected;

  void connect(String token, String loginUserId) {
    _userId = loginUserId;
    _token = token;
    _socket = IO.io('http://10.9.17.94:8888', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });
    _socket.on('connect', (_) {
      _connected = true;
      _retryCount = 0;
      notifyListeners();
      joinUserRoom(_userId);
      _startHeartbeat();

      // ✅ 拉取离线消息
      _socket.emit('getOfflineMessages', {'userId': _userId});
    });

    _socket.on('disconnect', (_) {
      _connected = false;
      _stopHeartbeat();
      notifyListeners();
      _reconnectWithBackoff();
    });

    _socket.on('connect_error', (_) {
      _connected = false;
      _stopHeartbeat();
      notifyListeners();
      _reconnectWithBackoff();
    });

    // ✅ 监听新消息
    _socket.on('newMessage', (data) => _emitLocalEvent('newMessage', data));

    // ✅ 监听离线消息
    _socket.on(
      'offlineMessages',
      (data) => _emitLocalEvent('offlineMessages', data),
    );

    // ✅ 监听消息回执
    _socket.on('messageAck', (data) => _emitLocalEvent('messageAck', data));

    // ✅ 对方正在输入
    _socket.on('typing', (data) => _emitLocalEvent('typing', data));

    // ✅ 对方已读
    _socket.on('readMessage', (data) => _emitLocalEvent('readMessage', data));

    _socket.connect();
  }

  void disconnect() {
    _stopHeartbeat();
    _socket.disconnect();
    _connected = false;
    notifyListeners();
  }

  void _reconnectWithBackoff() {
    if (_retryCount >= _maxRetry) return;
    final delay = Duration(seconds: (2 << _retryCount));
    _retryCount++;

    Future.delayed(delay, () {
      if (!_connected) {
        connect(_token, _userId);
      }
    });
  }

  void leaveSessionRoom(String sessionId) {
    _socket.emit('leaveSession', {'sessionId': sessionId});
  }

  /// 监听新消息的回调注册
  void onNewMessage(Function(dynamic) callback) {
    _socket.on('newMessage', callback);
  }

  /// 监听好友申请的回调注册
  void onFriendRequest(Function(dynamic) callback) {
    _socket.on('friendRequest', callback);
  }

  /// 监听在线状态变化
  void onOnlineStatus(Function(dynamic) callback) {
    _socket.on('online', callback);
  }

  /// 加入自己的用户房间（用于接收通知/好友申请等）
  void joinUserRoom(String myUserId) {
    _socket.emit('joinUserRoom', {'userId': myUserId});
  }

  /// 发起聊天时，加入会话房间
  void joinSession(String sessionId) {
    _socket.emit('joinSession', {'sessionId': sessionId});
  }

  /// 发送聊天消息
  void sendMessage({
    required String sessionId,
    required String content,
    required String localId,
    String type = 'text',
  }) {
    _socket.emit('sendMessage', {
      'sessionId': sessionId,
      'content': content,
      'localId': localId,
      'type': type,
    });
  }

  /// ✅ 发送 "我正在输入中" 通知
  void sendTyping(String sessionId) {
    if (!_connected) return;
    _socket.emit('typing', {'sessionId': sessionId, 'userId': _userId});
  }

  /// ✅ 发送 "我已读消息" 通知
  void sendRead(String messageId, String sessionId) {
    if (!_connected) return;
    _socket.emit('readMessage', {
      'sessionId': sessionId,
      'messageId': messageId,
      'userId': _userId,
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_connected) {
        _socket.emit('ping', {'timestamp': Helper.timestamp()});
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void on(String event, SocketEventCallback callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event, SocketEventCallback callback) {
    _listeners[event]?.remove(callback);
  }

  void _emitLocalEvent(String event, dynamic data) {
    if (_listeners[event] != null) {
      for (final cb in _listeners[event]!) {
        cb(data);
      }
    }
  }
}
