import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class UserEditPage extends ConsumerStatefulWidget {
  const UserEditPage({super.key});

  @override
  ConsumerState<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends ConsumerState<UserEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController(); // 新增邮箱控制器
  final _avatarUrlController = TextEditingController(); // 新增头像链接控制器
  String? _selectedGender;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isInitialized = false; // 添加初始化标志
  bool _useAvatarUrl = false; // 控制是否使用链接作为头像

  // 性别选项
  final List<Map<String, String>> _genderOptions = [
    {'value': 'male', 'label': '男'},
    {'value': 'female', 'label': '女'},
    {'value': 'other', 'label': '其他'},
  ];

  // 定义与"我的"页面一致的配色方案
  static const Color primaryColor = Color(0xFF5C6BC0); // 主色调：靛蓝色
  static const Color secondaryColor = Color(0xFFF48FB1); // 次要色：粉色
  static const Color backgroundColor = Color(0xFFF8F9FA); // 背景色：浅灰色
  static const Color cardColor = Colors.white; // 卡片色：纯白色

  @override
  void initState() {
    super.initState();
    // 移除 _loadUserData() 调用
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里初始化用户数据
    if (!_isInitialized) {
      _loadUserData();
      _isInitialized = true;
    }
  }

  void _loadUserData() {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user != null) {
      _usernameController.text = user.name;
      _emailController.text = user.email; // 加载邮箱
      // 如果有性别信息，也设置性别
      // _selectedGender = user.gender; // 假设用户模型有性别字段
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose(); // 释放邮箱控制器
    _avatarUrlController.dispose(); // 释放头像链接控制器
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // 请求权限
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          _showPermissionDialog('相机权限');
          return;
        }
      } else {
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          _showPermissionDialog('相册权限');
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _useAvatarUrl = false; // 选择了本地图片，不使用链接
        });
      }
    } catch (e) {
      _showErrorDialog('选择图片失败: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: primaryColor),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: secondaryColor,
                ),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.link,
                  color: primaryColor,
                ),
                title: const Text('使用链接'),
                onTap: () {
                  Navigator.pop(context);
                  _showAvatarUrlDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 新增：显示头像链接输入对话框
  void _showAvatarUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入头像链接'),
        content: TextField(
          controller: _avatarUrlController,
          decoration: const InputDecoration(
            hintText: '请输入有效的图片URL',
            prefixIcon: Icon(Icons.link),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (_avatarUrlController.text.isNotEmpty) {
                setState(() {
                  _useAvatarUrl = true;
                  _selectedImage = null; // 清除本地图片
                });
              }
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(String permission) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: const Text('权限请求'),
        content: Text('需要$permission权限才能继续操作'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('去设置', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: const Text('错误', style: TextStyle(color: primaryColor)),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 获取当前用户
      final authNotifier = ref.read(authProvider.notifier);
      final user = authNotifier.user;

      if (user == null) {
        _showErrorDialog('用户未登录或已失效');
        return;
      }
      Map<String, dynamic> cleanUserData(User user, {required String name, required String email}) {
        final data = Map<String, dynamic>.from(user.toJson());

        // 删除后端不允许的字段
        for (final key in ['roles']) {
          data.remove(key);
        }

        // 替换名称和邮箱
        data['name'] = name;
        data['email'] = email;

        // 如果使用头像链接
        if (_useAvatarUrl && _avatarUrlController.text.isNotEmpty) {
          data['avatar'] = _avatarUrlController.text;
        }

        return data;
      }

      // 请求更新接口
      final body = cleanUserData(
        user!,
        name: _usernameController.text,
        email: _emailController.text,
      );
      final res = await updateUser(body);

      // 响应成功
      if (res.code == 200 && res.data != null) {
        // 更新本地缓存中的 user 数据
        final updatedUser = res.data!; // ✅ 已经是 User 类型
        await authNotifier.login(updatedUser, authNotifier.token!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('保存成功！'),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context, true); // 返回并标记"已保存"
        }
      } else {
        // 后端返回失败
        _showErrorDialog('保存失败: ${res.message ?? '未知错误'}');
      }
    } catch (e) {
      _showErrorDialog('保存失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = ref.read(authProvider.notifier);
    final token = authNotifier.token;
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '编辑资料',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveUserData,
            child:
            _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text(
              '保存',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 头像部分 - 宽度100%，移除渐变色
              Container(
                width: double.infinity, // 设置宽度为100%
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Stack(
                        children: [
                          // 头像容器 - 使用普通颜色
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor, // 使用普通颜色替代渐变
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: ClipOval(
                                child: _useAvatarUrl && _avatarUrlController.text.isNotEmpty
                                    ? Image.network(
                                  _avatarUrlController.text,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[100],
                                      child: const Icon(
                                        Icons.error_outline,
                                        size: 50,
                                        color: Colors.red,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                )
                                    : _selectedImage != null
                                    ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                )
                                    : Container(
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 相机图标 - 使用普通颜色
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: secondaryColor, // 使用普通颜色替代渐变
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _useAvatarUrl ? '使用链接头像' : '点击更换头像',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (_useAvatarUrl && _avatarUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '链接: ${_avatarUrlController.text.length > 20 ? '${_avatarUrlController.text.substring(0, 20)}...' : _avatarUrlController.text}',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 用户名输入 - 优化设计
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '用户名',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: '请输入用户名',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '请输入用户名';
                        }
                        if (value.trim().length < 2) {
                          return '用户名至少2个字符';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 新增：邮箱输入
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.email,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '邮箱',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: '请输入邮箱地址',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryColor),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null; // 邮箱可以为空
                        }
                        // 简单的邮箱格式验证
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return '请输入有效的邮箱地址';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 性别选择 - 使用普通颜色
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.wc,
                            color: secondaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '性别',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      children:
                      _genderOptions.map((gender) {
                        final isSelected =
                            _selectedGender == gender['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedGender = gender['value'];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                              isSelected
                                  ? primaryColor
                                  : Colors.grey[100], // 使用普通颜色替代渐变
                              borderRadius: BorderRadius.circular(20),
                              boxShadow:
                              isSelected
                                  ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                                  : null,
                            ),
                            child: Text(
                              gender['label']!,
                              style: TextStyle(
                                color:
                                isSelected
                                    ? Colors.white
                                    : Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}