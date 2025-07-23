import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocketProvider extends ChangeNotifier {
  late IO.Socket socket;
  bool _connected = false;
  String userId = '';

  bool get isConnected => _connected;

  void connect(String token, String myUserId) {
    if (_connected) return;
    userId = myUserId;
    socket = IO.io('http://10.9.17.94:8888', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });

    socket.on('connect', (_) {
      _connected = true;
      joinUserRoom(myUserId);
      notifyListeners();  // 连接状态变化通知 UI
    });

    socket.on('disconnect', (_) {
      _connected = false;
      notifyListeners();
    });

    socket.on('connect_error', (_) {
      _connected = false;
      notifyListeners();
    });

    // 监听新消息示例
    socket.on('newMessage', (data) {
      // 可以做状态存储或事件推送
      print('收到新消息: $data');
      // notifyListeners() 如果 UI 需要刷新消息列表
    });

    socket.connect();
  }

  void joinUserRoom(String myUserId) {
    socket.emit('joinUserRoom', {'userId': myUserId});
  }

  void sendMessage(String sessionId, String content, {String type = 'text'}) {
    socket.emit('sendMessage', {
      'sessionId': sessionId,
      'content': content,
      'type': type,
    });
  }

  void disconnect() {
    socket.disconnect();
    _connected = false;
    notifyListeners();
  }
}
