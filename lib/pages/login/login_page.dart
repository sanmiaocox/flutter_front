import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';

/// 登录页。进入应用时首先展示，登录成功后跳转至带底部导航的主页。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  DateTime? _lastLoginAttempt; // 记录上次登录尝试时间
  
  // 配置常量
  static const Duration _loginCooldown = Duration(seconds: 3); // 登录失败后的冷却时间
  static const Duration _requestTimeout = Duration(seconds: 10); // 请求超时时间
  static const Duration _snackBarDuration = Duration(seconds: 3); // 提示消息显示时长

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 验证手机号格式
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    if (value.length != 11) {
      return '手机号必须是11位';
    }
    if (!value.startsWith('1')) {
      return '手机号格式不正确';
    }
    return null;
  }

  /// 验证密码
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码至少6位';
    }
    return null;
  }

  /// 检查是否在冷却期内
  bool _isInCooldown() {
    if (_lastLoginAttempt == null) return false;
    final elapsed = DateTime.now().difference(_lastLoginAttempt!);
    return elapsed < _loginCooldown;
  }

  /// 获取剩余冷却时间(秒)
  int _getRemainingCooldown() {
    if (_lastLoginAttempt == null) return 0;
    final elapsed = DateTime.now().difference(_lastLoginAttempt!);
    final remaining = _loginCooldown.inSeconds - elapsed.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// 执行登录
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 检查冷却时间
    if (_isInCooldown()) {
      final remaining = _getRemainingCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请等待 $remaining 秒后再试'),
          backgroundColor: Colors.orange,
          duration: _snackBarDuration,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.login(
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        timeout: _requestTimeout,
      );

      if (!mounted) return;

      if (response.isSuccess) {
        // 登录成功 - 清除冷却时间
        _lastLoginAttempt = null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('欢迎回来，${response.data!.user.username}！'),
            backgroundColor: Colors.green,
            duration: _snackBarDuration,
          ),
        );
        
        // 跳转到主页
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // 登录失败 - 记录失败时间,启动冷却
        _lastLoginAttempt = DateTime.now();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
            duration: _snackBarDuration,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // 请求异常 - 记录失败时间
      _lastLoginAttempt = DateTime.now();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('登录失败: $e'),
          backgroundColor: Colors.red,
          duration: _snackBarDuration,
        ),
      );
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
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo或图标
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.capriBlue,
                          AppTheme.capriBlue.withOpacity(0.7),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.capriBlue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.movie,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 标题
                  const Text(
                    '电影交流社区',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.capriBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '发现更多精彩活动',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 手机号输入框
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                    decoration: InputDecoration(
                      labelText: '手机号',
                      hintText: '请输入11位手机号',
                      prefixIcon: const Icon(Icons.phone_android),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.muted.withOpacity(0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.capriBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 密码输入框
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      labelText: '密码',
                      hintText: '请输入密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppTheme.muted.withValues(alpha: 0.5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.capriBlue,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 登录按钮
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.capriBlue,
                        foregroundColor: AppTheme.lycheeWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              '登录',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 注册提示
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '还没有账号？',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pushNamed('/register');
                              },
                        child: const Text(
                          '立即注册',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
