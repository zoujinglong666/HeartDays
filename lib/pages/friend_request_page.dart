import 'package:flutter/material.dart';
import 'package:heart_days/apis/friends.dart';
import 'package:heart_days/pages/add_friend_page.dart';
import 'package:heart_days/components/AnimatedCardWrapper.dart';

class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  List<FriendRequestVO> friendRequests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  Future<void> handleAction(int id, String action) async {
    try {
      final res = await friendsRespondStatusApi({
        "requestId": id,
        "action": action,
      });
      if (res.code == 200) {
        _loadFriendRequests();
      } else {
        // Handle error
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${res.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后重试')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final res = await listFriendsRequestApi();
      if (res.data != null) {
        setState(() {
          friendRequests = res.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '数据加载失败';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '网络错误，请检查网络连接';
      });
    }
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';

    try {
      final DateTime now = DateTime.now();
      final DateTime messageTime = time.toLocal();
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
        return '${messageTime.year}/${messageTime.month.toString().padLeft(2, '0')}/${messageTime.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('好友申请'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFriendPage()),
              );
            },
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF07C160)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFriendRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07C160),
                foregroundColor: Colors.white,
              ),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (friendRequests.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.separated(
      itemCount: friendRequests.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        return AnimatedCardWrapper(
          delay: Duration(milliseconds: 100 * index),
          child: _buildRequestItem(friendRequests[index]),
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '暂无好友申请',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
          // ElevatedButton.icon(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const AddFriendPage()),
          //     );
          //   },
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: const Color(0xFF07C160),
          //     foregroundColor: Colors.white,
          //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(30),
          //     ),
          //   ),
          //   icon: const Icon(Icons.person_add, size: 20),
          //   label: const Text('添加好友'),
          // ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(FriendRequestVO r) {
    final fromUser = r.fromUser;
    final fromUserAvatar = fromUser.avatar ?? '';
    
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundImage:
              fromUserAvatar.isNotEmpty
                  ? NetworkImage(fromUserAvatar)
                  : null,
          child:
              fromUserAvatar.isEmpty
                  ? const Icon(Icons.person_outline, size: 24)
                  : null,
        ),
        title: Text(
          fromUser.name ?? '',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '账号: ${fromUser.userAccount}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              '申请时间: ${_formatTime(r.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (r.status == 'accepted')
              const Text(
                '已同意',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (r.status == 'rejected')
              const Text(
                '已拒绝',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing:
            r.status == 'pending'
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => handleAction(r.id, 'accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF07C160),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('同意'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => handleAction(r.id, 'reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('拒绝'),
                    ),
                  ],
                )
                : null,
      ),
    );
  }
}
