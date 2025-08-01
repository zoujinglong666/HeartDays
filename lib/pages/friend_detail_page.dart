import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/chat.dart';
import 'package:heart_days/apis/friends.dart';
import 'package:heart_days/components/AnimatedCardWrapper.dart';
import 'package:heart_days/components/Clickable.dart';
import 'package:heart_days/pages/chat_detail_page.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/utils/ToastUtils.dart';

class FriendDetailPage extends ConsumerStatefulWidget {
  final FriendVO friend;
// ❌ 原来是 const，不能配合可变状态变量
// const FriendDetailPage({super.key, required this.friend});
// ✅ 改为非 const 构造函数
  // <-- 移到这里作为成员变量
  const FriendDetailPage({super.key, required this.friend});
  @override
  ConsumerState<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends ConsumerState<FriendDetailPage> {
  @override
  Widget build(BuildContext context) {
    final avatar = widget.friend.avatar ?? '';
    final name = widget.friend.name ?? '';
    final userAccount = widget.friend.userAccount ?? '';
    final displayName =
    widget.friend.friendNickname?.isNotEmpty == true
        ? widget.friend.friendNickname!
        : widget.friend.name;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 头像区域 - 增加点击预览功能
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              color: Colors.white,
              child: Center(
                child: GestureDetector(
                  onTap: () => _showAvatarPreview(context, avatar),
                  child: Hero(
                    tag: 'avatar_${widget.friend.id}',
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                        backgroundColor: Colors.grey[100],
                        child: avatar.isEmpty
                            ? Icon(Icons.person_outline, size: 60, color: Colors.grey[300])
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 用户信息卡片
            AnimatedCardWrapper(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('昵称', name, primaryColor),
                    Divider(height: 24, thickness: 1, color: Colors.grey[100]),
                  _buildInfoItem('账号', userAccount, primaryColor),
                    Divider(height: 24, thickness: 1, color: Colors.grey[100]),
              _buildInfoItem('备注', displayName, primaryColor),
                ]
            ),
              ),
            ),

            const SizedBox(height: 16),
            AnimatedCardWrapper(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildFunctionItem(
                      icon: Icons.message,
                      iconColor: Colors.white,
                      title: '发消息',
                      backgroundColor: primaryColor,
                      onTap: () async {

                        final authState = ref.read(authProvider);
                        final user = authState.user;
                        try {
                          final res = await createChatSession({
                            "type": "single",
                            "name": widget.friend.name,
                            "userIds": [widget.friend.id, user?.id],
                          });

                          if (res.success && res.data != null) {
                            final response = await listChatSession({
                              "page": "1",
                              "pageSize": "100",
                            });

                            List<ChatSession> chatSessions = response.data!
                                .records;
                            final chatSessionItem = chatSessions.firstWhere(
                                  (item) => item.sessionId == res.data?.id,
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChatDetailPage(
                                      chatSession: chatSessionItem,
                                    ),
                              ),
                            );
                          }
                        } catch (e) {
                          print(e);
                        }
                      },
                    ),
                    Divider(height: 0.5, indent: 72, color: Colors.grey[100]),
                    _buildFunctionItem(
                      icon: Icons.edit,
                      iconColor: Colors.white,
                      title: '添加备注',
                      backgroundColor: Colors.orange,
                      onTap: () {
                        _showRemarkDialog(context); // 👈 添加这个方法
                      },
                    ),
                  ],
                ),
              ),
            ),
            // 功能按钮区域

          ],
        ),
      ),
    );
  }

  void _showRemarkDialog(BuildContext context) {
    final TextEditingController remarkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加备注'),
          content: TextField(
            controller: remarkController,
            decoration: const InputDecoration(
              hintText: '请输入备注',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final remark = remarkController.text.trim();
                if (remark.isNotEmpty) {
                  // 你可以在这里调用接口或更新备注字段
                  final res= await settingFriendNickNameApi({
                    "friendId": widget.friend.id,
                    "friendNickname": remark,
                  });
                  if(res.success){
                    ToastUtils.showToast('修改成功');

                  }
                  Navigator.of(context).pop();
                }
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value, Color primaryColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[900],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFunctionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Clickable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

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
                tag: 'avatar_${widget.friend.id}',
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