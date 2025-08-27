import 'dart:async';

import 'package:heart_days/Consts/index.dart';
import 'package:heart_days/common/toast.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocketService {
  static final ChatSocketService _instance = ChatSocketService._internal();
  late IO.Socket socket;
  String userId = '';
  bool _connected = false;

  // 回调函数
  Function(dynamic)? onNewMessage;
  Function(dynamic)? onFriendRequest;
  Function(dynamic)? onOnlineStatus;
  Function(dynamic)? onUserStatus;
  Function(dynamic)? onFriendStatus;
  Function(dynamic)? onTyping;
  Function(dynamic)? onStopTyping;
  Function(dynamic)? onOfflineMessages;
  Function(dynamic)? onMessageRead;
  Function(dynamic)? onMessageReadConfirm;
  Function(dynamic)? onMessageWithdrawn;
  Function(dynamic)? onMessageWithdrawnConfirm;
  Function(dynamic)? onMessageDelivered;
  Function(dynamic)? onMessageSent;
  Function(dynamic)? onMessageAck;
  Function(dynamic)? onMessageAckConfirm;
  Function(dynamic)? onCheckUserStatus;

  factory ChatSocketService() {
    return _instance;
  }
  bool get isConnected => _connected;
  ChatSocketService._internal();

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  static const int _heartbeatInterval = 10 * 1000; // 10秒心跳
  static const int _reconnectInterval = 5; // 每5秒尝试重连
  bool _manuallyDisconnected = false; // 是否手动断开（避免手动断开还去重连）

  void connect(String token, String myUserId) {
    if (_connected) {
      print('⚠️ WebSocket 已连接,请勿重连');
      return;
    }
    _manuallyDisconnected = false;
    userId = myUserId;
    socket = IO.io(Consts.request.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $token'},
    });

    socket.on('connect', (_) {
      print('✅ WebSocket 连接成功: ${socket.id}');
      _connected = true;
      joinUserRoom(myUserId);
      _startHeartbeat();
      _stopReconnectTimer(); // 连接成功就停止重连计时
    });

    socket.on('disconnect', (_) {
      print('❌ WebSocket 已断开');
      _connected = false;
      _stopHeartbeat();
      if (!_manuallyDisconnected) {
        _startReconnectTimer(token, myUserId);
      }
    });

    socket.on('connect_error', (err) async {
      _connected = false;
      print('⚠️ 连接错误: $err');
      if (err.toString().contains('401') || err.toString().contains('jwt expired')) {
        final prefs = await SharedPreferences.getInstance();
        final newToken = prefs.getString('token');
        if (newToken != null) {
          print('🔄 token 刷新后重连...');
          reconnectWithToken(newToken);
        }
      } else {
        if (!_manuallyDisconnected) {
          _startReconnectTimer(token, myUserId);
        }
      }
    });

    // 注册业务事件
    _registerEventListeners();
    socket.connect();
  }

  /// 定时重连
  void _startReconnectTimer(String token, String myUserId) {
    _stopReconnectTimer();
    _reconnectTimer = Timer.periodic(Duration(seconds: _reconnectInterval), (timer) {
      if (!_connected) {
        print('⏳ 检测到未连接，尝试重连...');
        connect(token, myUserId);
      }
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 手动断开
  void disconnect() {
    print('🔌 手动断开连接');
    _manuallyDisconnected = true;
    _stopHeartbeat();
    _stopReconnectTimer();
    socket.disconnect();
    _connected = false;
  }

  /// 心跳
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(Duration(milliseconds: _heartbeatInterval), (timer) {
      if (_connected) {
        sendPing(DateTime.now().millisecondsSinceEpoch);
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _registerEventListeners() {
    // 监听新消息
    socket.on('newMessage', (data) {
      if (data['senderId'] != userId) {
        final currentTime = DateFormat('HH:mm').format(DateTime.now());
        MyToast.showNotification(
          title: "新消息 $currentTime",
          subtitle: data['content'],
        );
      }
      onNewMessage?.call(data);
    });

    // 监听好友申请
    socket.on('friendRequest', (data) {
      ToastUtils.showToast('收到好友申请: ${data['from']['nickname']}');
      onFriendRequest?.call(data);
    });

    // 监听在线状态
    socket.on('online', (data) {
      print('用户在线状态变化: $data');
      onOnlineStatus?.call(data);
    });

    // 监听用户状态
    socket.on('userStatus', (data) {
      onUserStatus?.call(data);
    });

    // 监听好友在线状态变化
    socket.on('friendStatus', (data) {
      onFriendStatus?.call(data);
    });

    // 监听他人输入状态
    socket.on('typing', (data) {
      print('用户 ${data['userId']} 正在输入');
      onTyping?.call(data);
    });

    // 监听他人停止输入
    socket.on('stopTyping', (data) {
      print('用户 ${data['userId']} 停止输入');
      onStopTyping?.call(data);
    });

    // 监听离线消息
    socket.on('offlineMessages', (data) {
      onOfflineMessages?.call(data);
    });

    // 监听消息已读确认
    socket.on('messageReadConfirm', (data) {
      print('消息已读确认: ${data['messageId']}');
      onMessageReadConfirm?.call(data);
    });

    // 监听他人消息已读
    socket.on('readMessage', (data) {
      print('用户 ${data['userId']} 已读消息: ${data['messageId']}');
      onMessageRead?.call(data);
    });

    // 监听撤回确认
    socket.on('messageWithdrawnConfirm', (data) {
      print('消息已撤回: ${data['messageId']}');
      onMessageWithdrawnConfirm?.call(data);
    });

    // 监听他人撤回消息
    socket.on('messageWithdrawn', (data) {
      print('用户 ${data['userId']} 撤回了消息: ${data['messageId']}');
      onMessageWithdrawn?.call(data);
    });

    // 监听消息送达确认
    socket.on('messageDelivered', (data) {
      print('消息已送达用户: ${data['messageId']}');
      onMessageDelivered?.call(data);
    });

    // 监听消息发送确认
    socket.on('messageSent', (data) {
      print('消息已发送，服务器ID: ${data['messageId']}');
      onMessageSent?.call(data);
    });

    // 监听消息确认
    socket.on('messageAck', (data) {
      onMessageAck?.call(data);
    });

    // 监听消息确认回复
    socket.on('messageAckConfirm', (data) {
      onMessageAckConfirm?.call(data);
    });

    // 检查用户状态
    socket.on('checkUserStatus', (data) {
      onCheckUserStatus?.call(data);
    });


  }
  void reconnectWithToken(String token) async {
    disconnect(); // 断开当前连接
    await Future.delayed(Duration(seconds: 1));
    connect(token, userId); // 使用新 token 重新连接
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
    required String localId,
    String type = 'text',
  }) {
    socket.emit('sendMessage', {
      'sessionId': sessionId,
      'content': content,
      'localId': localId,
      'type': type,
    });
  }

  /// 发送好友申请
  void sendFriendRequest(String targetUserId) {
    print('发送好友请求给用户: $targetUserId');
    socket.emit('friendRequest', {'to': targetUserId});
  }

  /// 检查用户在线状态
  void checkUserStatus(List<String> userIds) {
    socket.emit('checkUserStatus', {'userIds': userIds});
  }

  /// 发送正在输入状态
  void sendTyping(String sessionId) {
    socket.emit('typing', {'sessionId': sessionId});
  }

  /// 发送停止输入状态
  void sendStopTyping(String sessionId) {
    socket.emit('stopTyping', {'sessionId': sessionId});
  }

  /// 获取离线消息
  void getOfflineMessages([String? lastMessageTime]) {
    var data = <String, dynamic>{};
    if (lastMessageTime != null) {
      data['lastMessageTime'] = lastMessageTime;
    }
    print("获取离线消息");
    socket.emit('getOfflineMessages', data);
  }

  /// 发送消息已读确认
  void sendReadMessage({
    required String messageId,
    required String sessionId,
  }) {
    socket.emit('readMessage', {
      'messageId': messageId,
      'sessionId': sessionId,
    });
  }

  /// 撤回消息
  void withdrawMessage({
    required String messageId,
    required String sessionId,
  }) {
    socket.emit('withdrawMessage', {
      'messageId': messageId,
      'sessionId': sessionId,
    });
  }

  /// 发送消息确认
  void sendMessageAck({
    required String messageId,
    required String sessionId,
    required String localId,
  }) {
    socket.emit('messageAck', {
      'messageId': messageId,
      'sessionId': sessionId,
      'localId': localId,
    });
  }

  /// 发送心跳包
  void sendPing(int timestamp) {
    socket.emit('ping', {'timestamp': timestamp});
  }







  /// 设置新消息回调
  void setOnNewMessage(Function(dynamic) callback) {
    onNewMessage = callback;
  }

  /// 设置好友请求回调
  void setOnFriendRequest(Function(dynamic) callback) {
    onFriendRequest = callback;
  }

  /// 设置在线状态回调
  void setOnOnlineStatus(Function(dynamic) callback) {
    onOnlineStatus = callback;
  }

  /// 设置用户状态回调
  void setOnUserStatus(Function(dynamic) callback) {
    onUserStatus = callback;
  }

  /// 设置好友状态回调
  void setOnFriendStatus(Function(dynamic) callback) {
    onFriendStatus = callback;
  }

  /// 设置正在输入回调
  void setOnTyping(Function(dynamic) callback) {
    onTyping = callback;
  }

  /// 设置停止输入回调
  void setOnStopTyping(Function(dynamic) callback) {
    onStopTyping = callback;
  }

  /// 设置离线消息回调
  void setOnOfflineMessages(Function(dynamic) callback) {
    onOfflineMessages = callback;
  }

  /// 设置消息已读回调
  void setOnMessageRead(Function(dynamic) callback) {
    onMessageRead = callback;
  }

  /// 设置消息已读确认回调
  void setOnMessageReadConfirm(Function(dynamic) callback) {
    onMessageReadConfirm = callback;
  }

  /// 设置消息撤回回调
  void setOnMessageWithdrawn(Function(dynamic) callback) {
    onMessageWithdrawn = callback;
  }

  /// 设置消息撤回确认回调
  void setOnMessageWithdrawnConfirm(Function(dynamic) callback) {
    onMessageWithdrawnConfirm = callback;
  }

  /// 设置消息送达回调
  void setOnMessageDelivered(Function(dynamic) callback) {
    onMessageDelivered = callback;
  }

  /// 设置消息发送回调
  void setOnMessageSent(Function(dynamic) callback) {
    onMessageSent = callback;
  }

  /// 设置消息确认回调
  void setOnMessageAck(Function(dynamic) callback) {
    onMessageAck = callback;
  }

  /// 设置消息确认回复回调
  void setOnMessageAckConfirm(Function(dynamic) callback) {
    onMessageAckConfirm = callback;
  }


  final List<void Function(dynamic)> _friendStatusListeners = [];

  void addFriendStatusListener(void Function(dynamic) listener) {
    if (!_friendStatusListeners.contains(listener)) {
      _friendStatusListeners.add(listener);
    }
  }

  void removeFriendStatusListener(void Function(dynamic) listener) {
    _friendStatusListeners.remove(listener);
  }

}