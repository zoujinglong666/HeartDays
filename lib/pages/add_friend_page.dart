import 'package:flutter/material.dart';
import 'package:heart_days/apis/friends.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/components/input_text/index.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> searchHistory = [];
  List<Map<String, String>> friends = [];
  List<UnaddedUserVO> filteredFriends = [];

  // 跟踪每个好友的添加状态
  final Map<String, bool> _addingStatus = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    final res = await listUnaddedUsers({'page': 1, 'size': 20});
    setState(() {
      filteredFriends = res.data!;
    });
  }

  Future<void> _onSearch(String value) async {
    final res = await listUnaddedUsers({
      'page': 1,
      'size': 20,
      if (value
          .trim()
          .isNotEmpty) 'keyword': value,
    });
    setState(() {
      filteredFriends = res.data!;
    });
  }


  void _onSelectHistory(String value) {
    _searchController.text = value;
    _onSearch(value);
  }

  Future<void> _addFriend(UnaddedUserVO friend) async {
    // 设置添加状态为正在添加
    setState(() {
      _addingStatus[friend.id] = true;
    });

    try {
      // ChatSocketService().sendFriendRequest(friend.id);
      await friendsRequestApi({'friendId': friend.id});

      // 更新好友列表以反映新状态
      await _loadData();
    } finally {
      // 无论成功还是失败，都清除添加状态
      setState(() {
        _addingStatus.remove(friend.id);
      });
    }
  }

  // 根据状态返回相应的Widget
  Widget _getStatusWidget(String status) {
    switch (status) {
      case 'pending':
        return const Text(
          '已申请',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 12,
          ),
        );
      case 'accepted':
        return const Text(
          '已接受',
          style: TextStyle(
            color: Colors.green,
            fontSize: 12,
          ),
        );
      case 'rejected':
        return const Text(
          '已拒绝',
          style: TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加朋友'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [


          Padding(
            padding: const EdgeInsets.all(12.0),
            child: InputText(
              label: "用户名",
              controller: _searchController,
              icon: const Icon(Icons.search),
              placeholder: "请输入",
              showBorder: true,
              onSubmitted: _onSearch,
              borderRadius: BorderRadius.circular(50),
            ),
          ),
          if (searchHistory.isNotEmpty)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  const Text('搜索历史:', style: TextStyle(color: Colors.grey)),
                  ...searchHistory.map(
                    (h) => ActionChip(
                      label: Text(h),
                      onPressed: () => _onSelectHistory(h),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: filteredFriends.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final friend = filteredFriends[index];
                final isAdding = _addingStatus[friend.id] ?? false;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        friend.avatar!.isNotEmpty
                            ? NetworkImage(friend.avatar!)
                            : null,
                    child:
                        friend.avatar!.isEmpty
                            ? const Icon(Icons.person_outline)
                            : null,
                  ),
                  title: Text(friend.name ?? ''),
                  subtitle: Row(
                    children: [
                      Text(friend.userAccount ?? ''),
                      if (friend.friendshipStatus.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: _getStatusWidget(friend.friendshipStatus),
                        ),
                    ],
                  ),
                  trailing: isAdding
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : (friend.friendshipStatus == 'pending' ||
                      friend.friendshipStatus == 'accepted')
                      ? const SizedBox.shrink()
                      : IconButton(
                    icon: const Icon(Icons.person_add),
                    onPressed: () {
                      // 在这里处理添加好友的逻辑
                      _addFriend(friend);
                    },
                  ),
                  onTap: () {
                    // 点击用户进入详情页
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
