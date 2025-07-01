import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_days/pages/register_page.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme_controller.dart';
import 'package:heart_days/api/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  bool _isPasswordMode = false;
  bool _isLoading = false;
  bool _isAgreed = false;
  int _countdown = 0;
  int _currentTabIndex = 0; // 0: 手机登录, 1: 账号登录
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

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _toggleLoginMode() {
    setState(() {
      _isPasswordMode = !_isPasswordMode;
      _codeController.clear();
    });
  }

  void _toggleTab(int index) {
    if (_currentTabIndex != index) {
      setState(() {
        _currentTabIndex = index;
      });
      _tabAnimationController.reset();
      _tabAnimationController.forward();
      _contentAnimationController.reset();
      _contentAnimationController.forward();
    }
  }

  void _toggleAgreement() {
    setState(() {
      _isAgreed = !_isAgreed;
    });
  }

  Future<void> _handleLogin() async {
    if (!_isAgreed) {
      _showToast('请先同意用户协议和隐私政策');
      return;
    }

    if (_currentTabIndex == 0) {
      // 手机登录
      if (_phoneController.text.isEmpty) {
        _showToast('请输入手机号');
        return;
      }

      if (_codeController.text.isEmpty) {
        _showToast(_isPasswordMode ? '请输入密码' : '请输入验证码');
        return;
      }
    } else {
      // 账号登录
      if (_usernameController.text.isEmpty) {
        _showToast('请输入用户名');
        return;
      }

      if (_passwordController.text.isEmpty) {
        _showToast('请输入密码');
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    void handleLogin() async {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await userLogin({
          "userAccount": _usernameController.text,
          "password": _passwordController.text,
        });

        if (response.code == 200) {
          final user = response.data?.user;
          final token = response.data?.accessToken;
          if (user != null && token != null) {
            _showToast('登录成功');
            await ref.read(authProvider.notifier).login(user as User, token);

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', token);

            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/main', (route) => false);
          }
        }
      } catch (e) {
        print("网络或解析异常: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登录错误: $e')));
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
                        const SizedBox(height: 24), // 减少间距
                        // Tab切换
                        _buildTabBar(),

                        const SizedBox(height: 16), // 减少间距
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

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleTab(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                // 减少动画时长
                curve: Curves.easeOut,
                // 使用更温和的曲线
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient:
                      _currentTabIndex == 0
                          ? const LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                          : null,
                  color: _currentTabIndex == 0 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200), // 减少文字动画时长
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _currentTabIndex == 0 ? Colors.white : textSecondary,
                  ),
                  child: const Text('手机登录', textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _toggleTab(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                // 减少动画时长
                curve: Curves.easeOut,
                // 使用更温和的曲线
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient:
                      _currentTabIndex == 1
                          ? const LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                          : null,
                  color: _currentTabIndex == 1 ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200), // 减少文字动画时长
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _currentTabIndex == 1 ? Colors.white : textSecondary,
                  ),
                  child: const Text('账号登录', textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300), // 更短的动画时长
      transitionBuilder: (Widget child, Animation<double> animation) {
        // 只使用淡入淡出效果，更简单温和
        return FadeTransition(opacity: animation, child: child);
      },
      child:
          _currentTabIndex == 0
              ? _buildPhoneLoginCard()
              : _buildAccountLoginCard(),
    );
  }

  Widget _buildPhoneLoginCard() {
    return Container(
      key: const ValueKey('phone'),
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
            '手机号登录',
            style: TextStyle(
              fontSize: 22, // 稍微减小字体
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),

          const SizedBox(height: 6), // 减少间距

          Text(
            '使用手机号快速登录',
            style: TextStyle(
              fontSize: 13, // 稍微减小字体
              color: textSecondary,
            ),
          ),

          const SizedBox(height: 24), // 减少间距
          // 手机号输入框
          _buildPhoneInput(),

          const SizedBox(height: 16), // 减少间距
          // 验证码/密码输入框
          _buildCodeInput(),

          const SizedBox(height: 24), // 减少间距
          // 登录按钮
          _buildLoginButton(),

          const SizedBox(height: 16), // 减少间距
          // 切换登录方式
          _buildToggleMode(),
        ],
      ),
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

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _phoneFocusNode.hasFocus ? primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _phoneController,
        focusNode: _phoneFocusNode,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ],
        style: const TextStyle(fontSize: 16, color: textPrimary),
        decoration: const InputDecoration(
          hintText: '请输入手机号',
          hintStyle: TextStyle(color: textLight),
          prefixIcon: Icon(Icons.phone_android, color: textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        onSubmitted: (value) {
          if (_isPasswordMode) {
            _passwordFocusNode.requestFocus();
          } else {
            _codeFocusNode.requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildCodeInput() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _codeFocusNode.hasFocus ? primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeController,
              focusNode: _codeFocusNode,
              obscureText: _isPasswordMode,
              keyboardType:
                  _isPasswordMode ? TextInputType.text : TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters:
                  _isPasswordMode
                      ? null
                      : [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
              style: const TextStyle(fontSize: 16, color: textPrimary),
              decoration: InputDecoration(
                hintText: _isPasswordMode ? '请输入密码' : '请输入验证码',
                hintStyle: const TextStyle(color: textLight),
                prefixIcon: Icon(
                  _isPasswordMode ? Icons.lock : Icons.verified_user,
                  color: textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onSubmitted: (value) {
                _codeFocusNode.unfocus();
              },
            ),
          ),

          if (!_isPasswordMode) ...[
            Container(height: 40, width: 1, color: textLight.withOpacity(0.3)),
            GestureDetector(
              onTap: _countdown > 0 ? null : _startCountdown,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _countdown > 0 ? '${_countdown}s' : '获取验证码',
                  style: TextStyle(
                    fontSize: 14,
                    color: _countdown > 0 ? textLight : primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
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
        obscureText: true,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        style: const TextStyle(fontSize: 16, color: textPrimary),
        decoration: const InputDecoration(
          hintText: '请输入密码',
          hintStyle: TextStyle(color: textLight),
          prefixIcon: Icon(Icons.lock, color: textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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

  Widget _buildToggleMode() {
    return Center(
      child: GestureDetector(
        onTap: _toggleLoginMode,
        child: Text(
          _isPasswordMode ? '使用验证码登录' : '使用密码登录',
          style: const TextStyle(
            fontSize: 14,
            color: primaryColor,
            fontWeight: FontWeight.w500,
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
          child: Text('忘记密码？'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RegisterPage()),
            );
          },
          child: Text('注册账号'),
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
                width: 12, // 稍微减小复选框尺寸
                height: 12,
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
                          size: 10, // 稍微减小勾选图标尺寸
                          color: Colors.white,
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 4), // 减少间距
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 11, // 稍微减小字体
                  color: textSecondary,
                ),
                children: [
                  const TextSpan(text: '我已阅读并同意'),
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
        const SizedBox(height: 2), // 减少两行文字之间的间距
        Text(
          '登录即表示您同意我们的服务条款和隐私政策',
          style: TextStyle(
            fontSize: 10, // 稍微减小字体
            color: textLight,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
