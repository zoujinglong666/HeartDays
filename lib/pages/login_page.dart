import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/Consts/index.dart';
import 'package:heart_days/apis/user.dart';
import 'package:heart_days/pages/register_page.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/services/ChatSocketService.dart';
import 'package:heart_days/utils/ToastUtils.dart';
import 'package:heart_days/utils/simpleEncryptor_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_theme_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _isAgreed = false;
  late AnimationController _animationController;
  late AnimationController _tabAnimationController;
  late AnimationController _contentAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 更柔和的配色方案
  static const Color primaryColor = Color(0xFFF48FB1); // 更柔和的粉红色
  static const Color secondaryColor = Color(0xFFCE93D8); // 更柔和的紫色
  static const Color backgroundColor = Color(0xFFFEF7F9); // 更淡的粉色背景
  static const Color cardColor = Color(0xFFFFFFFF); // 纯白
  static const Color textPrimary = Color(0xFF424242); // 更柔和的深灰
  static const Color textSecondary = Color(0xFF757575); // 更柔和的中灰
  static const Color textLight = Color(0xFFBDBDBD); // 更柔和的浅灰

  @override
  void initState() {
    super.initState();
    AppThemeController().setTransparentUI();
    _loadAgreementState(); // 新增：加载本地勾选状态

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600), // 减少动画时长
      vsync: this,
    );

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300), // 减少动画时长
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400), // 减少动画时长
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut, // 使用更温和的曲线
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // 减少滑动距离
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut, // 使用更温和的曲线
      ),
    );

    _animationController.forward();
  }

  // 新增：加载本地勾选状态
  Future<void> _loadAgreementState() async {
    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('agreed_privacy_policy') ?? false;
    setState(() {
      _isAgreed = agreed;
    });
  }

  void _toggleShowConfirmPassword() {
    setState(() {
      _showConfirmPassword = !_showConfirmPassword;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneFocusNode.dispose();
    _codeFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _tabAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  void _toggleAgreement() async {
    setState(() {
      _isAgreed = !_isAgreed;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('agreed_privacy_policy', _isAgreed);
  }

  Future<void> _handleLogin() async {
    if (!_isAgreed) {
      _showToast('请先同意用户协议和隐私政策');
      return;
    }

    // 账号登录
    if (_usernameController.text.isEmpty) {
      _showToast('请输入用户名');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showToast('请输入密码');
      return;
    }

    void handleLogin() async {
  setState(() {
    _isLoading = true;
  });
  try {
    // 登录前清除旧的认证数据
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');

    final secret = Consts.password.secret;
    final encrypted = SimpleEncryptor.encryptText(
      _passwordController.text,
      secret,
    );
    final response = await userLogin({
      "userAccount": _usernameController.text,
      "password": encrypted,
    });
    if (response.code == 200) {
      final user = response.data?.user;

      if (user != null) {
        _showToast('登录成功');
        final token = response.data!.accessToken;
        final refreshToken = response.data?.refreshToken;

        // ✅ 第一步：先写状态管理（内存里最先可用）
        await ref.read(authProvider.notifier).login(
            user, token, refreshToken: refreshToken);


        // ✅ 第二步：写本地缓存
        await prefs.setString('token', token);
        await prefs.setString('refresh_token', refreshToken!);


        ChatSocketService().connect(token, user.id);

        // ✅ 第四步：切页面
        Navigator.of(context).pushNamedAndRemoveUntil(
            '/main', (route) => false);
        ChatSocketService().connect(token, user.id);
        Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
      }
    }
  } catch (e) {
    print("网络或解析异常: $e");
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
    handleLogin();
  }

  void _showToast(String message) {
    ToastUtils.showToast(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      // resizeToAvoidBottomInset: false, // 防止键盘顶起整个页面
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag, // 拖拽时隐藏键盘
                controller: _scrollController,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 32), // 减少顶部间距
                        // Logo和标题区域
                        _buildHeader(),
                        const SizedBox(height: 16), // 减少间距
                        // Tab切换
                        // _buildTabBar(),
                        // const SizedBox(height: 16), // 减少间距
                        // 登录卡片
                        _buildLoginCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 底部协议 - 固定在底部
            SizedBox(width: double.infinity, child: _buildAgreementSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo图标
        Container(
          width: 70, // 稍微减小Logo尺寸
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20), // 稍微减小圆角
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 16, // 减少阴影模糊
                offset: const Offset(0, 6), // 减少阴影偏移
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 35, // 稍微减小图标尺寸
          ),
        ),

        const SizedBox(height: 16), // 减少间距
        // 标题
        const Text(
          '甜甜纪念日',
          style: TextStyle(
            fontSize: 26, // 稍微减小字体
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 6), // 减少间距
        // 副标题
        Text(
          '记录每一个甜蜜的瞬间',
          style: TextStyle(
            fontSize: 14, // 稍微减小字体
            color: textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300), // 更短的动画时长
      child: _buildAccountLoginCard(),
    );
  }

  Widget _buildAccountLoginCard() {
    return Container(
      key: const ValueKey('account'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // 稍微增加内边距
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20), // 稍微减小圆角
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16, // 减少阴影模糊
            offset: const Offset(0, 6), // 减少阴影偏移
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          const Text(
            '账号登录',
            style: TextStyle(
              fontSize: 22, // 稍微减小字体
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 6), // 减少间距

          Text(
            '使用用户名和密码登录',
            style: TextStyle(
              fontSize: 13, // 稍微减小字体
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 24), // 减少间距
          // 用户名输入框
          _buildUsernameInput(),

          const SizedBox(height: 16), // 减少间距
          // 密码输入框
          _buildPasswordInput(),

          const SizedBox(height: 24), // 减少间距
          // 登录按钮
          _buildLoginButton(),

          const SizedBox(height: 16), // 减少间距
          // 忘记密码
          _buildForgotPassword(),
        ],
      ),
    );
  }

  Widget _buildUsernameInput() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _usernameFocusNode.hasFocus ? primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _usernameController,
        focusNode: _usernameFocusNode,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 16, color: textPrimary),
        decoration: const InputDecoration(
          hintText: '请输入用户名',
          hintStyle: TextStyle(color: textLight),
          prefixIcon: Icon(Icons.person, color: textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onSubmitted: (value) {
          _passwordFocusNode.requestFocus();
        },
      ),
    );
  }

  Widget _buildPasswordInput() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _passwordFocusNode.hasFocus ? primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _passwordController,
        focusNode: _passwordFocusNode,
        obscureText: !_showConfirmPassword,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        style: const TextStyle(fontSize: 16, color: textPrimary),
        decoration: InputDecoration(
          hintText: '请输入密码',
          hintStyle: const TextStyle(color: textLight),
          prefixIcon: const Icon(Icons.lock, color: textSecondary),
          suffixIcon: IconButton(
            icon: Icon(
              _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
              color: textSecondary,
            ),
            onPressed: _toggleShowConfirmPassword,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onSubmitted: (value) {
          _passwordFocusNode.unfocus();
        },
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 52, // 稍微减小按钮高度
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14), // 稍微减小圆角
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10, // 减少阴影模糊
            offset: const Offset(0, 5), // 减少阴影偏移
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleLogin,
          borderRadius: BorderRadius.circular(14), // 稍微减小圆角
          child: Container(
            alignment: Alignment.center,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 22, // 稍微减小加载指示器尺寸
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      '登录',
                      style: TextStyle(
                        fontSize: 17, // 稍微减小字体
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () {
            // 忘记密码逻辑
          },
          child: Text('忘记密码？', style: TextStyle(color: primaryColor)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RegisterPage()),
            );
          },
          child: Text('注册账号', style: TextStyle(color: primaryColor)),
        ),
      ],
    );
  }

  Widget _buildAgreementSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _toggleAgreement,
              child: Container(
                width: 16, // 稍微减小复选框尺寸
                height: 16,
                decoration: BoxDecoration(
                  color: _isAgreed ? primaryColor : Colors.transparent,
                  border: Border.all(
                    color: _isAgreed ? primaryColor : textLight,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(3), // 稍微减小圆角
                ),
                child:
                    _isAgreed
                        ? const Icon(
                          Icons.check,
                          size: 14, // 稍微减小勾选图标尺寸
                          color: Colors.white,
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 4), // 减少间距
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14, // 稍微减小字体
                  color: textSecondary,
                ),
                children: [
                  TextSpan(
                    text: '我已阅读并同意',
                    recognizer: TapGestureRecognizer()..onTap = _toggleAgreement,
                  ),
                  TextSpan(
                    text: '《用户协议》',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const TextSpan(text: '和'),
                  TextSpan(
                    text: '《隐私政策》',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16), // 减少两行文字之间的间距
      ],
    );
  }
}
