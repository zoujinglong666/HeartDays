import 'package:flutter/material.dart';
import 'package:heart_days/apis/chat.dart';
import 'package:heart_days/pages/add_friend_page.dart';
import 'package:heart_days/pages/chat_detail_page.dart';
import 'package:heart_days/pages/friend_list_page.dart';
import 'package:heart_days/pages/friend_request_page.dart';
import 'package:heart_days/provider/get_login_userinfo.dart';
import 'package:heart_days/services/ChatSocketService.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFEDEDED),
          foregroundColor: Colors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.add, size: 24),
              onPressed: () {
                // 跳转到添加好友页面
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddFriendPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.request_page, size: 24),
              onPressed: () {
                // 跳转到好友申请页面
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FriendRequestPage()),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFF07C160),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF07C160),
            tabs: [
              Tab(text: '聊天', icon: Icon(Icons.chat_bubble_outline)),
              Tab(text: '通讯录', icon: Icon(Icons.contacts_outlined)),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFEDEDED),
        body: const TabBarView(children: [ChatListTab(), FriendListPage()]),
      ),
    );
  }
}

class ChatListTab extends StatefulWidget {
  const ChatListTab({super.key});

  @override
  State<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends State<ChatListTab> {
  List<ChatSession> chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    fetchChats();
  }
  
  void _connectSocket() async {
    // 获取用户信息并连接WebSocket
    final loginState = await LoginUserInfo().getLoginState();
    
    if (loginState.token != null && loginState.userId != null) {
      final socketService = ChatSocketService();
      socketService.connect(loginState.token!, loginState.userId!);
      
      // 注册事件回调
      socketService.setOnNewMessage(_onNewMessage);
      socketService.setOnFriendRequest(_onFriendRequest);
      socketService.setOnOnlineStatus(_onOnlineStatus);
    }
  }
  
  // 处理新消息
  void _onNewMessage(dynamic data) {



    // print('收到新消息: $data');
    // 可以更新聊天列表或显示通知
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

  Future<void> fetchChats() async {
    setState(() {
      _isLoading = true;
    });

    final res = await listChatSession({"page": "1", "pageSize": "20"});
    try {
      if (res.code == 200) {
        setState(() {
          chats = res.data!.records;
          _isLoading = false;
        });
      } else {
        setState(() {
          chats = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        chats = [];
        _isLoading = false;
      });
    }
  }

  // 格式化时间显示
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';

    try {
      final DateTime now = DateTime.now();
      final DateTime messageTime = DateTime.parse(timeStr);
      final Duration difference = now.difference(messageTime);

      // 今天内的消息显示时间
      if (difference.inDays == 0) {
        return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
      }
      // 昨天的消息
      else if (difference.inDays == 1) {
        return '昨天';
      }
      // 一周内的消息
      else if (difference.inDays < 7) {
        const List<String> weekdays = [
          '周一',
          '周二',
          '周三',
          '周四',
          '周五',
          '周六',
          '周日',
        ];
        // 注意：DateTime中的weekday是1-7，其中7代表周日
        int weekdayIndex = messageTime.weekday - 1;
        return weekdays[weekdayIndex];
      }
      // 更早的消息
      else {
        return '${messageTime.month}月${messageTime.day}日';
      }
    } catch (e) {
      return timeStr;
    }
  }

  void _navigateToFriendList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FriendListPage()),
    ).then((_) {
      // 从好友列表返回后刷新聊天列表
      fetchChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF07C160)),
        )
        : chats.isEmpty
        ? _buildEmptyView()
        : _buildChatList();
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无聊天记录',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _navigateToFriendList,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF07C160),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('添加好友开始聊天'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return RefreshIndicator(
      color: const Color(0xFF07C160),
      onRefresh: fetchChats,
      child: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          return _buildChatItem(chat, index);
        },
      ),
    );
  }

  Widget _buildChatItem(ChatSession chat, int index) {
    final isLastItem = index == chats.length - 1;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: GestureDetector(
              onLongPressStart: (LongPressStartDetails details) {
                _showActionMenu(context, chat, details.globalPosition);
              },
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: chat.avatar != null && chat.avatar!.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          chat.avatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(
                            Icons.person,
                            size: 28,
                            color: Colors.grey,
                          ),
                        ),
                      )
                          : const Icon(
                        Icons.person,
                        size: 28,
                        color: Colors.grey,
                      ),
                    ),
                    if (chat.unreadCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              chat.unreadCount > 99
                                  ? '99+'
                                  : chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (chat.isMuted)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.volume_off,
                            size: 8,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(chat.lastMessage?.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      if (chat.isPinned)
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: const Text(
                            '置顶',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          chat.lastMessage?.content ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: chat.isMuted
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  if (chat.sessionId.isEmpty) return;
                  ChatSocketService().joinSession(chat.sessionId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailPage(chatSession: chat),
                    ),
                  );
                },
              ),
            ),
          ),
          if (!isLastItem)
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 76,
              endIndent: 0,
              color: Colors.grey[300],
            ),
        ],
      ),
    );
  }



  void _showActionMenu(
      BuildContext context,
      ChatSession chat,
      Offset tapPosition,
      ) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Size screenSize = overlay.size;

    final double menuWidth = 220;
    final double menuHeight = 200;

    final double left = (screenSize.width - tapPosition.dx) < menuWidth
        ? screenSize.width - menuWidth - 8.0
        : tapPosition.dx;

    final double top = (screenSize.height - tapPosition.dy) < menuHeight
        ? tapPosition.dy - menuHeight
        : tapPosition.dy;

    showGeneralDialog(
      context: context,
      barrierLabel: 'Menu',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Stack(
          children: [
            Positioned(
              left: left.clamp(8.0, screenSize.width - menuWidth - 8.0),
              top: top.clamp(8.0, screenSize.height - menuHeight - 8.0),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  alignment: Alignment.topLeft,
                  child: Material(
                    color: Colors.white,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: menuWidth),
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAnimatedMenuItem(
                              icon: Icons.push_pin_outlined,
                              text: chat.isPinned ? '取消置顶' : '置顶聊天',
                              onTap: () {
                                Navigator.pop(context);
                                // 置顶逻辑
                              },
                            ),
                            _buildAnimatedMenuItem(
                              icon: Icons.mark_chat_read_outlined,
                              text: '标为已读',
                              onTap: () {
                                Navigator.pop(context);
                                // 标为已读逻辑
                              },
                            ),
                            _buildAnimatedMenuItem(
                              icon: chat.isMuted ? Icons.volume_up : Icons.volume_off,
                              text: chat.isMuted ? '取消静音' : '静音',
                              onTap: () {
                                Navigator.pop(context);
                                // 静音逻辑
                              },
                            ),
                            _buildAnimatedMenuItem(
                              icon: Icons.delete_outline,
                              text: '删除',
                              iconColor: Colors.red,
                              textColor: Colors.red,
                              onTap: () {
                                Navigator.pop(context);
                                // 删除逻辑
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  Widget _buildAnimatedMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
    Color textColor = Colors.black,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标区域固定宽度，保证对齐
              SizedBox(
                width: 24, // 可根据实际图标大小调整
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 16),
              // 文字自动占满剩余空间
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
