import 'dart:async';

import 'package:heart_days/Consts/index.dart';
import 'package:heart_days/common/notification.dart';
import 'package:heart_days/common/toast.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocketService {
  IO.Socket? socket; // 改为可空类型，避免late初始化错误
  String userId = '';
  bool _connected = false;
  String? _currentToken; // 跟踪当前使用的 token
  String? _currentUserId; // 跟踪当前连接的用户ID

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

  static ChatSocketService? _singleton;

  // 2. 把原来的 _instance 改成可空静态变量
  static ChatSocketService get _instance =>
      _singleton ??= ChatSocketService._internal();

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  static const int _heartbeatInterval = 10 * 1000; // 10秒心跳
  static const int _reconnectInterval = 5; // 每5秒尝试重连
  bool _manuallyDisconnected = false; // 是否手动断开（避免手动断开还去重连）

  void connect(String token, String myUserId) async {
    // 检查是否需要切换用户
    if (_connected && _currentUserId != myUserId) {
      print('🔄 检测到用户切换，从 $_currentUserId 切换到 $myUserId');
      await switchUser(token, myUserId);
      return;
    }

    if (_connected && _currentUserId == myUserId) {
      print('⚠️ 同一用户的WebSocket已连接,请勿重连');
      return;
    }

    _manuallyDisconnected = false;
    userId = myUserId;
    _currentUserId = myUserId; // 记录当前用户ID

    // 获取最新的 token
    final prefs = await SharedPreferences.getInstance();
    final latestToken = prefs.getString('token') ?? token;
    _currentToken = latestToken; // 记录当前使用的 token
    print('🔑 用户 $myUserId 使用 token 连接: ${latestToken.substring(
        0, 20)}...');

    socket = IO.io(Consts.request.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer $latestToken'},
    });

    socket!.on('connect', (_) {
      print('✅ WebSocket 连接成功: ${socket!.id}');
      _connected = true;
      joinUserRoom(myUserId);
      _startHeartbeat();
      _stopReconnectTimer(); // 连接成功就停止重连计时
    });

    socket!.on('disconnect', (_) {
      print('❌ WebSocket 已断开');
      _connected = false;
      _stopHeartbeat();
      if (!_manuallyDisconnected) {
        _startReconnectTimer(token, myUserId);
      }
    });

    socket!.on('connect_error', (err) async {
      _connected = false;
      print('⚠️ 连接错误: $err');
      if (err.toString().contains('401') || err.toString().contains('jwt expired') || err.toString().contains('unauthorized')) {
        print('🔑 检测到认证错误，尝试使用最新 token 重连...');
        final prefs = await SharedPreferences.getInstance();
        final newToken = prefs.getString('token');
        if (newToken != null && newToken != token) {
          print('🔄 发现新 token，重新连接...');
          reconnectWithToken(newToken);
        } else {
          print('❌ 没有找到有效的新 token');
          if (!_manuallyDisconnected) {
            _startReconnectTimer(token, myUserId);
          }
        }
      } else {
        if (!_manuallyDisconnected) {
          _startReconnectTimer(token, myUserId);
        }
      }
    });

    // 注册业务事件
    _registerEventListeners();
    socket!.connect();
  }

  /// 定时重连
  void _startReconnectTimer(String token, String myUserId) {
    _stopReconnectTimer();
    _reconnectTimer = Timer.periodic(Duration(seconds: _reconnectInterval), (timer) async {
      if (!_connected) {
        print('⏳ 检测到未连接，尝试重连...');
        // 每次重连前都获取最新的 token
        final prefs = await SharedPreferences.getInstance();
        final latestToken = prefs.getString('token');
        connect(latestToken!, myUserId);
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

    // 检查socket是否已初始化再断开连接
    try {
      if (_connected && socket != null) {
        socket!.disconnect();
      }
    } catch (e) {
      print('⚠️ 断开连接时出错: $e');
    }

    _connected = false;
  }

  /// 切换用户（完全重置连接状态）
  Future<void> switchUser(String newToken, String newUserId) async {
    print('🔄 开始切换用户: $_currentUserId -> $newUserId');

    // 1. 离开当前用户房间（只有在连接且socket已初始化时才执行）
    if (_connected && _currentUserId != null && socket != null) {
      try {
        print('🚪 离开用户房间: $_currentUserId');
        socket!.emit('leaveUserRoom', {'userId': _currentUserId});
      } catch (e) {
        print('⚠️ 离开用户房间时出错: $e');
      }
    }

    // 2. 断开当前连接
    disconnect();

    // 3. 清理状态
    _clearUserState();

    // 4. 等待一下确保连接完全断开
    await Future.delayed(Duration(milliseconds: 500));

    // 5. 使用新用户信息重新连接
    print('🔄 使用新用户信息重新连接: $newUserId');
    connect(newToken, newUserId);
  }

  /// 清理用户状态
  void _clearUserState() {
    print('🧹 清理用户状态');
    userId = '';
    _currentUserId = null;
    _currentToken = null;
    _connected = false;
  }

  /// 完全重置服务（用于用户登出）
  void reset() {
    print('🔄 完全重置ChatSocketService');
    disconnect();
    _clearUserState();
    _stopHeartbeat();
    _stopReconnectTimer();
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
    if (socket == null) return;

    // 监听新消息
    socket!.on('newMessage', (data) async {
      final prefs = await SharedPreferences.getInstance();
      final latestToken = prefs.getString('token');
      if (latestToken!.isNotEmpty && data['senderId'] != userId) {
        final currentTime = DateFormat('HH:mm').format(DateTime.now());
        // MyToast.showNotification(
        //   title: "新消息 $currentTime",
        //   subtitle: data['content'],
        // );
        MyNotification.showNotification(
          title: "新消息 $currentTime",
          subtitle: data['content'],
        );

      }
      onNewMessage?.call(data);
    });

    // 监听好友申请
    socket!.on('friendRequest', (data) {
      ToastUtils.showToast('收到好友申请: ${data['from']['nickname']}');
      onFriendRequest?.call(data);
    });

    // 监听在线状态
    socket!.on('online', (data) {
      print('用户在线状态变化: $data');
      onOnlineStatus?.call(data);
    });

    // 监听用户状态
    socket!.on('userStatus', (data) {
      onUserStatus?.call(data);
    });

    // 监听好友在线状态变化
    socket!.on('friendStatus', (data) {
      onFriendStatus?.call(data);
    });

    // 监听他人输入状态
    socket!.on('typing', (data) {
      print('用户 ${data['userId']} 正在输入');
      onTyping?.call(data);
    });

    // 监听他人停止输入
    socket!.on('stopTyping', (data) {
      print('用户 ${data['userId']} 停止输入');
      onStopTyping?.call(data);
    });

    // 监听离线消息
    socket!.on('offlineMessages', (data) {
      onOfflineMessages?.call(data);
    });

    // 监听消息已读确认
    socket!.on('messageReadConfirm', (data) {
      print('消息已读确认: ${data['messageId']}');
      onMessageReadConfirm?.call(data);
    });

    // 监听他人消息已读
    socket!.on('readMessage', (data) {
      print('用户 ${data['userId']} 已读消息: ${data['messageId']}');
      onMessageRead?.call(data);
    });

    // 监听撤回确认
    socket!.on('messageWithdrawnConfirm', (data) {
      print('消息已撤回: ${data['messageId']}');
      onMessageWithdrawnConfirm?.call(data);
    });

    // 监听他人撤回消息
    socket!.on('messageWithdrawn', (data) {
      print('用户 ${data['userId']} 撤回了消息: ${data['messageId']}');
      onMessageWithdrawn?.call(data);
    });

    // 监听消息送达确认
    socket!.on('messageDelivered', (data) {
      print('消息已送达用户: ${data['messageId']}');
      onMessageDelivered?.call(data);
    });

    // 监听消息发送确认
    socket!.on('messageSent', (data) {
      print('消息已发送，服务器ID: ${data['messageId']}');
      onMessageSent?.call(data);
    });

    // 监听消息确认
    socket!.on('messageAck', (data) {
      onMessageAck?.call(data);
    });

    // 监听消息确认回复
    socket!.on('messageAckConfirm', (data) {
      onMessageAckConfirm?.call(data);
    });

    // 检查用户状态
    socket!.on('checkUserStatus', (data) {
      onCheckUserStatus?.call(data);
    });


  }
  void reconnectWithToken(String token) async {
    print('🔄 使用新 token 重新连接: ${token.substring(0, 20)}...');
    _currentToken = token; // 更新当前 token
    disconnect(); // 断开当前连接
    await Future.delayed(Duration(seconds: 1));
    connect(token, userId); // 使用新 token 重新连接
  }

  /// 安全的用户切换方法（推荐使用）
  Future<void> safeUserSwitch(String newToken, String newUserId) async {
    print('🛡️ 安全切换用户: $_currentUserId -> $newUserId');

    if (_currentUserId == newUserId && _currentToken == newToken) {
      print('✅ 用户和token都相同，无需切换');
      return;
    }

    // 更新SharedPreferences中的token
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', newToken);

    // 执行用户切换
    await switchUser(newToken, newUserId);
  }

  /// 主动刷新连接（当检测到 token 更新时调用）
  void refreshConnection() async {
    final prefs = await SharedPreferences.getInstance();
    final newToken = prefs.getString('token');

    if (newToken == null) {
      print('⚠️ 没有找到新 token');
      return;
    }

    // 比较当前使用的 token 和存储的 token
    if (_currentToken == newToken) {
      print('🔍 Token 未变化，无需刷新连接');
      return;
    }

    print('🔄 检测到新 token，刷新连接...');
    print('🔄 旧 token: ${_currentToken?.substring(0, 20) ?? 'null'}...');
    print('🔄 新 token: ${newToken.substring(0, 20)}...');

    if (_connected) {
      reconnectWithToken(newToken);
    } else {
      // 如果当前未连接，直接使用新 token 连接
      print('🔄 当前未连接，使用新 token 直接连接');
      connect(newToken, userId);
    }
  }

  /// 检查并更新 token（可以在 HTTP 请求成功后调用）
  void checkAndUpdateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token');

    if (storedToken == null) {
      print('⚠️ 存储中没有 token');
      return;
    }

    if (_currentToken != storedToken) {
      print('🔍 检测到 token 已更新');
      print('🔍 当前使用: ${_currentToken?.substring(0, 20) ?? 'null'}...');
      print('🔍 存储中的: ${storedToken.substring(0, 20)}...');
      refreshConnection();
    } else {
      print('🔍 Token 状态正常，无需更新');
    }
  }

  /// 获取当前使用的 token
  String? get currentToken => _currentToken;

  /// 获取当前连接的用户ID
  String? get currentUserId => _currentUserId;

  /// 检查是否为当前用户
  bool isCurrentUser(String userId) {
    return _currentUserId == userId;
  }

  /// 强制使用最新 token 重连（用于调试）
  void forceReconnectWithLatestToken() async {
    final prefs = await SharedPreferences.getInstance();
    final latestToken = prefs.getString('token');
    if (latestToken != null) {
      print('🔧 强制使用最新 token 重连');
      reconnectWithToken(latestToken);
    } else {
      print('⚠️ 没有找到最新 token');
    }
  }
  /// 加入自己的用户房间（用于接收通知/好友申请等）
  void joinUserRoom(String myUserId) {
    if (socket != null && _connected) {
      socket!.emit('joinUserRoom', {'userId': myUserId});
    }
  }

  /// 发起聊天时，加入会话房间
  void joinSession(String sessionId) {
    if (socket != null && _connected) {
      socket!.emit('joinSession', {'sessionId': sessionId});
    }
  }

  /// 发送聊天消息
  void sendMessage({
    required String sessionId,
    required String content,
    required String localId,
    String type = 'text',
  }) {
    if (socket != null && _connected) {
      socket!.emit('sendMessage', {
        'sessionId': sessionId,
        'content': content,
        'localId': localId,
        'type': type,
      });
    }
  }

  /// 发送好友申请
  void sendFriendRequest(String targetUserId) {
    print('发送好友请求给用户: $targetUserId');
    if (socket != null && _connected) {
      socket!.emit('friendRequest', {'to': targetUserId});
    }
  }

  /// 检查用户在线状态
  void checkUserStatus(List<String> userIds) {
    if (socket != null && _connected) {
      socket!.emit('checkUserStatus', {'userIds': userIds});
    }
  }

  /// 发送正在输入状态
  void sendTyping(String sessionId) {
    if (socket != null && _connected) {
      socket!.emit('typing', {'sessionId': sessionId});
    }
  }

  /// 发送停止输入状态
  void sendStopTyping(String sessionId) {
    if (socket != null && _connected) {
      socket!.emit('stopTyping', {'sessionId': sessionId});
    }
  }

  /// 获取离线消息
  void getOfflineMessages([String? lastMessageTime]) {
    if (socket != null && _connected) {
      var data = <String, dynamic>{};
      if (lastMessageTime != null) {
        data['lastMessageTime'] = lastMessageTime;
      }
      print("获取离线消息");
      socket!.emit('getOfflineMessages', data);
    }
  }

  /// 发送消息已读确认
  void sendReadMessage({
    required String messageId,
    required String sessionId,
  }) {
    if (socket != null && _connected) {
      socket!.emit('readMessage', {
        'messageId': messageId,
        'sessionId': sessionId,
      });
    }
  }

  /// 撤回消息
  void withdrawMessage({
    required String messageId,
    required String sessionId,
  }) {
    if (socket != null && _connected) {
      socket!.emit('withdrawMessage', {
        'messageId': messageId,
        'sessionId': sessionId,
      });
    }
  }

  /// 发送消息确认
  void sendMessageAck({
    required String messageId,
    required String sessionId,
    required String localId,
  }) {
    if (socket != null && _connected) {
      socket!.emit('messageAck', {
        'messageId': messageId,
        'sessionId': sessionId,
        'localId': localId,
      });
    }
  }

  /// 发送心跳包
  void sendPing(int timestamp) {
    if (socket != null && _connected) {
      socket!.emit('ping', {'timestamp': timestamp});
    }
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


  // 1. 在类末尾新增销毁方法
  Future<void> destroy() async {
    reset(); // 内部已做 disconnect + 清状态
    _instance._clean(); // 把自身字段全置空，防止内存泄漏
    _singleton = null; // 关键：让单例失效，下次重新创建
  }



  // 3. 内部清理辅助
  void _clean() {
    socket = null;
    _currentToken = null;
    _currentUserId = null;
    userId = '';
    _connected = false;
    // 所有回调置空
    onNewMessage = null;
    onFriendRequest = null;
    onOnlineStatus = null;
    onUserStatus = null;
    onFriendStatus = null;
    onTyping = null;
    onStopTyping = null;
    onOfflineMessages = null;
    onMessageRead = null;
    onMessageReadConfirm = null;
    onMessageWithdrawn = null;
    onMessageWithdrawnConfirm = null;
    onMessageDelivered = null;
    onMessageSent = null;
    onMessageAck = null;
    onMessageAckConfirm = null;
    _friendStatusListeners.clear();
  }

}