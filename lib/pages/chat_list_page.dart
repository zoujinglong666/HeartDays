import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/chat.dart';
import 'package:heart_days/components/com_container.dart';
import 'package:heart_days/components/com_popup_menu.dart';
import 'package:heart_days/pages/add_friend_page.dart';
import 'package:heart_days/pages/chat_detail_page.dart';
import 'package:heart_days/pages/friend_list_page.dart';
import 'package:heart_days/pages/friend_request_page.dart';
import 'package:heart_days/pages/create_group_chat_page.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/services/ChatSocketService.dart';
import 'package:heart_days/utils/date_utils.dart';

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage> {
  final ComPopupMenuController _controller = ComPopupMenuController();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFEDEDED),
          foregroundColor: Colors.black,
          title: const Text('微聊'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ComPopupMenu(
                controller: _controller, // ✅ 必须传入 controller 才能控制菜单
                pressType: PressType.singleClick,
                menuBuilder: _buildBasicMenu(),
                child: const Icon(Icons.add, size: 24),
              ),
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


  Widget _buildBasicMenu() {
    return ComContainer(
      padding: EdgeInsets.zero,
      width: 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(Icons.home, '添加好友'),
          _buildMenuItem(Icons.group, '创建群聊'),
          _buildMenuItem(Icons.settings, '好友申请'),
        ],
      ),
    );
  }

Widget _buildMenuItem(IconData icon, String text, {Color? color}) {
  return ListTile(
    leading: Icon(icon, color: color),
    title: Text(text, style: TextStyle(color: color)),
    onTap: () {
      // 先隐藏菜单
      // 点击菜单项后立即关闭菜单
      _controller.hideMenu();
      // 使用addPostFrameCallback确保菜单关闭后再导航
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (text == '添加好友') {
          _controller.hideMenu();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddFriendPage()),
          );
        }
        if (text == '好友申请') {
          _controller.hideMenu();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FriendRequestPage()),
          );
        }
        if (text == '创建群聊') {
          _controller.hideMenu();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateGroupChatPage()),
          );
        }
      });
    },
  );
}

}


class ChatListTab extends ConsumerStatefulWidget {
  const ChatListTab({super.key});

  @override
  ConsumerState<ChatListTab> createState() => _ChatListTabState();
}

class _ChatListTabState extends ConsumerState<ChatListTab> {
  List<ChatSession> chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChats();
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
                HapticFeedback.heavyImpact();
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
                      formatMsgTime(chat.lastMessage?.createdAt),
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
                onTap: () async {
                  if (chat.sessionId.isEmpty) return;
                  ChatSocketService().joinSession(chat.sessionId);
                  final needRefresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailPage(chatSession: chat),
                    ),
                  );
                  if (needRefresh == true) {
                    await fetchChats();
                  }
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

    final double menuWidth = 160;
    final double menuHeight = 200;

    final double leftRaw = (screenSize.width - tapPosition.dx) < menuWidth
        ? screenSize.width - menuWidth - 8.0
        : tapPosition.dx;

// 只对右边界限制，左边界允许更小，不用clamp左边最小8了
    final double left = leftRaw > 0 ? leftRaw : tapPosition.dx;

    final double topRaw = (screenSize.height - tapPosition.dy) < menuHeight
        ? tapPosition.dy - menuHeight
        : tapPosition.dy;

// 仍然限制上下不超屏幕
    final double top = topRaw.clamp(8.0, screenSize.height - menuHeight - 8.0);


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
