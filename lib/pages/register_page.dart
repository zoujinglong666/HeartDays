import 'package:flutter/material.dart';
import 'package:heart_days/apis/user.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isAgreed = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 更柔和的配色方案 - 与登录页面保持一致
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

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAgreement() {
    setState(() {
      _isAgreed = !_isAgreed;
    });
  }

  void _toggleShowPassword() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  void _toggleShowConfirmPassword() {
    setState(() {
      _showConfirmPassword = !_showConfirmPassword;
    });
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

  Future<void> _handleRegister() async {
    if (_usernameController.text.isEmpty) {
      _showToast('请输入账号');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showToast('请输入密码');
      return;
    }
    if (_confirmPasswordController.text.isEmpty) {
      _showToast('请确认密码');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showToast('两次输入的密码不一致');
      return;
    }
    if (!_isAgreed) {
      _showToast('请先同意用户协议和隐私政策');
      return;
    }
    setState(() {
      _isLoading = true;
    });

    void handleRegister() async {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;

      if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
        _showToast("请填写完整信息");
        return;
      }

      if (password != confirmPassword) {
        _showToast("两次密码不一致");
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await userRegister({
          "userAccount": username,
          "password": password,
          "confirmPassword": confirmPassword,
        });

        print("注册响应: $response");
        if (response.code == 200 && response.data != null) {
          _showToast("注册成功！");
          if (mounted) {
            Navigator.of(context).pop(); // 返回登录页
          }
        } else {
          _showToast(response.message ?? "注册失败，请稍后重试");
        }
      } catch (e) {
        print("注册异常: $e");
        _showToast("网络错误，请检查连接");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    handleRegister();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '注册',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        // Logo和标题区域
                        _buildHeader(),
                        const SizedBox(height: 32),
                        // 注册卡片
                        _buildRegisterCard(),
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
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.favorite, color: Colors.white, size: 35),
        ),

        const SizedBox(height: 16),
        // 标题
        const Text(
          '创建账号',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 6),
        // 副标题
        Text(
          '加入我们，记录美好时光',
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户名输入框
          _buildUsernameInput(),

          const SizedBox(height: 16),

          // 密码输入框
          _buildPasswordInput(),

          const SizedBox(height: 16),

          // 确认密码输入框
          _buildConfirmPasswordInput(),

          const SizedBox(height: 24),

          // 注册按钮
          _buildRegisterButton(),
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
        obscureText: !_showPassword,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 16, color: textPrimary),
        decoration: InputDecoration(
          hintText: '请输入密码',
          hintStyle: const TextStyle(color: textLight),
          prefixIcon: const Icon(Icons.lock, color: textSecondary),
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: textSecondary,
            ),
            onPressed: _toggleShowPassword,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        onSubmitted: (value) {
          _confirmPasswordFocusNode.requestFocus();
        },
      ),
    );
  }

  Widget _buildConfirmPasswordInput() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              _confirmPasswordFocusNode.hasFocus
                  ? primaryColor
                  : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _confirmPasswordController,
        focusNode: _confirmPasswordFocusNode,
        obscureText: !_showConfirmPassword,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.done,
        style: const TextStyle(fontSize: 16, color: textPrimary),
        decoration: InputDecoration(
          hintText: '请确认密码',
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
          _confirmPasswordFocusNode.unfocus();
        },
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleRegister,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            alignment: Alignment.center,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      '注册',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgreementSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _isAgreed,
              onChanged: (val) => _toggleAgreement(),
              activeColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: textSecondary),
                children: [
                  const TextSpan(text: '我已阅读并同意'),
                  TextSpan(
                    text: '《用户协议》',
                    style: TextStyle(color: primaryColor),
                  ),
                  const TextSpan(text: '和'),
                  TextSpan(
                    text: '《隐私政策》',
                    style: TextStyle(color: primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
