import 'dart:async';

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
  // 备注编辑相关
  final TextEditingController _remarkController = TextEditingController();
  final FocusNode _remarkFocus = FocusNode();
  bool _editingRemark = false;
  String? _editStartValue;
  Timer? _debounceTimer;
  DateTime? _lastSaveAt;
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  static const Duration _throttleInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    // 初始备注为好友备注或昵称
    final initialRemark = widget.friend.friendNickname?.isNotEmpty == true
        ? widget.friend.friendNickname!
        : (widget.friend.name ?? '');
    _remarkController.text = initialRemark;
    _editStartValue = initialRemark;
  }
  @override
  Widget build(BuildContext context) {
    final avatar = widget.friend.avatar ?? '';
    final name = widget.friend.name ?? '';
    final userAccount = widget.friend.userAccount ?? '';
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
                    _buildRemarkItem(primaryColor),
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

  Widget _buildRemarkItem(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标签行
        Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                '备注',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(width: 16),
            // 展示或编辑区域
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _editingRemark = true;
                    _editStartValue = _remarkController.text.trim();
                  });
                  Future.delayed(const Duration(milliseconds: 50), () {
                    _remarkFocus.requestFocus();
                  });
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _editingRemark
                      ? Container(
                    key: const ValueKey('remark_editing'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _remarkController,
                      focusNode: _remarkFocus,
                      maxLines: 2,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: '输入备注，自动保存',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      onChanged: (val) {
                        _scheduleDebouncedSave(val);
                      },
                      onEditingComplete: () {
                        final newVal = _remarkController.text.trim();
                        if (_editStartValue != null &&
                            newVal == _editStartValue) {
                          _debounceTimer?.cancel();
                        } else {
                          _commitRemark(newVal);
                        }
                        setState(() {
                          _editingRemark = false;
                        });
                      },
                      onSubmitted: (_) {
                        final newVal = _remarkController.text.trim();
                        if (_editStartValue != null &&
                            newVal == _editStartValue) {
                          _debounceTimer?.cancel();
                        } else {
                          _commitRemark(newVal);
                        }
                        setState(() {
                          _editingRemark = false;
                        });
                      },
                      onTapOutside: (_) {
                        final newVal = _remarkController.text.trim();
                        if (_editStartValue != null &&
                            newVal == _editStartValue) {
                          _debounceTimer?.cancel();
                        } else {
                          _commitRemark(newVal);
                        }
                        setState(() {
                          _editingRemark = false;
                        });
                      },
                    ),
                  )
                      : Container(
                    key: const ValueKey('remark_view'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _remarkController.text.isNotEmpty
                                ? _remarkController.text
                                : (widget.friend.name ?? ''),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _editingRemark = true;
                              _editStartValue = _remarkController.text.trim();
                            });
                            Future.delayed(
                                const Duration(milliseconds: 50), () {
                              _remarkFocus.requestFocus();
                            });
                          },
                          child: const Text('编辑'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // 提示说明
        Padding(
          padding: const EdgeInsets.only(left: 76, top: 4),
          child: Text(
            '备注在会话和联系人中优先显示，长文本自动折叠',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  void _scheduleDebouncedSave(String val) {
    final trimmed = val.trim();
    // 若文本未变化，直接取消防抖并退出
    if (_editStartValue != null && trimmed == _editStartValue) {
      _debounceTimer?.cancel();
      return;
    }
    // 取消上一次防抖定时器
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _commitRemark(trimmed);
    });
  }

  Future<void> _commitRemark(String val) async {
    final trimmed = val.trim();
    // 与当前已保存值相同，或为空：不请求
    final currentSaved = (widget.friend.friendNickname
        ?.trim()
        .isNotEmpty == true)
        ? widget.friend.friendNickname!.trim()
        : (widget.friend.name ?? '').trim();
    if (trimmed.isEmpty || trimmed == currentSaved) {
      return;
    }

    final now = DateTime.now();
    // 节流：2s内最多一次
    if (_lastSaveAt != null) {
      final diff = now.difference(_lastSaveAt!);
      if (diff < _throttleInterval) {
        return;
      }
    }
    _lastSaveAt = now;
    final res = await settingFriendNickNameApi({
      "friendId": widget.friend.id,
      "friendNickname": trimmed,
    });
    if (res.success) {
      // 更新本地显示
      setState(() {
        _remarkController.text = trimmed;
        widget.friend.friendNickname = trimmed;
        _editStartValue = trimmed;
      });
      ToastUtils.showToast('备注已保存');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _remarkController.dispose();
    _remarkFocus.dispose();
    super.dispose();
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