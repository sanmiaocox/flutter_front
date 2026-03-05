import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';
import '../../models/tmdb_movie.dart';

/// 创建活动页面
class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController(text: '100');
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _registrationNotesController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  DateTime? _registrationDeadline;
  TimeOfDay? _registrationDeadlineTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  File? _coverImage;
  TmdbMovie? _selectedMovie;
  bool _isSubmitting = false;

  final List<String> _eventTypes = [
    '观影团',
    '影评征集',
    '线下活动',
    '电影节',
    '主题展映',
    '见面会',
    '嘉年华',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _typeController.dispose();
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
      initialDate: tomorrow,
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
      initialTime: TimeOfDay.now(),
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
      initialDate: tomorrow,
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
      initialTime: TimeOfDay.now(),
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
      initialDate: startDate,
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
      initialTime: TimeOfDay.now(),
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

  /// 选择关联电影
  Future<void> _selectMovie() async {
    final searchController = TextEditingController();
    List<TmdbMovie> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text(
              '选择电影',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 500,
              child: Column(
                children: [
                  // 搜索框
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: '搜索电影...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (value) async {
                      if (value.trim().isEmpty) return;
                      
                      setDialogState(() {
                        isSearching = true;
                      });

                      try {
                        final response = await ApiService.searchMovies(
                          keyword: value.trim(),
                          page: 1,
                        );

                        if (response.isSuccess && response.data != null) {
                          setDialogState(() {
                            searchResults = response.data!.results;
                            isSearching = false;
                          });
                        } else {
                          setDialogState(() {
                            isSearching = false;
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('搜索失败: ${response.message}')),
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSearching = false;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('搜索失败: $e')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // 搜索结果
                  Expanded(
                    child: searchResults.isEmpty
                        ? Center(
                            child: Text(
                              '请输入电影名称搜索',
                              style: TextStyle(
                                color: AppTheme.mutedForeground,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final movie = searchResults[index];
                              return ListTile(
                                leading: movie.posterPath != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          'https://image.tmdb.org/t/p/w92${movie.posterPath}',
                                          width: 40,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 40,
                                        height: 60,
                                        color: AppTheme.muted,
                                        child: const Icon(Icons.movie),
                                      ),
                                title: Text(
                                  movie.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: movie.releaseDate != null
                                    ? Text(
                                        movie.releaseDate!,
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedMovie = movie;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 选择活动类型
  Future<void> _selectEventType() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '选择活动类型',
          style: TextStyle(
            color: AppTheme.capriBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _eventTypes.length,
            itemBuilder: (context, index) {
              final type = _eventTypes[index];
              return ListTile(
                title: Text(type),
                onTap: () => Navigator.pop(context, type),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      _typeController.text = selected;
    }
  }

  /// 提交创建活动
  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择活动开始日期和时间')),
      );
      return;
    }

    if (_selectedMovie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择关联电影')),
      );
      return;
    }

    // 验证时间逻辑
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

      if (registrationDeadlineDateTime.isAfter(eventDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报名截止时间不能晚于活动开始时间')),
        );
        return;
      }
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

      if (endDateTime.isBefore(eventDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('活动结束时间不能早于活动开始时间')),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. 上传封面图片（如果有）
      String? imageFilename;
      if (_coverImage != null) {
        final uploadResponse = await ApiService.uploadImage(_coverImage!);
        if (uploadResponse.isSuccess && uploadResponse.data != null) {
          imageFilename = uploadResponse.data;
        } else {
          throw Exception('图片上传失败: ${uploadResponse.message}');
        }
      }

      // 2. 保存电影到数据库
      final saveMovieResponse = await ApiService.saveMovieToDatabase(_selectedMovie!.id);
      
      int? localMovieId;
      if (saveMovieResponse.isSuccess && saveMovieResponse.data != null) {
        // 获取本地电影ID
        localMovieId = saveMovieResponse.data!['id'] as int;
        debugPrint('电影已保存到数据库，本地ID: $localMovieId');
      } else {
        throw Exception('电影信息保存失败: ${saveMovieResponse.message}');
      }

      // 3. 创建活动
      final response = await ApiService.createEvent(
        title: _titleController.text.trim(),
        imageUrl: imageFilename,
        eventDate: eventDateTime,
        location: _locationController.text.trim(),
        maxParticipants: int.parse(_maxParticipantsController.text),
        type: _typeController.text.trim(),
        description: _descriptionController.text.trim(),
        movieId: localMovieId!,
        registrationDeadline: registrationDeadlineDateTime,
        endTime: endDateTime,
        registrationNotice: _registrationNotesController.text.trim().isNotEmpty 
            ? _registrationNotesController.text.trim() 
            : null,
      );

      if (!mounted) return;

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('活动创建成功！')),
        );
        Navigator.pop(context, true); // 返回true表示创建成功
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: ${response.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建失败: $e')),
      );
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
          '创建活动',
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
            // 封面图片
            _buildCoverImageSection(),
            const SizedBox(height: 24),

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

            // 活动类型
            _buildSelectField(
              controller: _typeController,
              label: '活动类型',
              hint: '请选择活动类型',
              onTap: _selectEventType,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请选择活动类型';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // 关联电影
            _buildMovieSection(),
            const SizedBox(height: 20),

            // 时间信息卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.capriBlue.withOpacity(0.05),
                    AppTheme.capriBlue.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.capriBlue.withOpacity(0.2),
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
                          color: AppTheme.capriBlue.withOpacity(0.1),
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
                          isRequired: true,
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
                          isRequired: true,
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
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入最大参与人数';
                }
                final num = int.tryParse(value);
                if (num == null || num <= 0) {
                  return '请输入有效的人数';
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
                          color: AppTheme.capriBlue.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitEvent,
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
                            '创建中...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            '创建活动',
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
              gradient: _coverImage == null
                  ? LinearGradient(
                      colors: [
                        AppTheme.capriBlue.withOpacity(0.05),
                        AppTheme.capriBlue.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _coverImage == null
                    ? AppTheme.capriBlue.withOpacity(0.2)
                    : Colors.transparent,
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
                            color: Colors.black.withOpacity(0.6),
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
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.capriBlue.withOpacity(0.1),
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
                          color: AppTheme.mutedForeground.withOpacity(0.7),
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

  Widget _buildMovieSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.movie, size: 18, color: AppTheme.capriBlue),
            const SizedBox(width: 8),
            const Text(
              '关联电影',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '*',
              style: TextStyle(
                color: AppTheme.softPeach,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectMovie,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _selectedMovie != null
                    ? AppTheme.capriBlue.withOpacity(0.3)
                    : AppTheme.muted,
                width: _selectedMovie != null ? 1.5 : 1,
              ),
            ),
            child: _selectedMovie != null
                ? Row(
                    children: [
                      if (_selectedMovie!.posterPath != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w200${_selectedMovie!.posterPath}',
                            width: 50,
                            height: 75,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          width: 50,
                          height: 75,
                          decoration: BoxDecoration(
                            color: AppTheme.muted,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.movie, color: Colors.white),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedMovie!.title,
                              style: const TextStyle(
                                color: AppTheme.capriBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_selectedMovie!.releaseDate != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: AppTheme.mutedForeground,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedMovie!.releaseDate!,
                                    style: TextStyle(
                                      color: AppTheme.mutedForeground,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.capriBlue,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search,
                        color: AppTheme.mutedForeground,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '点击搜索并选择电影',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
    List<TextInputFormatter>? inputFormatters,
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
          inputFormatters: inputFormatters,
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

  Widget _buildSelectField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.capriBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.mutedForeground),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.arrow_drop_down),
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
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppTheme.softPeach,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
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
                    ? AppTheme.capriBlue.withOpacity(0.3)
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
}

