import 'package:flutter/material.dart';
import 'package:heart_days/apis/chat.dart';
import 'package:heart_days/apis/friends.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/pages/chat_detail_page.dart';
import 'package:heart_days/provider/get_login_userinfo.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  List<UserVO> friends = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final res = await getFriendListApi();
    setState(() {
      friends = res.data!;
    });
  }

  void _onSearch(String value) {
    setState(() {
      searchText = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<UserVO> filtered =
        searchText.isEmpty
            ? friends
            : friends
                .where(
                  (f) =>
                      (f.name ?? '').toLowerCase().contains(
                        searchText.toLowerCase(),
                      ) ||
                      (f.userAccount ?? '').toLowerCase().contains(
                        searchText.toLowerCase(),
                      ),
                )
                .toList();
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索好友昵称/账号',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 8,
                ),
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final f = filtered[index];
                final avatar = f.avatar ?? '';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child:
                        avatar.isEmpty
                            ? const Icon(Icons.person_outline)
                            : null,
                  ),
                  title: Text(f.name ?? ''),
                  subtitle: Text(
                    '账号: ${f.userAccount ?? ''}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FriendDetailPage(friend: f),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FriendDetailPage extends StatelessWidget {
  final UserVO friend;

  const FriendDetailPage({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    final avatar = friend.avatar ?? '';
    final name = friend.name ?? '';
    final userAccount = friend.userAccount ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: ListView(
        children: [
          // 头像区域 - 增加点击预览功能
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (avatar.isNotEmpty) {
                    _showAvatarPreview(context, avatar);
                  }
                },
                child: Hero(
                  tag: 'avatar_${friend.id}',
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child:
                        avatar.isEmpty
                            ? const Icon(Icons.person_outline, size: 50)
                            : null,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 用户信息区域
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoItem('昵称', name),
                const Divider(height: 24),
                _buildInfoItem('账号', userAccount),
                const Divider(height: 24),
                _buildInfoItem('备注', '暂无备注'),
              ],
            ),
          ),

          const Divider(height: 24, thickness: 8),

          // 功能按钮
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildFunctionItem(
                  icon: Icons.message,
                  iconColor: Colors.green,
                  title: '发消息',
                  onTap: () async {
                    final userId = await LoginUserInfo().getUserId();
                    if (userId == null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('用户未登录')));
                      return;
                    }
                    try {
                      final res = await createChatSession({
                        "type": "single",
                        "name": friend.name,
                        "userIds": [friend.id, userId],
                      });

                      if (res.code == 200 && res.data != null) {
                        final response = await listChatSession({
                          "page": "1",
                          "pageSize": "20",
                        });

                        List<ChatSession> chatSessions = response.data!.records;

                        final chatSessionItem = chatSessions.firstWhere(
                          (item) => item.sessionId == res.data?.id,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatDetailPage(
                                  chatSession: chatSessionItem,
                                ),
                          ),
                        );
                                            }
                    } catch (e) {
                      print(e);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('发生错误: $e')));
                    }
                  },
                ),
                const Divider(height: 1, indent: 72),
                _buildFunctionItem(
                  icon: Icons.videocam,
                  iconColor: Colors.blue,
                  title: '视频聊天',
                  onTap: () {
                    // TODO: 实现视频聊天逻辑
                  },
                ),
                const Divider(height: 1, indent: 72),
                _buildFunctionItem(
                  icon: Icons.phone,
                  iconColor: Colors.green,
                  title: '语音通话',
                  onTap: () {
                    // TODO: 实现语音通话逻辑
                  },
                ),
                const Divider(height: 1, indent: 72),
                _buildFunctionItem(
                  icon: Icons.edit,
                  iconColor: Colors.orange,
                  title: '添加备注',
                  onTap: () {
                    // TODO: 实现备注编辑
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建信息项
  Widget _buildInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // 构建功能项
  Widget _buildFunctionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  // 显示头像预览
  void _showAvatarPreview(BuildContext context, String avatarUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.black87,
          body: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: Hero(
                tag: 'avatar_${friend.id}',
                child: InteractiveViewer(
                  child: CircleAvatar(
                    radius: 120,
                    backgroundImage: NetworkImage(avatarUrl),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}
