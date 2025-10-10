import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/chat.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/components/FastLongPressDetector.dart';
import 'package:heart_days/http/model/api_response.dart';
import 'package:heart_days/models/message.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/services/ChatSocketService.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:heart_days/utils/date_utils.dart';
import 'package:heart_days/utils/message_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChatDetailPage extends ConsumerStatefulWidget {
  final ChatSession chatSession;

  const ChatDetailPage({super.key, required this.chatSession});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = Uuid();
  
  // 扩展表情列表，增加更多表情
  final List<String> emojiList = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂',
    '😊', '😇', '🙂', '🙃', '😉', '😍', '🥰', '😘',
    '😗', '😚', '😋', '😜', '😎', '🤗', '🤔', '😶',
    '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄',
    '😬', '🤥', '😌', '😔', '😪', '🤤', '😴', '😷',
    '🤒', '🤕', '🤢', '🤮', '🤧', '🥵', '🥶', '🥴',
    '😵', '🤯', '🤠', '🥳', '😎', '🤓', '🧐', '😕',
    '😟', '🙁', '☹️', '😮', '😯', '😲', '😳', '🥺',
    '😦', '😧', '😨', '😰', '😥', '😢', '😭', '😱',
    '😖', '😣', '😞', '😓', '😩', '😫', '🥱', '😤',
    '😡', '😠', '🤬', '😈', '👿', '💀', '☠️', '💩',
    '🤡', '👹', '👺', '👻', '👽', '👾', '🤖', '😺',
    '😸', '😹', '😻', '😼', '😽', '🙀', '😿', '😾',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍',
    '🤎', '💔', '❣️', '💕', '💞', '💓', '💗', '💖',
    '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉️', '☸️',
    '✡️', '🔯', '🕎', '☯️', '☦️', '🛐', '⛎', '♈',
    '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐',
    '♑', '♒', '♓', '🆔', '⚛️', '🉑', '☢️', '☣️',
    '📴', '📳', '🈶', '🈚', '🈸', '🈺', '🈷️', '✴️',
    '🆚', '💮', '🉐', '㊙️', '㊗️', '🈴', '🈵', '🈹',
    '🈲', '🅰️', '🅱️', '🆎', '🆑', '🅾️', '🆘', '❌',
    '⭕', '🛑', '⛔', '📛', '🚫', '💯', '💢', '♨️',
    '🚷', '🚯', '🚳', '🚱', '🔞', '📵', '🚭', '❗',
    '❕', '❓', '❔', '‼️', '⁉️', '🔅', '🔆', '〽️',
    '⚠️', '🚸', '🔱', '⚜️', '🔰', '♻️', '✅', '🈯',
    '💹', '❇️', '✳️', '❎', '🌐', '💠', 'Ⓜ️', '🌀',
    '💤', '🏧', '🚾', '♿', '🅿️', '🈳', '🈂️', '🛂',
    '🛃', '🛄', '🛅', '🚹', '🚺', '🚼', '🚻', '🚮',
    '🎦', '📶', '🈁', '🔣', 'ℹ️', '🔤', '🔡', '🔠',
    '🆖', '🆗', '🆙', '🆒', '🆕', '🆓', '0️⃣', '1️⃣',
    '2️⃣', '3️⃣', '4️⃣', '5️⃣', '6️⃣', '7️⃣', '8️⃣', '9️⃣',
    '🔟', '🔢', '#️⃣', '*️⃣', '⏏️', '▶️', '⏸️', '⏯️',
    '⏹️', '⏺️', '⏭️', '⏮️', '⏩', '⏪', '⏫', '⏬',
    '◀️', '🔼', '🔽', '➡️', '⬅️', '⬆️', '⬇️', '↗️',
    '↘️', '↙️', '↖️', '↕️', '↔️', '↪️', '↩️', '⤴️',
    '⤵️', '🔀', '🔁', '🔂', '🔄', '🔃', '🎵', '🎶',
    '➕', '➖', '➗', '✖️', '♾️', '💲', '💱', '™️',
    '©️', '®️', '〰️', '➰', '➿', '🔚', '🔙', '🔛',
    '🔝', '🔜', '✔️', '☑️', '🔘', '🔴', '🟠', '🟡',
    '🟢', '🔵', '🟣', '⚫', '⚪', '🟤', '🔺', '🔻',
    '🔸', '🔹', '🔶', '🔷', '🔳', '🔲', '▪️', '▫️',
    '◾', '◽', '◼️', '◻️', '🟥', '🟧', '🟨', '🟩',
    '🟦', '🟪', '⬛', '⬜', '🟫', '🔈', '🔇', '🔉',
    '🔊', '🔔', '🔕', '📣', '📢', '👁‍🗨', '💬', '💭',
    '🗯️', '♠️', '♣️', '♥️', '♦️', '🃏', '🎴', '🀄',
    '🕐', '🕑', '🕒', '🕓', '🕔', '🕕', '🕖', '🕗',
    '🕘', '🕙', '🕚', '🕛', '🕜', '🕝', '🕞', '🕟',
    '🕠', '🕡', '🕢', '🕣', '🕤', '🕥', '🕦', '🕧',
  ];
  
  final ChatSocketService _socketService = ChatSocketService();
  User? loginUser;

  // 状态管理
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _userOnlineStatus = false;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  
  // 分页相关
  int _offset = 0;
  int totalMessages = 0;
  final int _pageSize = 20;
  
  // UI控制器
  final FocusNode _focusNode = FocusNode();
  
  // 消息状态管理
  final Set<String> _readMessageIds = {}; // 防止重复标记已读
  final Set<String> _persistentReadMessageIds = {}; // 持久化的已读消息ID
  String? selectedMessageLocalId;
  final MessageQueue _messageQueue = MessageQueue();
  
  // 网络连接
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Database? _messageDatabase;
  
  // 面板状态
  bool _showEmojiPanel = false;
  bool _showMorePanel = false;

  // 网络和重连
  late Connectivity _connectivity;
  late bool _isOnline;
  Timer? _heartbeatRetryTimer;
  Timer? _typingTimer;
  static const int _heartbeatRetryInterval = 60000; // 60秒心跳重试间隔
  static const int _typingTimeout = 3000; // 3秒输入超时
  
  // 动画控制器
  late AnimationController _messageAnimationController;
  late AnimationController _panelAnimationController;
  late Animation<double> _messageAnimation;
  late Animation<double> _panelAnimation;
  
  // 性能优化
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  bool _isScrollingToBottom = false;
  Timer? _scrollDebounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 初始化动画控制器
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _panelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _messageAnimation = CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.easeOutBack,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeInOut,
    );
    
    // 初始化基础状态
    _connectivity = Connectivity();
    _isOnline = false;
    _messageDatabase = null;
    _connectivitySubscription = null;
    
    // 初始化连接和回调
    _initConnect();
    _registerSocketCallbacks();
    
    // 优化的滚动监听器
    _scrollController.addListener(_onScroll);
    
    // 输入框监听器
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    // 异步初始化
    _initializeAsync();

    // 页面进入后自动聚焦输入框（首帧渲染完成后）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showEmojiPanel = false;
        _showMorePanel = false;
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }
  
  Future<void> _initializeAsync() async {
    await _initDatabase();
    await _loadReadMessageIds();
    _initConnectivityListener();
    await _loadUnsentMessages();
    await _loadInitialHistory();
    _messageQueue.onMessageSent = _onMessageSent;
    _startHeartbeatRetry();
  }
  
  void _onScroll() {
    // 防抖处理滚动事件
    _scrollDebounceTimer?.cancel();
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.offset <= 100 &&
          !_loadingMore &&
          _hasMore &&
          !_loading) {
        _loadMoreHistory();
      }
    });
  }
  
  void _onTextChanged() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _socketService.sendTyping(widget.chatSession.sessionId);
      _startTypingTimer();
    } else if (text.isEmpty && _isTyping) {
      _stopTyping();
    }
    setState(() {});
  }
  
  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      setState(() {
        _showEmojiPanel = false;
        _showMorePanel = false;
      });
      _scrollToBottomSmooth();
    }
  }
  
  void _startTypingTimer() {
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: _typingTimeout), () {
      _stopTyping();
    });
  }
  
  void _stopTyping() {
    if (_isTyping) {
      _isTyping = false;
      _socketService.sendStopTyping(widget.chatSession.sessionId);
      _typingTimer?.cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResume();
        break;
      case AppLifecycleState.paused:
        // 应用暂停时停止输入状态
        _stopTyping();
        break;
      default:
        break;
    }
  }

  Future<void> _handleAppResume() async {
    // 确保服务已初始化
    if (!mounted) return;

    // 检查连接状态，如果未连接，则尝试重连
    if (!_socketService.isConnected) {
      final authState = ref.read(authProvider);
      final token = authState.token;
      final userId = authState.user?.id;
      if (token != null && userId != null) {
        await _socketService.connect(token, userId);
      }
    }

    // 延迟一小段时间，确保连接和会话状态同步
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // 重新加入会话并获取离线消息
    _socketService.joinSession(widget.chatSession.sessionId);
    final lastTime = _getLastMessageTime();
    _socketService.getOfflineMessages(lastTime);
  }

  // Future<void> _handleAppResume() async {
  //   // 确保服务已初始化
  //   if (!mounted) return;
  //
  //   // 检查连接状态，如果未连接，则尝试重连
  //   if (!_socketService.isConnected) {
  //     final authState = ref.read(authProvider);
  //     final token = authState.token;
  //     final userId = authState.user?.id;
  //     if (token != null && userId != null) {
  //       await _socketService.connect(token, userId);
  //     }
  //   }
  //
  //   // 延迟一小段时间，确保连接和会话状态同步
  //   await Future.delayed(const Duration(milliseconds: 200));
  //   if (!mounted) return;
  //
  //   // 重新加入会话并获取离线消息
  //   _socketService.joinSession(widget.chatSession.sessionId);
  //   final lastTime = _getLastMessageTime();
  //   _socketService.getOfflineMessages(lastTime);
  // }

  void _initConnect() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    setState(() {
      loginUser = user;
    });
    // _socketService = ChatSocketService(); // Removed to prevent re-initialization
    // 确保页面进入时建立连接
    final token = authState.token;
    final userId = user?.id;
    if (token != null && userId != null) {
      _socketService.connect(token, userId);
    }
    _joinSession();
  }

  Future<void> _initDatabase() async {
    _messageDatabase = await MessageDatabase.init();
  }

  // 加载已读消息ID
  Future<void> _loadReadMessageIds() async {
    if (_messageDatabase == null) {
      // 如果数据库还未初始化，延迟加载
      Future.delayed(const Duration(milliseconds: 100), () {
        _loadReadMessageIds();
      });
      return;
    }
    
    try {
      final readIds = await MessageDatabase.getReadMessageIds(
        _messageDatabase!,
        widget.chatSession.sessionId,
      );
      setState(() {
        _persistentReadMessageIds.addAll(readIds);
        _readMessageIds.addAll(readIds);
      });
      print('已加载 ${readIds.length} 个已读消息ID');
    } catch (e) {
      print('加载已读消息ID失败: $e');
    }
  }

  // 保存已读消息ID到数据库
  Future<void> _saveReadMessageId(String messageId) async {
    if (_messageDatabase == null) return;
    
    try {
      await MessageDatabase.saveReadMessageId(
        _messageDatabase!,
        widget.chatSession.sessionId,
        messageId,
      );
      _persistentReadMessageIds.add(messageId);
    } catch (e) {
      print('保存已读消息ID失败: $e');
    }
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      if (!wasOnline && _isOnline) {
        _messageQueue.resumeSending(_actuallySendMessage);
      }
    });
  }

  /// 开始心跳重试机制
  void _startHeartbeatRetry() {
    _stopHeartbeatRetry(); // 先停止已有的心跳重试
    _heartbeatRetryTimer = Timer.periodic(Duration(milliseconds: _heartbeatRetryInterval), (timer) {
      // 检查是否有未发送的消息，如果有则尝试重新发送
      if (_isOnline && _messageQueue.hasPendingMessages) {
        _messageQueue.resumeSending(_actuallySendMessage);
      }
    });
  }

  /// 停止心跳重试机制
  void _stopHeartbeatRetry() {
    _heartbeatRetryTimer?.cancel();
    _heartbeatRetryTimer = null;
  }

  Future<void> _loadUnsentMessages() async {
    if (_messageDatabase == null) return;

    // 使用MessageDatabase的静态方法获取未发送消息
    final unsentMessages = await MessageDatabase.getUnsentMessages(
      _messageDatabase!,
      widget.chatSession.sessionId,
    );

    setState(() {
      messages.insertAll(0, unsentMessages);
    });

    _messageQueue.initWithMessages(unsentMessages);
    if (_isOnline) {
      _messageQueue.startSending(_actuallySendMessage);
    }
  }

  // 修改_actuallySendMessage方法以匹配MessageQueue期望的签名
  Future<bool> _actuallySendMessage(Map<String, dynamic> message) async {
    // 若未连接，触发页面级连接并让队列稍后重试，避免“假成功”
    if (!_socketService.isConnected) {
      _initConnect();
      return false;
    }
    // 发送前确保加入会话房间
    _socketService.joinSession(widget.chatSession.sessionId);

    try {
      _socketService.sendMessage(
        sessionId: widget.chatSession.sessionId,
        content: message['text'],
        localId: message['localId'],
      );

      return true;
    } catch (e) {
      if (_messageDatabase != null && message['localId'] != null) {
        await MessageDatabase.updateMessageStatus(
          _messageDatabase!,
          message['localId'],
          MessageSendStatus.failed,
        );
      }
      return false;
    }
  }

  void _registerSocketCallbacks() {
    // 连接成功后再加入会话房间
    _socketService.setOnNewMessage(_onNewMessage);
    _socketService.setOnFriendRequest(_onFriendRequest);
    _socketService.setOnOnlineStatus(_onOnlineStatus);
    _socketService.setOnUserStatus(_onUserStatus);
    _socketService.setOnFriendStatus(_onFriendStatus);
    _socketService.setOnTyping(_onTyping);
    _socketService.setOnStopTyping(_onStopTyping);
    _socketService.setOnOfflineMessages(_onOfflineMessages);
    _socketService.setOnMessageRead(_onMessageRead);
    _socketService.setOnMessageReadConfirm(_onMessageReadConfirm);
    _socketService.setOnMessageWithdrawn(_onMessageWithdrawn);
    _socketService.setOnMessageWithdrawnConfirm(_onMessageWithdrawnConfirm);
    _socketService.setOnMessageDelivered(_onMessageDelivered);
    _socketService.setOnMessageSent(_onMessageSentWrapper);
    _socketService.setOnMessageAck(_onMessageAck);
    _socketService.setOnMessageAckConfirm(_onMessageAckConfirm);
  }

  // 在连接成功后调用此方法加入会话房间
  void _joinSession() {
    if (_socketService.isConnected) {
      _socketService.joinSession(widget.chatSession.sessionId);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (_isScrollingToBottom || !_scrollController.hasClients) return;
    
    _isScrollingToBottom = true;
    final position = _scrollController.position.maxScrollExtent;
    
    if (animated) {
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      ).then((_) {
        _isScrollingToBottom = false;
      });
    } else {
      _scrollController.jumpTo(position);
      _isScrollingToBottom = false;
    }
  }
  
  void _scrollToBottomSmooth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: true);
    });
  }

  Future<void> _onNewMessage(dynamic data) async {
    if (data['sessionId'] == widget.chatSession.sessionId) {
      final content = data['content'];
      final createdAt = data['createdAt'];
      final senderId = data['senderId'];
      final messageId = data['id'];
      final localId = data['localId'];

      // 检查是否已存在相同的消息，避免重复显示
      bool messageExists = messages.any(
        (m) =>
            (m['messageId'] != null && m['messageId'] == messageId) ||
            (m['localId'] != null && m['localId'] == localId),
      );

      if (messageExists) {
        // 如果消息已存在，只更新状态（可能是发送确认）
        setState(() {
          for (int i = 0; i < messages.length; i++) {
            if ((messages[i]['messageId'] != null &&
                    messages[i]['messageId'] == messageId) ||
                (messages[i]['localId'] != null &&
                    messages[i]['localId'] == localId)) {
              messages[i]['sendStatus'] = MessageSendStatus.success;
              if (createdAt != null) messages[i]['createdAt'] = createdAt;
              if (messageId != null) messages[i]['messageId'] = messageId;
              // 修复：确保fromMe字段正确设置，只在messageId匹配时更新
              if (messageId != null) {
                messages[i]['fromMe'] = senderId == loginUser?.id;
              }
              break;
            }
          }
        });
        // 收到服务器确认后再持久化标记成功（以服务器返回的 messageId 或本地 localId 为准）
        if (_messageDatabase != null && (messageId != null || localId != null)) {
          await MessageDatabase.markAsSent(
            _messageDatabase!,
            (messageId ?? localId).toString(),
          );
        }
      } else {
        // 消息不存在，添加新消息
        setState(() {
          messages.add({
            'fromMe': senderId == loginUser?.id,
            'text': content,
            'createdAt': createdAt,
            'sendStatus': MessageSendStatus.success,
            'localId': messageId?.toString() ?? localId ?? _uuid.v4(),
            'messageId': messageId,
          });
        });
      }
      _scrollToBottom();
    }
  }

  // 处理好友请求
  void _onFriendRequest(dynamic data) {
    print('收到好友请求: $data');
    // 可以显示通知或更新UI
  }

  // 处理在线状态变化
  void _onOnlineStatus(dynamic data) {
    print('在线状态变化: $data');
    // 可以更新用户在线状态显示
  }

  // 处理用户状态变化
  void _onUserStatus(dynamic data) {
    print('用户状态变化: $data');
    // 可以更新用户状态显示
  }

  // 处理好友在线状态变化
  void _onFriendStatus(dynamic data) {
    if (!mounted) return; // 防止 setState 报错
    print('好友在线状态变化: $data');
    setState(() {
      _userOnlineStatus = data['status'] == 'online';
    });
  }

  // 处理他人正在输入
  void _onTyping(dynamic data) {
    if (data['sessionId'] == widget.chatSession.sessionId && 
        data['userId'] != loginUser?.id) {
      setState(() {
        _otherUserTyping = true;
      });
      print('用户 ${data['userId']} 正在输入');
    }
  }

  // 处理他人停止输入
  void _onStopTyping(dynamic data) {
    if (data['sessionId'] == widget.chatSession.sessionId && 
        data['userId'] != loginUser?.id) {
      setState(() {
        _otherUserTyping = false;
      });
      print('用户 ${data['userId']} 停止输入');
    }
  }

  // 处理离线消息
  void _onOfflineMessages(dynamic data) {
    if (!mounted) return;
    try {
      final List<dynamic> list = (data is Map && data['messages'] is List)
          ? (data['messages'] as List)
          : (data is List ? data : []);
      if (list.isEmpty) {
        print('收到离线消息: 空');
        return;
      }

      // 过滤出当前会话的消息，并去重
      final newMsgs = <Map<String, dynamic>>[];
      for (final item in list) {
        final sessionId = item['sessionId'];
        if (sessionId != widget.chatSession.sessionId) continue;

        final messageId = item['id'] ?? item['messageId'];
        final localId = item['localId'];
        final exists = messages.any((m) =>
            (m['messageId']?.toString() == messageId?.toString()) ||
            (m['localId']?.toString() == localId?.toString()));
        if (exists) continue;

        newMsgs.add({
          'fromMe': item['senderId'] == loginUser?.id,
          'text': item['content'],
          'createdAt': item['createdAt'],
          'sendStatus': MessageSendStatus.success,
          'localId': messageId?.toString() ?? localId ?? _uuid.v4(),
          'messageId': messageId,
        });
      }

      if (newMsgs.isNotEmpty) {
        setState(() {
          messages.addAll(newMsgs);
          // 合并后按时间戳重新排序，确保消息顺序正确
          messages.sort((a, b) {
            final aTime = a['createdAt'];
            final bTime = b['createdAt'];
            if (aTime is String && bTime is String) {
              return aTime.compareTo(bTime);
            }
            return 0; // 对于无效时间戳，保持原顺序
          });
        });
        _scrollToBottomSmooth();
        print('离线消息已合并: ${newMsgs.length} 条');
      }
    } catch (e) {
      print('处理离线消息异常: $e');
    }
  }

  // 处理消息已读确认
  void _onMessageReadConfirm(dynamic data) {
    print('消息已读确认: ${data['messageId']}');
    // 可以更新消息已读状态
  }

  // 处理他人消息已读
  void _onMessageRead(dynamic data) {
    print('用户 ${data['userId']} 已读消息: ${data['id']}');
    // 可以更新消息已读状态
  }

  // 处理撤回确认
  void _onMessageWithdrawnConfirm(dynamic data) {
    print('消息已撤回: ${data['id'] ?? data['messageId']}');
    _removeMessageByPayload(data);
  }

  // 处理他人撤回消息
  void _onMessageWithdrawn(dynamic data) {
    print('用户 ${data['userId']} 撤回了消息: ${data['id'] ?? data['messageId']}');
    _removeMessageByPayload(data);
  }

  // 处理消息送达确认
  void _onMessageDelivered(dynamic data) {
    print('消息已送达用户: ${data['id']}');
    // 可以更新消息送达状态
  }
  void _onEmojiPressed() {
    setState(() {
      _showEmojiPanel = !_showEmojiPanel;
      _showMorePanel = false;
      if (_showEmojiPanel) {
        _focusNode.unfocus(); // 收起键盘
        _panelAnimationController.forward();
      } else {
        _panelAnimationController.reverse();
      }
    });
  }

  void _onPlusPressed() {
    setState(() {
      _showMorePanel = !_showMorePanel;
      _showEmojiPanel = false;
      if (_showMorePanel) {
        _focusNode.unfocus(); // 收起键盘
        _panelAnimationController.forward();
      } else {
        _panelAnimationController.reverse();
      }
    });
  }

  Widget _buildEmojiPanel() {
    return AnimatedBuilder(
      animation: _panelAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _panelAnimation.value,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 表情网格
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: emojiList.length,
                    itemBuilder: (_, index) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          final emoji = emojiList[index];
                          final text = _controller.text;
                          final cursorPos = _controller.selection.baseOffset;
                          final newText = text.replaceRange(
                            cursorPos,
                            cursorPos,
                            emoji,
                          );
                          _controller.text = newText;
                          _controller.selection = TextSelection.collapsed(
                            offset: cursorPos + emoji.length,
                          );
                          setState(() {});
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              emojiList[index],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMorePanel() {
    return AnimatedBuilder(
      animation: _panelAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _panelAnimation.value,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 4,
                    padding: const EdgeInsets.all(12),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildMoreItem(Icons.photo_library, '相册', () {
                        HapticFeedback.lightImpact();
                        ToastUtils.showToast('相册功能开发中');
                      }),
                      _buildMoreItem(Icons.camera_alt, '拍照', () {
                        HapticFeedback.lightImpact();
                        ToastUtils.showToast('拍照功能开发中');
                      }),
                      _buildMoreItem(Icons.attach_file, '文件', () {
                        HapticFeedback.lightImpact();
                        ToastUtils.showToast('文件功能开发中');
                      }),
                      _buildMoreItem(Icons.location_on, '位置', () {
                        HapticFeedback.lightImpact();
                        ToastUtils.showToast('位置功能开发中');
                      }),
                      _buildMoreItem(Icons.videocam, '视频通话', () {
                        HapticFeedback.lightImpact();
                        ToastUtils.showToast('视频通话功能开发中');
                      }),
                      _buildMoreItem(Icons.phone, '语音通话', () {
                        HapticFeedback.lightImpact();
                        ToastUtils.showToast('语音通话功能开发中');
                      }),
                      _buildMoreItem(Icons.card_giftcard, '红包', () {
                        HapticFeedback.lightImpact();
                        ToastUtils.showToast('红包功能开发中');
                      }),
                      _buildMoreItem(Icons.payment, '转账', () {
                        HapticFeedback.lightImpact();
                        ToastUtils.showToast('转账功能开发中');
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoreItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: const Color(0xFF07C160),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _loadInitialHistory() async {
    setState(() {
      _loading = true;
      _offset = 0;
      messages.clear();
      _hasMore = true;
    });
    await _loadPage(_offset, scrollToBottom: true);
  }

  Future<void> _loadMoreHistory() async {
    if (!_hasMore || _loadingMore) return;
    if (_offset >= totalMessages) return; // 防止offset超出

    setState(() => _loadingMore = true);

    // 记录加载前的滚动位置和最大可滚动距离
    double oldScrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    double oldMaxExtent =
        _scrollController.hasClients
            ? _scrollController.position.maxScrollExtent
            : 0.0;

    _offset += _pageSize;
    await _loadPage(
      _offset,
      oldScrollOffset: oldScrollOffset,
      oldMaxExtent: oldMaxExtent,
    );

    setState(() => _loadingMore = false);
  }

  Future<void> _loadPage(
    int offset, {
    bool scrollToBottom = false,
    double? oldScrollOffset,
    double? oldMaxExtent,
  }) async {
    final res = await getChatHistoryApi({
      'id': widget.chatSession.sessionId,
      'limit': _pageSize,
      'offset': offset,
    });

    if (res.code == 200 && res.data != null) {
      List<ChatMessage> records = res.data!.records;

      setState(() {
        totalMessages = res.data!.total;
        final newMsgList =
            records.map((msg) {
              final messageId = msg.id.toString();
              // 检查消息是否已读，如果已读则添加到已读集合中
              if (_persistentReadMessageIds.contains(messageId)) {
                _readMessageIds.add(messageId);
              }
              
              return {
                'fromMe': msg.senderId == loginUser?.id,
                'text': msg.content,
                'createdAt': msg.createdAt,
                'sendStatus': MessageSendStatus.success,
                'localId': messageId,
                'messageId': msg.id,
              };
            }).toList();

        if (scrollToBottom || messages.isEmpty) {
          messages.addAll(newMsgList);
        } else {
          messages.insertAll(0, newMsgList);
        }

        // 只要 hasNext==false 或 records.length < _pageSize，就不能再加载
        _hasMore = (res.data!.hasNext == true) && (records.length == _pageSize);
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          if (scrollToBottom) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          } else if (oldScrollOffset != null && oldMaxExtent != null) {
            // 计算新offset，保持视觉停留在原地
            double newMaxExtent = _scrollController.position.maxScrollExtent;
            double newOffset = newMaxExtent - (oldMaxExtent - oldScrollOffset);
            _scrollController.jumpTo(newOffset);
          }
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final localId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    // 创建消息对象
    final message = {
      'fromMe': true,
      'text': text,
      'createdAt': now,
      'sendStatus': MessageSendStatus.sending,
      'localId': localId,
      'messageId': null,
      'sessionId': widget.chatSession.sessionId,
    };

    // 立即添加到UI
    setState(() => messages.add(message));
    _controller.clear();
    _scrollToBottom();

    // 保存到本地数据库
    if (_messageDatabase != null) {
      await MessageDatabase.saveMessage(_messageDatabase!, message);
    }

    // 添加到发送队列
    _messageQueue.addMessage(message, (msg) => _actuallySendMessage(msg));
  }

  void _onMessageSent(
    Map<String, dynamic> message,
    bool success,
    String? error,
  ) {
    if (success) {
      _updateMessageStatus(message['localId'], MessageSendStatus.success);
      if (_messageDatabase != null && message['messageId'] != null) {
        MessageDatabase.markAsSent(_messageDatabase!, message['messageId']);
      }
    } else {
      _updateMessageStatus(message['localId'], MessageSendStatus.failed);
      if (error != null) {
        ToastUtils.showToast('发送失败: $error');
      }
    }
  }

  void _onMessageSentWrapper(dynamic data) {
    print('消息发送回调: $data');
  }

  void _onMessageAck(dynamic data) {
    print('消息确认: $data');
    // 可以更新消息确认状态
  }

  void _onMessageAckConfirm(dynamic data) {
    print('消息确认回复: $data');
    // 可以更新消息确认回复状态
  }

  void _updateMessageStatus(String localId, MessageSendStatus status) {
    setState(() {
      final index = messages.indexWhere((m) => m['localId'] == localId);
      if (index != -1) {
        messages[index]['sendStatus'] = status;
      }
    });
  }

  // 重试发送（失败时点击重试）
  void _retrySend(String localId) {
    final index = messages.indexWhere((m) => m['localId'] == localId);
    if (index == -1) return;

    final message = messages[index];
    setState(() {
      messages[index]['sendStatus'] = MessageSendStatus.sending;
    });
    _messageQueue.retryMessage(message, (msg) => _actuallySendMessage(msg));
  }

  @override
  void dispose() {
    // 移除生命周期观察者
    WidgetsBinding.instance.removeObserver(this);
    
    // 停止输入状态
    _stopTyping();
    
    // 取消订阅和定时器
    _connectivitySubscription?.cancel();
    _stopHeartbeatRetry();
    _typingTimer?.cancel();
    _scrollDebounceTimer?.cancel();
    
    // 清理消息队列和数据库
    _messageQueue.dispose();
    _messageDatabase?.close();
    
    // 移除Socket事件监听
    _socketService.socket?.off('newMessage', _onNewMessage);
    _socketService.socket?.off('messageSent', _onMessageSentWrapper);
    _socketService.socket?.off('messageAck', _onMessageAck);
    _socketService.socket?.off('messageAckConfirm', _onMessageAckConfirm);
    _socketService.socket?.off('typing', _onTyping);
    _socketService.socket?.off('stopTyping', _onStopTyping);
    _socketService.socket?.off('messageWithdrawn', _onMessageWithdrawn);
    _socketService.socket?.off('messageWithdrawnConfirm', _onMessageWithdrawnConfirm);

    // 释放控制器和动画
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messageAnimationController.dispose();
    _panelAnimationController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false; // 阻止默认返回，改为携带结果返回
      },
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.chatSession.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            _buildStatusBadge(isOnline: _userOnlineStatus),
          ],
        ),
      )

      ,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            selectedMessageLocalId = null;
            _showEmojiPanel = false;
            _showMorePanel = false;
          });
          _panelAnimationController.reverse();
        },
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF07C160),
                      ),
                    )
                  : Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 60),
                          itemCount: messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildLoadingHeader();
                            }

                            final msg = messages[index - 1];
                            final isMe = msg['fromMe'] as bool;
                            return _buildMessageItem(msg, isMe, loginUser);
                          },
                        ),
                        // 输入状态提示
                        if (_otherUserTyping)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: _buildTypingIndicator(),
                          ),
                      ],
                    ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    )
    );
  }

