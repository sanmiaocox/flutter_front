import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app_theme.dart';
import '../../../services/api_service.dart';
import '../../../models/event.dart';

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
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qqController = TextEditingController();
  final _wechatController = TextEditingController();
  bool _isSubmitting = false;
  Event? _event;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEventDetail();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
    _qqController.dispose();
    _wechatController.dispose();
    super.dispose();
  }

  /// 加载活动详情
  Future<void> _loadEventDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getEventDetail(widget.eventId);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _event = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_event == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 调用后端API参加活动，传递个人信息
      final response = await ApiService.joinEvent(
        widget.eventId,
        participantNickname: _nicknameController.text.trim(),
        participantPhone: _phoneController.text.trim(),
        participantQq: _qqController.text.trim().isNotEmpty 
            ? _qqController.text.trim() 
            : null,
        participantWechat: _wechatController.text.trim().isNotEmpty 
            ? _wechatController.text.trim() 
            : null,
      );

      if (!mounted) return;

      if (response.isSuccess) {
        // 参加活动成功后，自动加入对应群聊
        try {
          final groupResp = await ApiService.getGroupByEventId(widget.eventId);
          if (groupResp.isSuccess && groupResp.data != null) {
            final groupId = groupResp.data!['id'] as int;
            await ApiService.joinGroup(groupId);
            debugPrint('已自动加入活动群聊: $groupId');
          }
        } catch (e) {
          debugPrint('自动加入群聊失败（不影响报名）: $e');
        }

        setState(() {
          _isSubmitting = false;
        });
        // 显示成功弹窗
        _showSuccessDialog();
      } else {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('报名失败: ${response.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('报名失败: $e')),
      );
    }
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
                  // 关闭弹窗并返回到活动详情页，传递true表示报名成功
                  Navigator.of(context).pop(); // 关闭对话框
                  Navigator.of(context).pop(true); // 返回到活动详情页
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
    // 检查是否登录
    if (!widget.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginDialog();
      });
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('活动报名'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.capriBlue),
        ),
      );
    }

    if (_errorMessage != null || _event == null) {
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
                _errorMessage ?? '未找到活动信息',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadEventDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.capriBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;

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

  Widget _buildEventSummary(Event event) {
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
            child: event.fullImageUrl != null
                ? Image.network(
                    event.fullImageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: AppTheme.muted,
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.muted,
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
                        _formatDate(event.eventDate),
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

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRegistrationForm(Event event) {
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
            // 提示信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.capriBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.capriBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '请填写您的个人信息以完成报名',
                      style: TextStyle(
                        color: AppTheme.capriBlue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 活动信息
            _buildInfoItem('活动名称', event.title),
            const SizedBox(height: 16),
            _buildInfoItem('活动时间', _formatDate(event.eventDate)),
            const SizedBox(height: 16),
            _buildInfoItem('活动地点', event.location),
            const SizedBox(height: 16),
            _buildInfoItem('剩余名额', '${event.maxParticipants - event.participants}人'),
            const SizedBox(height: 24),
            Divider(height: 1, color: AppTheme.muted.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            // 个人信息标题
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.capriBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '个人信息',
                  style: TextStyle(
                    color: AppTheme.capriBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 昵称输入框
            _buildTextField(
              controller: _nicknameController,
              label: '昵称',
              hint: '请输入您的昵称',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入昵称';
                }
                if (value.trim().length < 2) {
                  return '昵称至少2个字符';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 手机号输入框
            _buildTextField(
              controller: _phoneController,
              label: '手机号',
              hint: '请输入您的手机号',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入手机号';
                }
                if (value.trim().length != 11) {
                  return '请输入11位手机号';
                }
                if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(value.trim())) {
                  return '请输入有效的手机号';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // QQ号输入框（可选）
            _buildTextField(
              controller: _qqController,
              label: 'QQ号（可选）',
              hint: '请输入您的QQ号',
              icon: Icons.chat_bubble_outline,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (value.trim().length < 5) {
                    return 'QQ号至少5位数字';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 微信号输入框（可选）
            _buildTextField(
              controller: _wechatController,
              label: '微信号（可选）',
              hint: '请输入您的微信号',
              icon: Icons.wechat_outlined,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  if (value.trim().length < 6) {
                    return '微信号至少6个字符';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.capriBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppTheme.mutedForeground.withOpacity(0.6),
              fontSize: 14,
            ),
            filled: true,
            fillColor: AppTheme.lycheeWhite,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.muted.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.muted.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.capriBlue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.softPeach),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.softPeach, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.capriBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Event event) {
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
              : const Text(
                  '确认报名',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

