import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/chat.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/components/FastLongPressDetector.dart';
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

class _ChatDetailPageState extends ConsumerState<ChatDetailPage> {
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = Uuid();

  late final ChatSocketService _socketService;
  User? loginUser;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _userOnlineStatus = false;
  int _offset = 0;
  int totalMessages = 0;
  final int _pageSize = 20;
  final FocusNode _focusNode = FocusNode();
  final Set<String> _readMessageIds = {}; // 防止重复标记已读
  String? selectedMessageLocalId;
  final MessageQueue _messageQueue = MessageQueue();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Database? _messageDatabase;

  late Connectivity _connectivity;
  late bool _isOnline;
  Timer? _heartbeatRetryTimer;
  static const int _heartbeatRetryInterval = 60000; // 60秒心跳重试间隔

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _isOnline = false;
    _messageDatabase = null;
    _connectivitySubscription = null;
    _socketService = ChatSocketService();
    _initConnect();
    // 注册所有事件回调
    _registerSocketCallbacks();
    _scrollController.addListener(() {
      if (_scrollController.offset <= 0 &&
          !_loadingMore &&
          _hasMore &&
          !_loading) {
        _loadMoreHistory();
      }
    });

    _loadInitialHistory();
    _initDatabase();
    _initConnectivityListener();
    _loadUnsentMessages();
    _messageQueue.onMessageSent = _onMessageSent;
    _startHeartbeatRetry();
  }

  void _initConnect() async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    final token = authState.token;
    setState(() {
      loginUser = user;
    });
    _socketService.connect(token!, user!.id);
    _joinSession();
  }

  Future<void> _initDatabase() async {
    _messageDatabase = await MessageDatabase.init();
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
    try {
      _socketService.sendMessage(
        sessionId: widget.chatSession.sessionId,
        content: message['text'],
        localId: message['localId'],
      );
      // 因为服务器会返回确认消息，避免重复显示
      // 如果有_messageDatabase实例，更新数据库中的状态
      if (_messageDatabase != null && message['localId'] != null) {
        // 使用MessageDatabase的静态方法更新状态
        await MessageDatabase.updateMessageStatus(
          _messageDatabase!,
          message['localId'],
          MessageSendStatus.success,
        );
      }

      return true;
    } catch (e) {
      // 如果有_messageDatabase实例，更新数据库中的状态
      if (_messageDatabase != null && message['localId'] != null) {
        // 使用MessageDatabase的静态方法更新状态
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
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position);
      }
    }
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
    print('用户 ${data['userId']} 正在输入');
    // 可以显示"对方正在输入"提示
  }

  // 处理他人停止输入
  void _onStopTyping(dynamic data) {
    print('用户 ${data['userId']} 停止输入');
    // 可以隐藏"对方正在输入"提示
  }

  // 处理离线消息
  void _onOfflineMessages(dynamic data) {
    print('收到离线消息: $data');
    // 可以处理离线消息
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
    print('消息已撤回: ${data['id']}');
    // 可以从UI中移除消息
  }

  // 处理他人撤回消息
  void _onMessageWithdrawn(dynamic data) {
    print('用户 ${data['userId']} 撤回了消息: ${data['id']}');
    // 可以从UI中移除消息
  }

  // 处理消息送达确认
  void _onMessageDelivered(dynamic data) {
    print('消息已送达用户: ${data['id']}');
    // 可以更新消息送达状态
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
              return {
                'fromMe': msg.senderId == loginUser?.id,
                'text': msg.content,
                'createdAt': msg.createdAt,
                'sendStatus': MessageSendStatus.success,
                'localId': msg.id.toString(),
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
    _connectivitySubscription?.cancel();
    _stopHeartbeatRetry();
    _messageQueue.dispose();
    _messageDatabase?.close();
    _socketService.socket.off('newMessage', _onNewMessage);
    _socketService.socket.off('messageSent', _onMessageSentWrapper);
    _socketService.socket.off('messageAck', _onMessageAck);
    _socketService.socket.off('messageAckConfirm', _onMessageAckConfirm);

    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          });
        },
        child: Column(
          children: [
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            if (_loadingMore) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '正在获取信息中...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            } else if (!_hasMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: Text(
                                    '没有更多消息了',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }

                          final msg = messages[index - 1];
                          final isMe = msg['fromMe'] as bool;
                          return _buildMessageItem(msg, isMe, loginUser);
                        },
                      ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
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
            sendStatus == MessageSendStatus.success &&
            !isMe) {
          _readMessageIds.add(messageId);
          await markMessageReadApi(messageId); // ✅ 调用已读 API
        }
      },
      child: Column(
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder:
                (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
            child:
                (selectedMessageLocalId != null &&
                        selectedMessageLocalId == localId)
                    ? _buildMessageMenu(msg, isMe)
                    : const SizedBox.shrink(),
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
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: '输入消息...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              onTap: _scrollToBottom, // 点击输入框时滚动到底部
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.pink),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }




  Widget _buildMessageMenu(Map<String, dynamic> msg, bool isMe) {
    final localId = msg['localId'];
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMe)
            _buildMenuIcon(
              icon: Icons.undo,
              label: '撤回',
              onTap: () => _recallMessage(localId),
            ),
          _buildMenuIcon(
            icon: Icons.copy,
            label: '复制',
            onTap: () => _copyMessage(msg['text']),
          ),
          _buildMenuIcon(
            icon: Icons.delete_outline,
            label: '删除',
            onTap: () => _deleteMessage(localId),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuIcon({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        setState(() {
          selectedMessageLocalId = null;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.pink),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
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

  void _deleteMessage(String localId) {
    setState(() {
    });
  }

  void _recallMessage(String localId) async {
    setState(() {
    });
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