// 独立的小组件：在线绿色，离线灰色
  Widget _buildStatusBadge({required bool isOnline}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOnline ? const Color(0xFF07C160) : Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isOnline ? '在线' : '离线',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  Widget _buildMessageItem(Map<String, dynamic> msg, bool isMe, User? user) {
    final avatarUrl = isMe ? user?.avatar : widget.chatSession.avatar;
    final text = msg['text'] ?? '';
    final messageId = msg['messageId'];
    final localId = msg['localId'];
    final sendStatus = msg['sendStatus'] ?? MessageSendStatus.success;
    return VisibilityDetector(
      key: Key('msg-${messageId ?? localId ?? UniqueKey()}'),
      onVisibilityChanged: (VisibilityInfo info) async {
        // 优化：仅当消息发送成功、有messageId且未标记已读时才调用API
        if (info.visibleFraction > 0.5 &&
            messageId != null &&
            !_readMessageIds.contains(messageId) &&
            !_persistentReadMessageIds.contains(messageId) &&
            sendStatus == MessageSendStatus.success &&
            !isMe) {
          
          // 立即添加到内存集合，防止重复调用
          _readMessageIds.add(messageId);
          
          print('准备标记消息已读: $messageId');
          
          try {
            // 调用已读API
            final response = await markMessageReadApi(messageId);
            if (response.success) {
              // API调用成功后，保存到持久化存储
              await _saveReadMessageId(messageId);
              print('消息已读标记成功: $messageId');
            } else {
              // API调用失败，从内存集合中移除，允许下次重试
              _readMessageIds.remove(messageId);
              print('消息已读API调用失败: $messageId');
            }
          } catch (e) {
            // 异常情况下，从内存集合中移除，允许下次重试
            _readMessageIds.remove(messageId);
            print('标记消息已读异常: $messageId, 错误: $e');
          }
        } else if (messageId != null && (_readMessageIds.contains(messageId) || _persistentReadMessageIds.contains(messageId))) {
          print('消息已读过，跳过API调用: $messageId');
        }
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe) _buildAvatar(avatarUrl),
                    if (!isMe) const SizedBox(width: 8),
                    // 状态指示器（发送loading和重试图标）放在消息外面的左侧
                    if (isMe && sendStatus == MessageSendStatus.sending)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (isMe && sendStatus == MessageSendStatus.failed)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: GestureDetector(
                          onTap: () => _retrySend(localId),
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                        ),
                      ),
                    Flexible(
                      child: FastLongPressDetector(
                        duration: const Duration(milliseconds: 200),
                        onLongPress: () {
                          setState(() {
                            selectedMessageLocalId = localId;
                          });
                        },
                        child: Column(
                          crossAxisAlignment:
                              isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 4),
                                child: Text(
                                  widget.chatSession.name,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isMe
                                        ? Colors.pink.withOpacity(0.1)
                                        : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                text,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            if (msg['createdAt'] != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  left: 4,
                                  right: 4,
                                ),
                                child: Text(
                                  formatMsgTime(msg['createdAt']),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (isMe) const SizedBox(width: 8),
                    if (isMe) _buildAvatar(avatarUrl),
                  ],
                ),
              ),
              // 菜单显示在消息气泡下方的中心位置
              if (selectedMessageLocalId != null && selectedMessageLocalId == localId)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isMe) const SizedBox(width: 48), // 头像宽度 + 间距
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: 1.0,
                              child: _buildMessageMenu(msg, isMe),
                            ),
                          ],
                        ),
                      ),
                      if (isMe) const SizedBox(width: 48), // 头像宽度 + 间距
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return CircleAvatar(
      radius: 20,
      backgroundImage:
          (url != null && url.isNotEmpty) ? NetworkImage(url) : null,
      child:
          (url == null || url.isEmpty)
              ? const Icon(Icons.person_outline, color: Colors.grey)
              : null,
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 输入框区域
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 表情按钮
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: IconButton(
                    icon: Icon(
                      _showEmojiPanel ? Icons.keyboard : Icons.emoji_emotions_outlined,
                      color: _showEmojiPanel ? const Color(0xFF07C160) : Colors.grey[600],
                      size: 26,
                    ),
                    onPressed: _onEmojiPressed,
                  ),
                ),
                // 输入框
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 120,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                      ),
                      decoration: InputDecoration(
                        hintText: '请输入消息...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 发送 or 加号按钮
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: _controller.text.trim().isNotEmpty
                      ? Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF07C160),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _sendMessage,
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            _showMorePanel ? Icons.keyboard : Icons.add_circle_outline,
                            color: _showMorePanel ? const Color(0xFF07C160) : Colors.grey[600],
                            size: 26,
                          ),
                          onPressed: _onPlusPressed,
                        ),
                ),
              ],
            ),
          ),
          // 表情面板
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _showEmojiPanel ? 280 : 0,
            child: _showEmojiPanel ? _buildEmojiPanel() : const SizedBox.shrink(),
          ),
          // 更多功能面板
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _showMorePanel ? 220 : 0,
            child: _showMorePanel ? _buildMorePanel() : const SizedBox.shrink(),
          ),
          // 底部安全区
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
  
  Widget _buildLoadingHeader() {
    if (_loadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF07C160),
              ),
            ),
            SizedBox(width: 12),
            Text(
              '正在加载历史消息...',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (!_hasMore && messages.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '已显示全部消息',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
  
  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.chatSession.name} 正在输入',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }






  Widget _buildMessageMenu(Map<String, dynamic> msg, bool isMe) {
    final localId = msg['localId'];
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMe)
            _buildMenuIcon(
              icon: Icons.undo_rounded,
              label: '撤回',
              iconColor: Colors.white,
              textColor: Colors.white,
              onTap: () => _recallMessage(msg['messageId']),
            ),
          _buildMenuIcon(
            icon: Icons.content_copy_rounded,
            label: '复制',
            iconColor: Colors.white,
            textColor: Colors.white,
            onTap: () => _copyMessage(msg['text']),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.grey,
    Color textColor = Colors.black87,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        setState(() {
          selectedMessageLocalId = null;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ToastUtils.showToast('已复制到剪贴板');
  }

  // 获取当前页面最后一条消息的时间（用于拉取离线消息的起点）
  String? _getLastMessageTime() {
    if (messages.isEmpty) return null;
    // 取最后一条消息的 createdAt
    for (int i = messages.length - 1; i >= 0; i--) {
      final ts = messages[i]['createdAt'];
      if (ts != null && ts.toString().isNotEmpty) {
        return ts.toString();
      }
    }
    return null;
  }

  // 统一根据服务器撤回事件数据移除本地消息
  void _removeMessageByPayload(dynamic data) {
    final dynamic rawId = data['messageId'] ?? data['id'];
    if (rawId == null) return;
    final String idStr = rawId.toString();
    setState(() {
      messages.removeWhere((m) =>
        (m['messageId']?.toString() == idStr) ||
        (m['localId']?.toString() == idStr)
      );
    });
  }


  Future<void> _recallMessage(String messageId) async {
    ApiResponse res = await withdrawMessageApi(messageId);
    if (res.success) {
      setState(() {
        messages.removeWhere((m) => m['messageId'] == messageId);
      });
      ToastUtils.showToast('消息已撤回');
    }
  }
}

// 新增消息队列管理类
class MessageQueue {
  final List<Map<String, dynamic>> _queue = [];
  final List<Map<String, dynamic>> _processing = [];
  bool _isSending = false;
  final Duration _initialDelay = Duration(milliseconds: 1000);
  final Duration _maxDelay = Duration(seconds: 30);
  final Map<String, int> _retryCounts = {};
  Function(Map<String, dynamic>, bool, String?)? onMessageSent;

  void initWithMessages(List<Map<String, dynamic>> messages) {
    _queue.addAll(
      messages.where((m) => m['sendStatus'] == MessageSendStatus.failed),
    );
  }

  void addMessage(
    Map<String, dynamic> message,
    Future<bool> Function(Map<String, dynamic>) sender,
  ) {
    _queue.add(message);
    if (!_isSending) {
      _startProcessing(sender);
    }
  }

  void retryMessage(
    Map<String, dynamic> message,
    Future<bool> Function(Map<String, dynamic>) sender,
  ) {
    final localId = message['localId'];
    _queue.removeWhere((m) => m['localId'] == localId);
    _processing.removeWhere((m) => m['localId'] == localId);
    _retryCounts.remove(localId);
    addMessage(message, sender);
  }

  Future<void> _startProcessing(
    Future<bool> Function(Map<String, dynamic>) sender,
  ) async {
    if (_isSending || _queue.isEmpty) return;

    _isSending = true;
    while (_queue.isNotEmpty) {
      final message = _queue.removeAt(0);
      _processing.add(message);

      final localId = message['localId'];
      final retryCount = _retryCounts[localId] ?? 0;
      bool success = false;
      String? error;

      try {
        // 指数退避重试
        if (retryCount > 0) {
          final delay = _calculateDelay(retryCount);
          await Future.delayed(delay);
        }

        success = await sender(message);
        if (!success) {
          _retryCounts[localId] = retryCount + 1;
          if (retryCount >= 5) {
            // 最大重试5次
            error = '超过最大重试次数';
            success = true; // 不再重试
          } else {
            _queue.insert(0, message); // 放回队列重试
          }
        }
      } catch (e) {
        error = e.toString();
        _queue.insert(0, message);
      } finally {
        _processing.remove(message);
        if (onMessageSent != null) {
          onMessageSent!(message, success, error);
        }

        if (!success && _queue.isNotEmpty) {
          // 继续处理下一个消息
          continue;
        } else if (!success) {
          // 队列为空但当前消息未成功，稍后重试
          _isSending = false;
          _scheduleRetry(sender);
          break;
        }
      }
    }

    _isSending = false;
  }

  Duration _calculateDelay(int retryCount) {
    final delay = _initialDelay * (2 << (retryCount - 1));
    return delay > _maxDelay ? _maxDelay : delay;
  }

  void _scheduleRetry(Future<bool> Function(Map<String, dynamic>) sender) {
    Future.delayed(_initialDelay, () {
      if (!_isSending && _queue.isNotEmpty) {
        _startProcessing(sender);
      }
    });
  }

  void resumeSending(Future<bool> Function(Map<String, dynamic>) sender) {
    if (!_isSending && _queue.isNotEmpty) {
      _startProcessing(sender);
    }
  }

  void startSending(Future<bool> Function(Map<String, dynamic>) sender) {
    if (!_isSending && _queue.isNotEmpty) {
      _startProcessing(sender);
    }
  }

  bool get hasPendingMessages => _queue.isNotEmpty || _processing.isNotEmpty;

  void dispose() {
    _queue.clear();
    _processing.clear();
    _retryCounts.clear();
  }
}
