import 'package:flutter/material.dart';
import 'package:heart_days/apis/chat.dart';
import 'package:heart_days/apis/friends.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/pages/chat_detail_page.dart';
import 'package:heart_days/pages/friend_detail_page.dart';
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

