import 'dart:async';
import 'dart:math';

import 'package:heart_days/Consts/index.dart';
import 'package:heart_days/common/notification.dart';
import 'package:heart_days/common/toast.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatSocketService {
  IO.Socket? socket;
  String userId = '';
  bool _connected = false;
  String? _currentToken;
  String? _currentUserId;
  
  // 连接状态管理
  ConnectionState _connectionState = ConnectionState.disconnected;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _baseReconnectDelay = 1000; // 1秒基础延迟
  
  // 性能优化
  final Map<String, DateTime> _lastEventTime = {};
  static const int _eventThrottleMs = 100; // 事件节流100ms

  // 回调函数映射，便于管理
  final Map<String, Function(dynamic)?> _callbacks = {
    'newMessage': null,
    'friendRequest': null,
    'onlineStatus': null,
    'userStatus': null,
    'friendStatus': null,
    'typing': null,
    'stopTyping': null,
    'offlineMessages': null,
    'messageRead': null,
    'messageReadConfirm': null,
    'messageWithdrawn': null,
    'messageWithdrawnConfirm': null,
    'messageDelivered': null,
    'messageSent': null,
    'messageAck': null,
    'messageAckConfirm': null,
    'checkUserStatus': null,
  };

  // 兼容性getter
  Function(dynamic)? get onNewMessage => _callbacks['newMessage'];
  Function(dynamic)? get onFriendRequest => _callbacks['friendRequest'];
  Function(dynamic)? get onOnlineStatus => _callbacks['onlineStatus'];
  Function(dynamic)? get onUserStatus => _callbacks['userStatus'];
  Function(dynamic)? get onFriendStatus => _callbacks['friendStatus'];
  Function(dynamic)? get onTyping => _callbacks['typing'];
  Function(dynamic)? get onStopTyping => _callbacks['stopTyping'];
  Function(dynamic)? get onOfflineMessages => _callbacks['offlineMessages'];
  Function(dynamic)? get onMessageRead => _callbacks['messageRead'];
  Function(dynamic)? get onMessageReadConfirm => _callbacks['messageReadConfirm'];
  Function(dynamic)? get onMessageWithdrawn => _callbacks['messageWithdrawn'];
  Function(dynamic)? get onMessageWithdrawnConfirm => _callbacks['messageWithdrawnConfirm'];
  Function(dynamic)? get onMessageDelivered => _callbacks['messageDelivered'];
  Function(dynamic)? get onMessageSent => _callbacks['messageSent'];
  Function(dynamic)? get onMessageAck => _callbacks['messageAck'];
  Function(dynamic)? get onMessageAckConfirm => _callbacks['messageAckConfirm'];
  Function(dynamic)? get onCheckUserStatus => _callbacks['checkUserStatus'];

  factory ChatSocketService() {
    return _instance;
  }
  
  bool get isConnected => _connected && _connectionState == ConnectionState.connected;
  ConnectionState get connectionState => _connectionState;
  int get reconnectAttempts => _reconnectAttempts;
  
  ChatSocketService._internal();

  static ChatSocketService? _singleton;
  static ChatSocketService get _instance =>
      _singleton ??= ChatSocketService._internal();

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  static const int _heartbeatInterval = 15 * 1000; // 15秒心跳，减少频率
  bool _manuallyDisconnected = false;

  Future<void> connect(String token, String myUserId) async {
    try {
      // 检查是否已经连接且为同一用户
      if (_connected && _currentUserId == myUserId && _currentToken == token) {
        print('✅ 同一用户的WebSocket已连接，无需重连');
        return;
      }

      // 如果连接中但用户不同，需要切换用户
      if (_connected && _currentUserId != myUserId) {
        print('🔄 检测到用户切换，从 $_currentUserId 切换到 $myUserId');
        await switchUser(token, myUserId);
        return;
      }

      // 如果正在连接中，避免重复连接
      if (_connectionState == ConnectionState.connecting) {
        print('⏳ 正在连接中，跳过重复连接请求');
        return;
      }

      _setConnectionState(ConnectionState.connecting);
      _manuallyDisconnected = false;
      userId = myUserId;
      _currentUserId = myUserId;

      // 获取最新token
      final prefs = await SharedPreferences.getInstance();
      final latestToken = prefs.getString('token') ?? token;
      _currentToken = latestToken;
      
      print('🔑 用户 $myUserId 开始连接: ${latestToken.substring(0, min(20, latestToken.length))}...');

      // 创建Socket连接
      socket = IO.io(Consts.request.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'timeout': 10000, // 10秒超时
        'extraHeaders': {'Authorization': 'Bearer $latestToken'},
        'forceNew': true, // 强制创建新连接
      });

      _setupSocketEventHandlers(latestToken, myUserId);
      _registerEventListeners();
      
      socket!.connect();
      
    } catch (e) {
      print('❌ 连接初始化失败: $e');
      _setConnectionState(ConnectionState.error);
      _scheduleReconnect(token, myUserId);
    }
  }
  
  void _setupSocketEventHandlers(String token, String userId) {
    socket!.on('connect', (_) {
      print('✅ WebSocket 连接成功: ${socket!.id}');
      _connected = true;
      _setConnectionState(ConnectionState.connected);
      _reconnectAttempts = 0; // 重置重连计数
      
      joinUserRoom(userId);
      _startHeartbeat();
      _stopReconnectTimer();
    });

    socket!.on('disconnect', (reason) {
      print('❌ WebSocket 断开连接: $reason');
      _connected = false;
      _setConnectionState(ConnectionState.disconnected);
      _stopHeartbeat();
      
      if (!_manuallyDisconnected) {
        _scheduleReconnect(token, userId);
      }
    });

    socket!.on('connect_error', (err) async {
      print('⚠️ 连接错误: $err');
      _connected = false;
      _setConnectionState(ConnectionState.error);
      
      // 处理认证错误
      if (_isAuthError(err)) {
        await _handleAuthError(token, userId);
      } else if (!_manuallyDisconnected) {
        _scheduleReconnect(token, userId);
      }
    });

    socket!.on('reconnect', (attemptNumber) {
      print('🔄 重连成功，尝试次数: $attemptNumber');
      _reconnectAttempts = 0;
    });

    socket!.on('reconnect_error', (err) {
      print('❌ 重连失败: $err');
      _reconnectAttempts++;
    });
  }
  
  bool _isAuthError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('401') || 
           errorStr.contains('jwt expired') || 
           errorStr.contains('unauthorized') ||
           errorStr.contains('authentication');
  }
  
  Future<void> _handleAuthError(String token, String userId) async {
    print('🔑 处理认证错误，尝试刷新token...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final newToken = prefs.getString('token');
      
      if (newToken != null && newToken != token) {
        print('🔄 发现新token，重新连接...');
        await Future.delayed(const Duration(milliseconds: 500));
        reconnectWithToken(newToken);
      } else {
        print('❌ 没有找到有效的新token');
        _setConnectionState(ConnectionState.authError);
        if (!_manuallyDisconnected) {
          _scheduleReconnect(token, userId);
        }
      }
    } catch (e) {
      print('❌ 处理认证错误失败: $e');
      _scheduleReconnect(token, userId);
    }
  }
  
  void _setConnectionState(ConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      print('🔄 连接状态变更: ${state.name}');
    }
  }

  /// 智能重连调度
  void _scheduleReconnect(String token, String userId) {
    if (_manuallyDisconnected || _reconnectAttempts >= _maxReconnectAttempts) {
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        print('❌ 达到最大重连次数，停止重连');
        _setConnectionState(ConnectionState.failed);
      }
      return;
    }

    _stopReconnectTimer();
    _reconnectAttempts++;
    
    // 指数退避算法：延迟时间 = 基础延迟 * 2^(重连次数-1)，最大30秒
    final delay = min(_baseReconnectDelay * pow(2, _reconnectAttempts - 1).toInt(), 30000);
    
    print('⏳ 第 $_reconnectAttempts 次重连将在 ${delay}ms 后开始...');
    _setConnectionState(ConnectionState.reconnecting);
    
    _reconnectTimer = Timer(Duration(milliseconds: delay), () async {
      if (!_manuallyDisconnected && !_connected) {
        print('🔄 开始第 $_reconnectAttempts 次重连...');
        
        // 每次重连前获取最新token
        try {
          final prefs = await SharedPreferences.getInstance();
          final latestToken = prefs.getString('token') ?? token;
          await connect(latestToken, userId);
        } catch (e) {
          print('❌ 重连失败: $e');
          _scheduleReconnect(token, userId);
        }
      }
    });
  }

  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// 手动断开连接
  void disconnect() {
    print('🔌 手动断开连接');
    _manuallyDisconnected = true;
    _stopHeartbeat();
    _stopReconnectTimer();

    try {
      if (socket != null) {
        // 清理所有事件监听器
        socket!.clearListeners();
        
        if (_connected) {
          socket!.disconnect();
        }
        socket!.dispose();
        socket = null;
      }
    } catch (e) {
      print('⚠️ 断开连接时出错: $e');
    }

    _connected = false;
    _setConnectionState(ConnectionState.disconnected);
    _reconnectAttempts = 0;
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

    // 事件映射，便于统一管理
    final eventMap = {
      'newMessage': (data) => _handleNewMessage(data),
      'friendRequest': (data) => _handleFriendRequest(data),
      'online': (data) => _handleOnlineStatus(data),
      'userStatus': (data) => _handleUserStatus(data),
      'friendStatus': (data) => _handleFriendStatus(data),
      'typing': (data) => _handleTyping(data),
      'stopTyping': (data) => _handleStopTyping(data),
      'offlineMessages': (data) => _handleOfflineMessages(data),
      'messageReadConfirm': (data) => _handleMessageReadConfirm(data),
      'readMessage': (data) => _handleMessageRead(data),
      'messageWithdrawnConfirm': (data) => _handleMessageWithdrawnConfirm(data),
      'messageWithdrawn': (data) => _handleMessageWithdrawn(data),
      'messageDelivered': (data) => _handleMessageDelivered(data),
      'messageSent': (data) => _handleMessageSent(data),
      'messageAck': (data) => _handleMessageAck(data),
      'messageAckConfirm': (data) => _handleMessageAckConfirm(data),
      'checkUserStatus': (data) => _handleCheckUserStatus(data),
    };

    // 批量注册事件监听器
    eventMap.forEach((event, handler) {
      socket!.on(event, (data) => _throttledEventHandler(event, data, handler));
    });
  }
  
  /// 事件节流处理，防止频繁触发
  void _throttledEventHandler(String eventName, dynamic data, Function handler) {
    final now = DateTime.now();
    final lastTime = _lastEventTime[eventName];
    
    if (lastTime == null || now.difference(lastTime).inMilliseconds > _eventThrottleMs) {
      _lastEventTime[eventName] = now;
      try {
        handler(data);
      } catch (e) {
        print('❌ 处理事件 $eventName 时出错: $e');
      }
    }
  }

  // 各种事件处理方法
  void _handleNewMessage(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latestToken = prefs.getString('token');
      
      if (latestToken?.isNotEmpty == true && data['senderId'] != userId) {
        final currentTime = DateFormat('HH:mm').format(DateTime.now());
        MyNotification.showNotification(
          title: "新消息 $currentTime",
          subtitle: data['content'] ?? '收到新消息',
        );
      }
      
      _callbacks['newMessage']?.call(data);
    } catch (e) {
      print('❌ 处理新消息时出错: $e');
    }
  }

  void _handleFriendRequest(dynamic data) {
    try {
      final nickname = data['from']?['nickname'] ?? '未知用户';
      ToastUtils.showToast('收到好友申请: $nickname');
      _callbacks['friendRequest']?.call(data);
    } catch (e) {
      print('❌ 处理好友请求时出错: $e');
    }
  }

  void _handleOnlineStatus(dynamic data) {
    print('用户在线状态变化: $data');
    _callbacks['onlineStatus']?.call(data);
  }

  void _handleUserStatus(dynamic data) {
    _callbacks['userStatus']?.call(data);
  }

  void _handleFriendStatus(dynamic data) {
    _callbacks['friendStatus']?.call(data);
    // 通知所有监听器
    for (final listener in _friendStatusListeners) {
      try {
        listener(data);
      } catch (e) {
        print('❌ 好友状态监听器出错: $e');
      }
    }
  }

  void _handleTyping(dynamic data) {
    print('用户 ${data['userId']} 正在输入');
    _callbacks['typing']?.call(data);
  }

  void _handleStopTyping(dynamic data) {
    print('用户 ${data['userId']} 停止输入');
    _callbacks['stopTyping']?.call(data);
  }

  void _handleOfflineMessages(dynamic data) {
    _callbacks['offlineMessages']?.call(data);
  }

  void _handleMessageReadConfirm(dynamic data) {
    print('消息已读确认: ${data['messageId']}');
    _callbacks['messageReadConfirm']?.call(data);
  }

  void _handleMessageRead(dynamic data) {
    print('用户 ${data['userId']} 已读消息: ${data['messageId']}');
    _callbacks['messageRead']?.call(data);
  }

  void _handleMessageWithdrawnConfirm(dynamic data) {
    print('消息已撤回: ${data['messageId']}');
    _callbacks['messageWithdrawnConfirm']?.call(data);
  }

  void _handleMessageWithdrawn(dynamic data) {
    print('用户 ${data['userId']} 撤回了消息: ${data['messageId']}');
    _callbacks['messageWithdrawn']?.call(data);
  }

  void _handleMessageDelivered(dynamic data) {
    print('消息已送达用户: ${data['messageId']}');
    _callbacks['messageDelivered']?.call(data);
  }

  void _handleMessageSent(dynamic data) {
    print('消息已发送，服务器ID: ${data['messageId']}');
    _callbacks['messageSent']?.call(data);
  }

  void _handleMessageAck(dynamic data) {
    _callbacks['messageAck']?.call(data);
  }

  void _handleMessageAckConfirm(dynamic data) {
    _callbacks['messageAckConfirm']?.call(data);
  }

  void _handleCheckUserStatus(dynamic data) {
    _callbacks['checkUserStatus']?.call(data);
  }
  Future<void> reconnectWithToken(String token) async {
    print('🔄 使用新 token 重新连接: ${token.substring(0, 20)}...');
    _currentToken = token; // 更新当前 token
    disconnect(); // 断开当前连接
    await Future.delayed(Duration(seconds: 1));
    connect(token, userId); // 使用新 token 重新连接
  }

  /// 安全的用户切换方法（推荐使用）
  Future<void> safeUserSwitch(String newToken, String newUserId) async {
    print('🛡️ 安全切换用户: $_currentUserId -> $newUserId');

    // 检查是否为完全相同的用户和token
    if (_currentUserId == newUserId && _currentToken == newToken && _connected) {
      print('✅ 用户、token和连接状态都相同，无需切换');
      return;
    }

    // 如果是同一用户但token不同，只需要更新token并重连
    if (_currentUserId == newUserId && _currentToken != newToken) {
      print('🔄 同一用户token更新，重新连接');
      _currentToken = newToken;
      await reconnectWithToken(newToken);
      return;
    }

    // 不同用户，执行完整的用户切换
    if (_currentUserId != newUserId) {
      print('🔄 切换到不同用户，执行完整切换');
      await switchUser(newToken, newUserId);
      return;
    }

    // 其他情况，直接连接
    print('🔄 执行连接');
    await connect(newToken, newUserId);
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


  /// 统一的回调设置方法
  void setCallback(String eventName, Function(dynamic)? callback) {
    if (_callbacks.containsKey(eventName)) {
      _callbacks[eventName] = callback;
    } else {
      print('⚠️ 未知的事件类型: $eventName');
    }
  }

  /// 兼容性方法 - 设置新消息回调
  void setOnNewMessage(Function(dynamic) callback) {
    _callbacks['newMessage'] = callback;
  }

  /// 设置好友请求回调
  void setOnFriendRequest(Function(dynamic) callback) {
    _callbacks['friendRequest'] = callback;
  }

  /// 设置在线状态回调
  void setOnOnlineStatus(Function(dynamic) callback) {
    _callbacks['onlineStatus'] = callback;
  }

  /// 设置用户状态回调
  void setOnUserStatus(Function(dynamic) callback) {
    _callbacks['userStatus'] = callback;
  }

  /// 设置好友状态回调
  void setOnFriendStatus(Function(dynamic) callback) {
    _callbacks['friendStatus'] = callback;
  }

  /// 设置正在输入回调
  void setOnTyping(Function(dynamic) callback) {
    _callbacks['typing'] = callback;
  }

  /// 设置停止输入回调
  void setOnStopTyping(Function(dynamic) callback) {
    _callbacks['stopTyping'] = callback;
  }

  /// 设置离线消息回调
  void setOnOfflineMessages(Function(dynamic) callback) {
    _callbacks['offlineMessages'] = callback;
  }

  /// 设置消息已读回调
  void setOnMessageRead(Function(dynamic) callback) {
    _callbacks['messageRead'] = callback;
  }

  /// 设置消息已读确认回调
  void setOnMessageReadConfirm(Function(dynamic) callback) {
    _callbacks['messageReadConfirm'] = callback;
  }

  /// 设置消息撤回回调
  void setOnMessageWithdrawn(Function(dynamic) callback) {
    _callbacks['messageWithdrawn'] = callback;
  }

  /// 设置消息撤回确认回调
  void setOnMessageWithdrawnConfirm(Function(dynamic) callback) {
    _callbacks['messageWithdrawnConfirm'] = callback;
  }

  /// 设置消息送达回调
  void setOnMessageDelivered(Function(dynamic) callback) {
    _callbacks['messageDelivered'] = callback;
  }

  /// 设置消息发送回调
  void setOnMessageSent(Function(dynamic) callback) {
    _callbacks['messageSent'] = callback;
  }

  /// 设置消息确认回调
  void setOnMessageAck(Function(dynamic) callback) {
    _callbacks['messageAck'] = callback;
  }

  /// 设置消息确认回复回调
  void setOnMessageAckConfirm(Function(dynamic) callback) {
    _callbacks['messageAckConfirm'] = callback;
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



  // 内部清理辅助
  void _clean() {
    socket = null;
    _currentToken = null;
    _currentUserId = null;
    userId = '';
    _connected = false;
    _setConnectionState(ConnectionState.disconnected);
    _reconnectAttempts = 0;
    
    // 清理所有回调
    _callbacks.updateAll((key, value) => null);
    _friendStatusListeners.clear();
    _lastEventTime.clear();
  }

  /// 获取连接统计信息
  Map<String, dynamic> getConnectionStats() {
    return {
      'connected': _connected,
      'connectionState': _connectionState.name,
      'reconnectAttempts': _reconnectAttempts,
      'currentUserId': _currentUserId,
      'hasToken': _currentToken != null,
      'socketId': socket?.id,
      'manuallyDisconnected': _manuallyDisconnected,
    };
  }

  /// 强制重置连接状态（调试用）
  void forceResetConnectionState() {
    print('🔧 强制重置连接状态');
    _reconnectAttempts = 0;
    _manuallyDisconnected = false;
    _setConnectionState(ConnectionState.disconnected);
  }
}

/// 连接状态枚举
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
  authError,
  failed,
}

extension ConnectionStateExtension on ConnectionState {
  String get name {
    switch (this) {
      case ConnectionState.disconnected:
        return '已断开';
      case ConnectionState.connecting:
        return '连接中';
      case ConnectionState.connected:
        return '已连接';
      case ConnectionState.reconnecting:
        return '重连中';
      case ConnectionState.error:
        return '连接错误';
      case ConnectionState.authError:
        return '认证错误';
      case ConnectionState.failed:
        return '连接失败';
    }
  }
  
  bool get isConnected => this == ConnectionState.connected;
  bool get isConnecting => this == ConnectionState.connecting || this == ConnectionState.reconnecting;
  bool get hasError => this == ConnectionState.error || this == ConnectionState.authError || this == ConnectionState.failed;
}