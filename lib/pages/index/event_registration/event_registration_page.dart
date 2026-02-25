import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app_theme.dart';
import '../../../data/home_mock_data.dart';

/// 活动报名页（三级，属主页）：用户填写报名信息
class EventRegistrationPage extends StatefulWidget {
  const EventRegistrationPage({
    super.key,
    required this.eventId,
    required this.isLoggedIn,
  });

  final int eventId;
  final bool isLoggedIn;

  @override
  State<EventRegistrationPage> createState() => _EventRegistrationPageState();
}

class _EventRegistrationPageState extends State<EventRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  int _ticketCount = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // TODO: 后续对接后端API，提交报名信息
    // 模拟网络请求延迟
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    // 模拟付款成功，显示成功弹窗
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.capriBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: AppTheme.capriBlue,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '报名成功！',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '您已成功报名此活动',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '购买票数：$_ticketCount 张',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.capriBlue,
                  foregroundColor: AppTheme.lycheeWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // 关闭弹窗并返回到活动详情页
                  Navigator.of(context).pop(); // 关闭对话框
                  Navigator.of(context).pop(); // 返回到活动详情页
                },
                child: const Text('确定'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.softPeach, size: 28),
            const SizedBox(width: 12),
            const Text(
              '需要登录',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: const Text(
          '请先登录后再进行报名',
          style: TextStyle(
            color: AppTheme.capriBlue,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: AppTheme.mutedForeground),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.capriBlue,
              foregroundColor: AppTheme.lycheeWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // 关闭对话框
              Navigator.pop(context); // 返回到活动详情页
              // TODO: 跳转到登录页
              // Navigator.pushNamed(context, '/login');
            },
            child: const Text('去登录'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = HomeMockData.getEventDetailById(widget.eventId);

    if (event == null) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('活动报名'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.mutedForeground,
              ),
              const SizedBox(height: 16),
              Text(
                '未找到活动信息',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 检查是否登录
    if (!widget.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginDialog();
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: const Text('活动报名'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildEventSummary(event),
            const SizedBox(height: 16),
            _buildRegistrationForm(event),
            const SizedBox(height: 100), // 为底部按钮留出空间
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(event),
    );
  }

  Widget _buildEventSummary(EventDetail event) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              event.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 80,
                height: 80,
                color: AppTheme.muted,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: AppTheme.capriBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.date,
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppTheme.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm(EventDetail event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.softPeach,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '报名信息',
                  style: TextStyle(
                    color: AppTheme.capriBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 票数选择
            const Text(
              '购买票数',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lycheeWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.muted.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: _ticketCount > 1
                          ? AppTheme.capriBlue
                          : AppTheme.mutedForeground,
                    ),
                    onPressed: _ticketCount > 1
                        ? () {
                            setState(() {
                              _ticketCount--;
                            });
                          }
                        : null,
                  ),
                  Container(
                    width: 60,
                    alignment: Alignment.center,
                    child: Text(
                      '$_ticketCount',
                      style: const TextStyle(
                        color: AppTheme.capriBlue,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: _ticketCount < 10
                          ? AppTheme.capriBlue
                          : AppTheme.mutedForeground,
                    ),
                    onPressed: _ticketCount < 10
                        ? () {
                            setState(() {
                              _ticketCount++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 称呼输入
            const Text(
              '称呼',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: '请输入您的称呼',
                hintStyle: TextStyle(color: AppTheme.mutedForeground),
                filled: true,
                fillColor: AppTheme.lycheeWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.muted.withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.muted.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.capriBlue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.softPeach,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.softPeach,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入称呼';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // 手机号输入
            const Text(
              '手机号',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: InputDecoration(
                hintText: '请输入手机号',
                hintStyle: TextStyle(color: AppTheme.mutedForeground),
                filled: true,
                fillColor: AppTheme.lycheeWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.muted.withValues(alpha: 0.4),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.muted.withValues(alpha: 0.4),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.capriBlue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.softPeach,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.softPeach,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入手机号';
                }
                if (value.length != 11) {
                  return '请输入正确的手机号';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // 价格信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.capriBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '总计',
                    style: TextStyle(
                      color: AppTheme.capriBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    event.price == 0
                        ? '免费'
                        : '¥${(event.price * _ticketCount).toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.softPeach,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(EventDetail event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.capriBlue,
            foregroundColor: AppTheme.lycheeWhite,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  event.price == 0 ? '确认报名' : '确认并支付',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

