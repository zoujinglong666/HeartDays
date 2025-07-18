import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocketService {
  late IO.Socket socket;

  void connect(String token) {
    print('准备连接 WebSocket...');
    print(token);
    socket = IO.io('http://10.9.17.94:8888', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });
    // sessionId 的含义
    // sessionId 就是会话ID，代表你要加入的聊天会话（单聊或群聊）。
    // 这个 ID 是你在后端创建会话（如建群、发起单聊）时生成的，通常是 UUID。
    // 前端拿到会话列表（/chat/session-list）后，每个会话对象里都有 sessionId 字段。
    socket.on('connect', (_) {
      print('WebSocket 连接成功，socket id: ${socket.id}');
      // 加入会话房间
      socket.emit('joinSession', {'sessionId': 'xxx'});
    });



    socket.on('reconnect', (attempt) {
      print('WebSocket 重连成功，尝试次数: $attempt');
    });

    socket.on('reconnecting', (attempt) {
      print('WebSocket 正在重连，尝试次数: $attempt');
    });
    socket.on('newMessage', (data) {
      print('收到新消息: $data');
    });
    socket.on('messageWithdrawn', (data) {
      print('有消息被撤回: $data');
    });
    socket.on('joined', (data) {
      print('已加入房间: $data');
    });

    socket.on('friendRequest', (data) {
      print('收到好友申请: $data');
      // data: { from: { id, nickname, avatar }, time }
      // 这里可以弹窗、更新新朋友列表等
    });
    // 连接
    socket.connect();
  }

  void sendMessage(String sessionId, String content, String senderId) {
    print('发送消息: sessionId=$sessionId, content=$content, senderId=$senderId');
    socket.emit('sendMessage', {
      'sessionId': sessionId,
      'content': content,
      'senderId': senderId,
      'type': 'text',
    });
  }

  void joinSession(String sessionId) {
    print('请求加入会话房间: $sessionId');
    socket.emit('joinSession', {'sessionId': sessionId});
  }

  void disconnect() {
    print('手动断开 WebSocket 连接');
    socket.disconnect();
  }
}
