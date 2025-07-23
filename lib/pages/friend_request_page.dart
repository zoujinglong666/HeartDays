import 'package:flutter/material.dart';
import 'package:heart_days/apis/friends.dart';

class FriendRequestPage extends StatefulWidget {
  const FriendRequestPage({super.key});

  @override
  State<FriendRequestPage> createState() => _FriendRequestPageState();
}

class _FriendRequestPageState extends State<FriendRequestPage> {
  List<FriendRequestVO> friendRequests = [];

  Future<void> handleAction(int id, String action) async {
    final res = await friendsRespondStatusApi({
      "requestId": id,
      "action": action,
    });
    if (res.code == 200) {
      _loadFriendRequests();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFriendRequests();
  }

  Future<void> _loadFriendRequests() async {
    final res = await listFriendsRequestApi();
    if (res.data != null) {
      setState(() {
        friendRequests = res.data!;
      });
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
      ),
      body: ListView.separated(
        itemCount: friendRequests.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final r = friendRequests[index];
          final fromUser = r.fromUser;
          final fromUserAvatar = fromUser.avatar ?? '';
          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  fromUserAvatar != null && fromUserAvatar.isNotEmpty
                      ? NetworkImage(fromUserAvatar)
                      : null,
              child:
                  (fromUserAvatar == null || fromUserAvatar.isEmpty)
                      ? const Icon(Icons.person_outline)
                      : null,
            ),
            title: Text(fromUser.name ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '账号: ${fromUser.userAccount ?? ''}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  '申请时间: ${r.createdAt ?? ''}',
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
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(48, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('同意'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => handleAction(index, 'reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(48, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('拒绝'),
                        ),
                      ],
                    )
                    : null,
          );
        },
      ),
    );
  }
}
