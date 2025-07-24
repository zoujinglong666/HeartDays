import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:heart_days/apis/chat.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/components/AnimatedCardWrapper.dart';
import 'package:heart_days/components/Clickable.dart';
import 'package:heart_days/pages/chat_detail_page.dart';
import 'package:heart_days/provider/get_login_userinfo.dart';

class FriendDetailPage extends StatelessWidget {
  final UserVO friend;

  const FriendDetailPage({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    final avatar = friend.avatar ?? '';
    final name = friend.name ?? '';
    final userAccount = friend.userAccount ?? '';
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
                    tag: 'avatar_${friend.id}',
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
                        child: avatar.isEmpty
                            ? Icon(Icons.person_outline, size: 60, color: Colors.grey[300])
                            : null,
                        backgroundColor: Colors.grey[100],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 用户信息卡片
            AnimatedCardWrapper(
              duration: const Duration(milliseconds: 300),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoItem('昵称', name, primaryColor),
                    Divider(height: 24, thickness: 1, color: Colors.grey[100]),
                    _buildInfoItem('账号', userAccount, primaryColor),
                    Divider(height: 24, thickness: 1, color: Colors.grey[100]),
                    _buildInfoItem('备注', '暂无备注', primaryColor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 功能按钮区域
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildFunctionItem(
                    icon: Icons.message,
                    iconColor: Colors.white,
                    title: '发消息',
                    backgroundColor: primaryColor,
                    onTap: () async {
                      // 保留原有的发消息逻辑
                      final userId = await LoginUserInfo().getUserId();
                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('用户未登录'))
                        );
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
                              builder: (context) => ChatDetailPage(
                                chatSession: chatSessionItem,
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        print(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('发生错误: $e'))
                        );
                      }
                    },
                  ),
                  Divider(height: 1, indent: 72, color: Colors.grey[100]),
                  _buildFunctionItem(
                    icon: Icons.videocam,
                    iconColor: Colors.white,
                    title: '视频聊天',
                    backgroundColor: Colors.blue,
                    onTap: () {},
                  ),
                  Divider(height: 1, indent: 72, color: Colors.grey[100]),
                  _buildFunctionItem(
                    icon: Icons.phone,
                    iconColor: Colors.white,
                    title: '语音通话',
                    backgroundColor: Colors.green,
                    onTap: () {},
                  ),
                  Divider(height: 1, indent: 72, color: Colors.grey[100]),
                  _buildFunctionItem(
                    icon: Icons.edit,
                    iconColor: Colors.white,
                    title: '添加备注',
                    backgroundColor: Colors.orange,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建信息项
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

  // 构建功能项
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

  // 显示头像预览 - 保留原有的头像预览逻辑
  void _showAvatarPreview(BuildContext context, String avatarUrl) {
    // 保留原有的头像预览实现
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
