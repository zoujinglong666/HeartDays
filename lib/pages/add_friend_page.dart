import 'package:flutter/material.dart';
import 'package:heart_days/apis/friends.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/services/ChatSocketService.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  _AddFriendPageState createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> searchHistory = [];
  List<Map<String, String>> friends = [];
  List<UserVO> filteredFriends = [];

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
    if (value.trim().isEmpty) return;
    final res = await listUnaddedUsers({
      'page': 1,
      'size': 20,
      'keyword': value,
    });
    setState(() {
      filteredFriends = res.data!;
    });
  }

  void _onSelectHistory(String value) {
    _searchController.text = value;
    _onSearch(value);
  }

  Future<void> _addFriend(UserVO friend) async {
    // 发送好友请求给后端
    ChatSocketService().sendFriendRequest(friend.id);
    final _ = await friendsRequestApi({'friendId': friend.id});
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索朋友',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              filteredFriends = List.from(friends);
                            });
                          },
                        )
                        : null,
              ),
              onSubmitted: _onSearch,
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
                  subtitle: Text(friend.userAccount ?? ''),
                  trailing: IconButton(
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
