import 'package:flutter/material.dart';
import 'package:heart_days/apis/friends.dart';
import 'package:heart_days/pages/friend_detail_page.dart';

class FriendListPage extends StatefulWidget {
  const FriendListPage({super.key});

  @override
  State<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends State<FriendListPage> {
  List<FriendVO> friends = [];
  String searchText = '';
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final res = await getFriendListApi();
    if (!res.success) {
      return;
    }

    final data = res.data!;
    setState(() {
      friends = data;
    });
  }


  void _onSearch(String value) {
    setState(() {
      searchText = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<FriendVO> filtered;
    if (searchText.isEmpty) {
      filtered = friends;
    } else {
      filtered = friends
                .where(
                  (f) =>
                      (f.name).toLowerCase().contains(
                        searchText.toLowerCase(),
                      ) ||
                      (f.userAccount).toLowerCase().contains(
                        searchText.toLowerCase(),
                      ),
                )
                .toList();
    }
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      body: Column(
        children: [
          // 搜索栏
          Container(
            color: const Color(0xFFEDEDED),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: '搜索',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                ),
                onChanged: _onSearch,
              ),
            ),
          ),
          
          // 好友列表
          Expanded(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final f = filtered[index];
                  final avatar = f.avatar;
                  final isLastItem = index == filtered.length - 1;
                  
                  return Container(
                    color: Colors.white,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FriendDetailPage(friend: f),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          decoration: BoxDecoration(
                            border: isLastItem
                                ? null
                                : Border(
                                    bottom: BorderSide(
                                      color: const Color(0xFFE5E5E5),
                                      width: 0.5,
                                    ),
                                  ),
                          ),
                          child: Row(
                            children: [
                              // 头像
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: const Color(0xFFF0F0F0),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: avatar.isNotEmpty
                                      ? Image.network(
                                          avatar,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: const Color(0xFFF0F0F0),
                                              child: Icon(
                                                Icons.person,
                                                size: 26,
                                                color: Colors.grey[500],
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          color: const Color(0xFFF0F0F0),
                                          child: Icon(
                                            Icons.person,
                                            size: 26,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                ),
                              ),
                              
                              const SizedBox(width: 12),
                              
                              // 用户信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      f.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black87,
                                        height: 1.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

