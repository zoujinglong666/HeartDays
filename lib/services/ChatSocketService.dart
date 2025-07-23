import 'package:heart_days/utils/ToastUtils.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  late IO.Socket socket;
  String userId = '';
  bool _connected = false;

  factory ChatSocketService() {
    return _instance;
  }
  bool get isConnected => socket.connected;
  ChatSocketService._internal();

  void connect(String token, String myUserId) {
    if (_connected) return;
    userId = myUserId;
    print('准备连接 WebSocket...');
    socket = IO.io('http://10.9.17.94:8888', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });

    socket.on('connect', (_) {
      print('WebSocket 连接成功，socket id: ${socket.id}');
      _connected = true;
      joinUserRoom(myUserId);
    });

    socket.on('disconnect', (_) {
      print('WebSocket 已断开');
      _connected = false;
    });

    socket.on('connect_error', (err) {
      print('WebSocket 连接错误: $err');
      _connected = false;
    });

    // 监听新消息
    socket.on('newMessage', (data) {
      print('收到新消息: $data');
      // TODO: 通知UI层刷新消息
    });

    // 监听好友申请
    socket.on('friendRequest', (data) {
      ToastUtils.showToast('收到好友申请: ${data['from']['nickname']}');
      // TODO: 通知UI层刷新好友请求
    });

    // 监听在线状态
    socket.on('online', (data) {
      print('用户在线状态变化: $data');
      // TODO: 通知UI层刷新在线状态
    });

    socket.connect();
  }

  /// 加入自己的用户房间（用于接收通知/好友申请等）
  void joinUserRoom(String myUserId) {
    socket.emit('joinUserRoom', {'userId': myUserId});
  }

  /// 发起聊天时，加入会话房间
  void joinSession(String sessionId) {
    socket.emit('joinSession', {'sessionId': sessionId});
  }

  /// 发送聊天消息
  void sendMessage({
    required String sessionId,
    required String content,
    String type = 'text',
  }) {
    socket.emit('sendMessage', {
     'sessionId': sessionId,
      'content': content,
      'type': type,
    });
  }

  /// 发送好友申请
  void sendFriendRequest(String targetUserId) {
    print('发送好友请求给用户: $targetUserId');
    socket.emit('friendRequest', {'to': targetUserId});
  }

  void disconnect() {
    print('手动断开 WebSocket 连接');
    socket.disconnect();
    _connected = false;
  }

  /// 可选：监听新消息的回调注册
  void onNewMessage(Function(dynamic) callback) {
    socket.on('newMessage', callback);
  }

  /// 可选：监听好友申请的回调注册
  void onFriendRequest(Function(dynamic) callback) {
    socket.on('friendRequest', callback);
  }

  /// 可选：监听在线状态变化
  void onOnlineStatus(Function(dynamic) callback) {
    socket.on('online', callback);
  }
}