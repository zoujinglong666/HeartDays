import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/painting.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool notificationEnabled = true;
  int _cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard([
            _buildSwitchTile(
              icon: Icons.notifications_active_outlined,
              label: '开启纪念日提醒',
              value: notificationEnabled,
              onChanged: (v) => setState(() => notificationEnabled = v),
            ),
          ]),

          const SizedBox(height: 20),

          _buildSectionCard([
            _buildTile(
              icon: Icons.info_outline,
              label: '清除缓存',
              onTap: () async {
                await _clearAllCache(context);
                await _loadCacheSize();
              },
              trailing: Text(
                _cacheSize > 0
                  ? '${(_cacheSize / 1024 / 1024).toStringAsFixed(1)} MB'
                  : '0 MB',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            _buildTile(
              icon: Icons.logout,
              label: '退出登录',
              color: Colors.redAccent,
              onTap: () {
                _confirmLogout(context);
              },
            ),
          ]),

          const SizedBox(height: 30),
          Center(
            child: Text(
              '版本号 v1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 卡片区域容器
  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(
          children.length,
          (index) => Column(
            children: [
              children[index],
              if (index != children.length - 1)
                Divider(
                  height: 1,
                  indent: 60,
                  endIndent: 16,
                  color: Colors.grey.shade200,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 普通设置项
  Widget _buildTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
  }) {
    final iconColor = color ?? const Color(0xFF5C6BC0);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildIcon(icon, iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing,
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // 开关设置项
  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildIcon(icon, const Color(0xFF5C6BC0)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5C6BC0),
          ),
        ],
      ),
    );
  }

  // 图标块
  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  // 退出确认弹窗
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('确认退出登录？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  await userLogoutApi();
                  await ref.read(authProvider.notifier).logout();
                  // 退出登录，清除导航栈并跳转到登录页面
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false, // 清除所有路由
                  );
                },
                child: const Text(
                  '确定',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ToastUtils.showToast(message);
  }

  Future<int> getCacheSize() async {
    int total = 0;
    final tempDir = await getTemporaryDirectory();
    total += await _getFolderSize(tempDir);
    return total;
  }

  Future<int> _getFolderSize(Directory dir) async {
    int size = 0;
    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (_) {}
    return size;
  }

  Future<void> _clearAllCache(BuildContext context) async {
    try {
      // 清理图片缓存
      await CachedNetworkImage.evictFromCache('');
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 清理临时文件夹
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('缓存已清除')),
        );
      }
      // 清理后刷新显示
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清除缓存失败: $e')),
        );
      }
    }
  }

  Future<void> _loadCacheSize() async {
    final size = await getCacheSize();
    setState(() {
      _cacheSize = size;
    });
  }
}
