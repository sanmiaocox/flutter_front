import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../app_theme.dart';
import '../../../models/event.dart';
import '../../../services/api_service.dart';

/// 修改活动页面
/// 
/// 功能：
/// - 修改活动标题
/// - 修改活动时间
/// - 修改活动地点
/// - 修改活动描述
/// - 修改报名须知
/// - 修改最大参与人数
/// 
/// 注意：关联电影和活动类型不可修改
class EditEventPage extends StatefulWidget {
  const EditEventPage({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _maxParticipantsController;
  late TextEditingController _descriptionController;
  late TextEditingController _registrationNotesController;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _registrationDeadline;
  TimeOfDay? _registrationDeadlineTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  File? _coverImage;
  String? _existingImageUrl; // 现有的封面图片URL
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    
    // 初始化控制器并填充现有数据
    _titleController = TextEditingController(text: widget.event.title);
    _locationController = TextEditingController(text: widget.event.location);
    _maxParticipantsController = TextEditingController(text: widget.event.maxParticipants.toString());
    _descriptionController = TextEditingController(text: widget.event.description ?? '');
    _registrationNotesController = TextEditingController(text: widget.event.registrationNotice ?? '');
    
    // 保存现有封面图片URL
    _existingImageUrl = widget.event.fullImageUrl;
    
    // 初始化日期时间
    _selectedDate = widget.event.eventDate;
    _selectedTime = TimeOfDay(
      hour: widget.event.eventDate.hour,
      minute: widget.event.eventDate.minute,
    );
    
    if (widget.event.registrationDeadline != null) {
      _registrationDeadline = widget.event.registrationDeadline;
      _registrationDeadlineTime = TimeOfDay(
        hour: widget.event.registrationDeadline!.hour,
        minute: widget.event.registrationDeadline!.minute,
      );
    }
    
    if (widget.event.endTime != null) {
      _endDate = widget.event.endTime;
      _endTime = TimeOfDay(
        hour: widget.event.endTime!.hour,
        minute: widget.event.endTime!.minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _descriptionController.dispose();
    _registrationNotesController.dispose();
    super.dispose();
  }

  /// 选择活动开始日期
  Future<void> _selectDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.capriBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.capriBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// 选择活动开始时间
  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.capriBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.capriBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  /// 选择报名截止日期
  Future<void> _selectRegistrationDeadline() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _registrationDeadline ?? tomorrow,
      firstDate: tomorrow,
      lastDate: _selectedDate ?? DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.capriBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.capriBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _registrationDeadline = picked;
      });
    }
  }

  /// 选择报名截止时间
  Future<void> _selectRegistrationDeadlineTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _registrationDeadlineTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.capriBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.capriBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _registrationDeadlineTime = picked;
      });
    }
  }

  /// 选择活动结束日期
  Future<void> _selectEndDate() async {
    final now = DateTime.now();
    final startDate = _selectedDate ?? DateTime(now.year, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? startDate,
      firstDate: startDate,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.capriBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.capriBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  /// 选择活动结束时间
  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.capriBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.capriBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  /// 选择封面图片
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _coverImage = File(pickedFile.path);
      });
    }
  }

  /// 提交修改
  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择活动开始日期和时间')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 组合日期和时间
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      DateTime? registrationDeadlineDateTime;
      if (_registrationDeadline != null && _registrationDeadlineTime != null) {
        registrationDeadlineDateTime = DateTime(
          _registrationDeadline!.year,
          _registrationDeadline!.month,
          _registrationDeadline!.day,
          _registrationDeadlineTime!.hour,
          _registrationDeadlineTime!.minute,
        );
      }

      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      // 如果有新上传的封面图片，先上传
      String? imageFilename;
      if (_coverImage != null) {
        final uploadResponse = await ApiService.uploadImage(_coverImage!);
        if (uploadResponse.isSuccess && uploadResponse.data != null) {
          imageFilename = uploadResponse.data!; // data 直接就是文件名字符串
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('封面上传失败: ${uploadResponse.message}')),
            );
          }
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      } else if (_existingImageUrl != null) {
        // 如果没有上传新图片，但有现有图片，提取文件名
        // _existingImageUrl 可能是完整URL或只是文件名
        final uri = Uri.tryParse(_existingImageUrl!);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          imageFilename = uri.pathSegments.last;
        } else {
          imageFilename = _existingImageUrl;
        }
      }

      // 调用API更新活动
      final response = await ApiService.updateEvent(
        eventId: widget.event.id,
        title: _titleController.text.trim(),
        imageUrl: imageFilename,
        eventDate: eventDateTime,
        registrationDeadline: registrationDeadlineDateTime,
        endTime: endDateTime,
        location: _locationController.text.trim(),
        maxParticipants: int.parse(_maxParticipantsController.text.trim()),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        registrationNotice: _registrationNotesController.text.trim().isEmpty 
            ? null 
            : _registrationNotesController.text.trim(),
      );

      if (!mounted) return;

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('修改成功'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // 返回true表示修改成功
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败: ${response.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: const Text(
          '修改活动',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 提示信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.softPeach.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.softPeach.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.softPeach,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '注意：活动类型和关联电影不可修改',
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 封面图片
            _buildCoverImageSection(),
            const SizedBox(height: 24),

            // 活动类型（只读）
            _buildReadOnlyField(
              label: '活动类型',
              value: widget.event.type,
              icon: Icons.category,
            ),
            const SizedBox(height: 20),

            // 关联电影（只读）
            _buildReadOnlyField(
              label: '关联电影',
              value: widget.event.movieTitle ?? '未知电影',
              icon: Icons.movie,
            ),
            const SizedBox(height: 20),

            // 活动标题
            _buildTextField(
              controller: _titleController,
              label: '活动标题',
              hint: '请输入活动标题',
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入活动标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 时间信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.capriBlue.withValues(alpha: 0.05),
                    AppTheme.capriBlue.withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.capriBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.capriBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          color: AppTheme.capriBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '时间安排',
                        style: TextStyle(
                          color: AppTheme.capriBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 活动开始时间
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeField(
                          label: '开始日期',
                          value: _selectedDate != null
                              ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                              : null,
                          hint: '选择日期',
                          icon: Icons.event,
                          onTap: _selectDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimeField(
                          label: '开始时间',
                          value: _selectedTime != null
                              ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                              : null,
                          hint: '选择时间',
                          icon: Icons.access_time,
                          onTap: _selectTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 报名截止时间
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeField(
                          label: '报名截止日期',
                          value: _registrationDeadline != null
                              ? '${_registrationDeadline!.year}-${_registrationDeadline!.month.toString().padLeft(2, '0')}-${_registrationDeadline!.day.toString().padLeft(2, '0')}'
                              : null,
                          hint: '选择日期（可选）',
                          icon: Icons.event_busy,
                          onTap: _selectRegistrationDeadline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimeField(
                          label: '截止时间',
                          value: _registrationDeadlineTime != null
                              ? '${_registrationDeadlineTime!.hour.toString().padLeft(2, '0')}:${_registrationDeadlineTime!.minute.toString().padLeft(2, '0')}'
                              : null,
                          hint: '选择时间（可选）',
                          icon: Icons.timer_off,
                          onTap: _selectRegistrationDeadlineTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 活动结束时间
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTimeField(
                          label: '结束日期',
                          value: _endDate != null
                              ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                              : null,
                          hint: '选择日期（可选）',
                          icon: Icons.event_available,
                          onTap: _selectEndDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTimeField(
                          label: '结束时间',
                          value: _endTime != null
                              ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                              : null,
                          hint: '选择时间（可选）',
                          icon: Icons.timer,
                          onTap: _selectEndTime,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 活动地点
            _buildTextField(
              controller: _locationController,
              label: '活动地点',
              hint: '请输入活动地点',
              icon: Icons.location_on,
              maxLength: 200,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入活动地点';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 最大参与人数
            _buildTextField(
              controller: _maxParticipantsController,
              label: '最大参与人数',
              hint: '请输入最大参与人数',
              icon: Icons.people,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入最大参与人数';
                }
                final num = int.tryParse(value);
                if (num == null || num <= 0) {
                  return '请输入有效的人数';
                }
                // 不能小于当前已报名人数
                if (num < widget.event.participants) {
                  return '不能小于当前已报名人数(${widget.event.participants})';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 活动描述
            _buildTextField(
              controller: _descriptionController,
              label: '活动描述',
              hint: '请输入活动描述',
              icon: Icons.description,
              maxLines: 5,
              maxLength: 2000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入活动描述';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 报名须知
            _buildTextField(
              controller: _registrationNotesController,
              label: '报名须知',
              hint: '请输入报名须知（可选）',
              icon: Icons.info_outline,
              maxLines: 5,
              maxLength: 2000,
            ),
            const SizedBox(height: 32),

            // 提交按钮
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: _isSubmitting
                    ? null
                    : const LinearGradient(
                        colors: [
                          AppTheme.capriBlue,
                          Color(0xFF4A90E2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                boxShadow: _isSubmitting
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.capriBlue.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSubmitting ? AppTheme.muted : Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: _isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '保存中...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '保存修改',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.mutedForeground),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.muted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.muted,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppTheme.capriBlue),
              const SizedBox(width: 8),
            ],
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
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.mutedForeground),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.muted),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.muted),
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

  Widget _buildDateTimeField({
    required String label,
    String? value,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.capriBlue,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value != null 
                    ? AppTheme.capriBlue.withValues(alpha: 0.3)
                    : AppTheme.muted,
                width: value != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: value != null 
                      ? AppTheme.capriBlue 
                      : AppTheme.mutedForeground,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: value != null 
                          ? AppTheme.capriBlue 
                          : AppTheme.mutedForeground,
                      fontSize: 13,
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image, size: 18, color: AppTheme.capriBlue),
            const SizedBox(width: 8),
            const Text(
              '活动封面',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '（可选）',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              gradient: _coverImage == null && _existingImageUrl == null
                  ? LinearGradient(
                      colors: [
                        AppTheme.capriBlue.withValues(alpha: 0.05),
                        AppTheme.capriBlue.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _coverImage != null || _existingImageUrl != null
                    ? Colors.transparent
                    : AppTheme.capriBlue.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: _coverImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _coverImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () {
                              setState(() {
                                _coverImage = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  )
                : _existingImageUrl != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              _existingImageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppTheme.muted,
                                child: const Icon(Icons.error, size: 64, color: AppTheme.mutedForeground),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.capriBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: AppTheme.capriBlue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '点击上传封面图片',
                            style: TextStyle(
                              color: AppTheme.mutedForeground,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '建议尺寸 16:9',
                            style: TextStyle(
                              color: AppTheme.mutedForeground.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
}

