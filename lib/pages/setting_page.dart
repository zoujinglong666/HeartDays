import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF5C6BC0);

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
            _buildTile(
              icon: Icons.person_outline,
              label: '修改昵称',
              onTap: () {
                _showToast(context, '跳转到修改昵称页面');
              },
            ),
            _buildTile(
              icon: Icons.image_outlined,
              label: '修改头像',
              onTap: () {
                _showToast(context, '跳转到头像设置页面');
              },
            ),
          ]),

          const SizedBox(height: 20),

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
              onTap: () {
                Navigator.pushNamed(context, '/about');
              },
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
                onPressed: () {
                  // 登录成功，跳转到主页
                  Navigator.of(context).pushReplacementNamed('/login');
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
