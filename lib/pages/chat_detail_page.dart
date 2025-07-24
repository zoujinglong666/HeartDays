import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:heart_days/apis/chat.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/components/FastLongPressDetector.dart';
import 'package:heart_days/models/message.dart';
import 'package:heart_days/provider/get_login_userinfo.dart';
import 'package:heart_days/services/ChatSocketService.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:heart_days/utils/message_database.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChatDetailPage extends StatefulWidget {
  final ChatSession chatSession;

  const ChatDetailPage({super.key, required this.chatSession});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  // 添加缺失的类变量声明
  final List<Map<String, dynamic>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = Uuid();

  late final ChatSocketService _socketService;
  String myUserId = '';
  String myToken = '';
  User? myUser;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  int totalMessages = 0;
  final int _pageSize = 20;
  final FocusNode _focusNode = FocusNode();
  final Set<String> _readMessageIds = {}; // 防止重复标记已读
  String? selectedMessageLocalId;
  final MessageQueue _messageQueue = MessageQueue();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Database? _messageDatabase;
  
  // 添加缺失的变量声明
  late Connectivity _connectivity;
  late bool _isOnline;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _isOnline = false;
    _messageDatabase = null;
    _connectivitySubscription = null;
    _getUserInfo();
    _socketService = ChatSocketService();
    if (myToken.isEmpty && myUserId.isNotEmpty) {
      _socketService.connect(myToken, myUserId);
    }
    _socketService.joinSession(widget.chatSession.sessionId);
    _socketService.onNewMessage(_onNewMessage);

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
  }

  // 添加缺失的_initDatabase方法
  Future<void> _initDatabase() async {
    _messageDatabase = await MessageDatabase.init();
  }

  // 添加缺失的_initConnectivityListener方法
  void _initConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (!wasOnline && _isOnline) {
        _messageQueue.resumeSending(_actuallySendMessage);
      }
    });
  }

  // 修复_loadUnsentMessages方法中的静态调用错误
  Future<void> _loadUnsentMessages() async {
    if (_messageDatabase == null) return;

    // 使用MessageDatabase的静态方法获取未发送消息
    final unsentMessages = await MessageDatabase.getUnsentMessages(
      _messageDatabase!, widget.chatSession.sessionId
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
      
      // 不再在这里更新UI状态，而是通过_onNewMessage处理
      // 因为服务器会返回确认消息，避免重复显示
      
      // 如果有_messageDatabase实例，更新数据库中的状态
      if (_messageDatabase != null && message['localId'] != null) {
        // 使用MessageDatabase的静态方法更新状态
        await MessageDatabase.updateMessageStatus(
          _messageDatabase!, message['localId'], MessageSendStatus.success
        );
      }
      
      return true;
    } catch (e) {
      // 如果有_messageDatabase实例，更新数据库中的状态
      if (_messageDatabase != null && message['localId'] != null) {
        // 使用MessageDatabase的静态方法更新状态
        await MessageDatabase.updateMessageStatus(
          _messageDatabase!, message['localId'], MessageSendStatus.failed
        );
      }
      
      return false;
    }
  }

  // 移除重复的_actuallySendMessage方法定义

  Future<void> _getUserInfo() async {
    final loginState = await LoginUserInfo().getLoginState();

    if (loginState.token == null || loginState.userId == null || loginState.user == null) {
      // 可跳转登录或提示异常
      return;
    }

    setState(() {
      myToken = loginState.token!;
      myUserId = loginState.userId!;
      myUser = loginState.user!;
    });
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
      final messageId = data['messageId'];
      final localId = data['localId'];
      
      // 检查是否已存在相同的消息，避免重复显示
      bool messageExists = messages.any((m) => 
        (m['messageId'] != null && m['messageId'] == messageId) ||
        (m['localId'] != null && m['localId'] == localId)
      );
      
      if (messageExists) {
        // 如果消息已存在，只更新状态（可能是发送确认）
        setState(() {
          for (int i = 0; i < messages.length; i++) {
            if ((messages[i]['messageId'] != null && messages[i]['messageId'] == messageId) ||
                (messages[i]['localId'] != null && messages[i]['localId'] == localId)) {
              messages[i]['sendStatus'] = MessageSendStatus.success;
              if (createdAt != null) messages[i]['createdAt'] = createdAt;
              if (messageId != null) messages[i]['messageId'] = messageId;
              break;
            }
          }
        });
      } else {
        // 消息不存在，添加新消息
        setState(() {
          messages.add({
            'fromMe': senderId == myUserId,
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
    double oldScrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    double oldMaxExtent = _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0.0;

    _offset += _pageSize;
    await _loadPage(_offset, oldScrollOffset: oldScrollOffset, oldMaxExtent: oldMaxExtent);

    setState(() => _loadingMore = false);
  }

  Future<void> _loadPage(int offset, {bool scrollToBottom = false, double? oldScrollOffset, double? oldMaxExtent}) async {
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
            records?.map((msg) {
              return {
                'fromMe': msg.senderId == myUserId,
                'text': msg.content,
                'createdAt': msg.createdAt,
                'sendStatus': MessageSendStatus.success,
                'localId': msg.id?.toString() ?? _uuid.v4(),
                'messageId': msg.id,
              };
            }).toList();

        if (scrollToBottom || messages.isEmpty) {
          messages.addAll(newMsgList ?? []);
        } else {
          messages.insertAll(0, newMsgList ?? []);
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


  void _onMessageSent(Map<String, dynamic> message, bool success, String? error) {
    if (success) {
      _updateMessageStatus(message['localId'], MessageSendStatus.success);
      if (_messageDatabase != null && message['messageId'] != null) {
        MessageDatabase.markAsSent(
          _messageDatabase!, message['messageId']
        );
      }
    } else {
      _updateMessageStatus(message['localId'], MessageSendStatus.failed);
      if (error != null) {
        ToastUtils.showToast('发送失败: $error');
      }
    }
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
    _messageQueue.dispose();
    _messageDatabase?.close();
    _socketService.socket.off('newMessage', _onNewMessage);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatSession.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() { selectedMessageLocalId = null; });
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

                          return _buildMessageItem(msg, isMe, myUser);
                        },
                      ),
            ),
            _buildMessageInput(),
          ],
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
        if (info.visibleFraction > 0.5 &&
            messageId != null &&
            !_readMessageIds.contains(messageId)) {
          _readMessageIds.add(messageId);
          await markMessageReadApi(messageId); // ✅ 调用已读 API
        }
      },
      child: FastLongPressDetector(
        duration: const Duration(milliseconds: 200),
        onLongPress: () {
          setState(() {
            selectedMessageLocalId = localId;
          });
        },
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                    child: Column(
                      crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                          child: Text(text, style: const TextStyle(fontSize: 15)),
                        ),
                        if (msg['createdAt'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                            child: Text(
                              _formatTime(msg['createdAt']),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isMe) const SizedBox(width: 8),
                  if (isMe) _buildAvatar(avatarUrl),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: (selectedMessageLocalId != null && selectedMessageLocalId == localId)
                  ? _buildMessageMenu(msg, isMe)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
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

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final DateTime messageTime = DateTime.parse(timeStr).toLocal();
      return DateFormat('HH:mm').format(messageTime);
    } catch (e) {
      return '';
    }
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
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
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

  Widget _buildMenuIcon({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        onTap();
        setState(() { selectedMessageLocalId = null; });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: Colors.pink),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  void _deleteMessage(String localId) {
    setState(() {
      messages.removeWhere((m) => m['localId'] == localId);
    });
  }

  void _recallMessage(String localId) async {
    // 这里可调用撤回API，演示直接本地移除
    setState(() {
      messages.removeWhere((m) => m['localId'] == localId);
    });
    // TODO: 如有撤回API，调用后再移除
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('消息已撤回')),
    );
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
    _queue.addAll(messages.where((m) => m['sendStatus'] == MessageSendStatus.failed));
  }

  void addMessage(Map<String, dynamic> message, Future<bool> Function(Map<String, dynamic>) sender) {
    _queue.add(message);
    if (!_isSending) {
      _startProcessing(sender);
    }
  }

  void retryMessage(Map<String, dynamic> message, Future<bool> Function(Map<String, dynamic>) sender) {
    final localId = message['localId'];
    _queue.removeWhere((m) => m['localId'] == localId);
    _processing.removeWhere((m) => m['localId'] == localId);
    _retryCounts.remove(localId);
    addMessage(message, sender);
  }

  Future<void> _startProcessing(Future<bool> Function(Map<String, dynamic>) sender) async {
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
          if (retryCount >= 5) { // 最大重试5次
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

  void dispose() {
    _queue.clear();
    _processing.clear();
  }
}

