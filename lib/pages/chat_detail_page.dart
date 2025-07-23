import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:heart_days/apis/chat.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/provider/get_login_userinfo.dart';
import 'package:heart_days/services/ChatSocketService.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

enum MessageSendStatus { sending, success, failed }

class ChatDetailPage extends StatefulWidget {
  final ChatSession chatSession;

  const ChatDetailPage({super.key, required this.chatSession});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
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

  @override
  void initState() {
    super.initState();
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
  }

  Future<void> _getUserInfo() async {
    String? userId = await LoginUserInfo().getUserId();
    String? token = await LoginUserInfo().getToken();
    User user = await LoginUserInfo().getUser() as User;
    setState(() {
      myUserId = userId!;
      myUser = user;
      myToken = token!;
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
      // 优先查找本地发送的消息（fromMe==true, text相同, 状态为sending）
      int idx = messages.indexWhere((m) =>
        m['fromMe'] == true &&
        m['text'] == content &&
        m['sendStatus'] == MessageSendStatus.sending
      );
      if (idx != -1) {
        // 找到本地消息，更新状态和createdAt
        setState(() {
          messages[idx]['sendStatus'] = MessageSendStatus.success;
          messages[idx]['createdAt'] = createdAt;
          messages[idx]['messageId'] = messageId;
        });
      } else {
        // 没有本地消息，说明是别人发的，直接插入
        setState(() {
          messages.add({
            'fromMe': senderId == myUserId,
            'text': content,
            'createdAt': createdAt,
            'sendStatus': MessageSendStatus.success,
            'localId': messageId?.toString() ?? _uuid.v4(),
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
        final newMsgs =
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
          messages.addAll(newMsgs ?? []);
        } else {
          messages.insertAll(0, newMsgs ?? []);
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
    setState(() {
      messages.add({
        'fromMe': true,
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
        'sendStatus': MessageSendStatus.sending,
        'localId': localId,
        'messageId': null,
      });
      _controller.clear();
    });
    _scrollToBottom();
    try {
      if (!_socketService.isConnected) {
        throw Exception('Socket disconnected');
      }
      _socketService.sendMessage(
        sessionId: widget.chatSession.sessionId,
        content: text,
      );
      // 不在这里直接设为success，等socket回包
    } catch (e) {
      print('消息发送失败: $e');
      setState(() {
        int idx = messages.indexWhere((m) => m['localId'] == localId);
        if (idx != -1) {
          messages[idx]['sendStatus'] = MessageSendStatus.failed;
        }
      });
    }
  }

  // 重试发送（失败时点击重试）
  void _retrySend(String localId) {
    int idx = messages.indexWhere((m) => m['localId'] == localId);
    if (idx == -1) return;
    final text = messages[idx]['text'];
    setState(() {
      messages[idx]['sendStatus'] = MessageSendStatus.sending;
    });
    try {
      if (!_socketService.isConnected) {
        throw Exception('Socket disconnected');
      }
      _socketService.sendMessage(
        sessionId: widget.chatSession.sessionId,
        content: text,
      );
      // 等socket回包再设为success
    } catch (e) {
      print('重试发送失败: $e');
      setState(() {
        messages[idx]['sendStatus'] = MessageSendStatus.failed;
      });
    }
  }

  @override
  void dispose() {
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
                        Stack(
                          children: [
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
                            if (isMe && sendStatus == MessageSendStatus.sending)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            if (isMe && sendStatus == MessageSendStatus.failed)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: GestureDetector(
                                  onTap: () => _retrySend(localId),
                                  child: const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
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

class FastLongPressDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onLongPress;
  final Duration duration;

  const FastLongPressDetector({
    super.key,
    required this.child,
    required this.onLongPress,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        _FastLongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<_FastLongPressGestureRecognizer>(
          () => _FastLongPressGestureRecognizer(duration: duration),
          (_FastLongPressGestureRecognizer instance) {
            instance.onLongPress = onLongPress;
          },
        ),
      },
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _FastLongPressGestureRecognizer extends LongPressGestureRecognizer {
  _FastLongPressGestureRecognizer({required Duration duration})
      : super(duration: duration);
}
