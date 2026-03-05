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

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
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
    super.dispose();
  }

  /// 选择日期
  Future<void> _selectDate() async {
    final now = DateTime.now();
    // 时间必须是未来时间
    final tomorrow = DateTime(now.year, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow, // 从明天开始
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

  /// 选择时间
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
        const SnackBar(content: Text('请选择活动日期和时间')),
      );
      return;
    }

    if (_selectedMovie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择关联电影')),
      );
      return;
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

      // 3. 组合日期和时间
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // 4. 创建活动
      final response = await ApiService.createEvent(
        title: _titleController.text.trim(),
        imageUrl: imageFilename,
        eventDate: eventDateTime,
        location: _locationController.text.trim(),
        maxParticipants: int.parse(_maxParticipantsController.text),
        type: _typeController.text.trim(),
        description: _descriptionController.text.trim(),
        movieId: localMovieId!,
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

            // 活动日期和时间
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeField(
                    label: '活动日期',
                    value: _selectedDate != null
                        ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                        : null,
                    hint: '选择日期',
                    icon: Icons.calendar_today,
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTimeField(
                    label: '活动时间',
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
            const SizedBox(height: 20),

            // 活动地点
            _buildTextField(
              controller: _locationController,
              label: '活动地点',
              hint: '请输入活动地点',
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
              maxLines: 5,
              maxLength: 2000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入活动描述';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // 提交按钮
            FilledButton(
              onPressed: _isSubmitting ? null : _submitEvent,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.capriBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
                      '创建活动',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
        const Text(
          '活动封面',
          style: TextStyle(
            color: AppTheme.capriBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.muted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.muted,
                width: 1,
              ),
            ),
            child: _coverImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _coverImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: AppTheme.mutedForeground,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '点击上传封面图片',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 14,
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
        const Text(
          '关联电影',
          style: TextStyle(
            color: AppTheme.capriBlue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectMovie,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.muted,
                width: 1,
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
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_selectedMovie!.releaseDate != null)
                              Text(
                                _selectedMovie!.releaseDate!,
                                style: TextStyle(
                                  color: AppTheme.mutedForeground,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.mutedForeground,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.movie,
                        color: AppTheme.mutedForeground,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '点击选择电影',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 14,
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
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
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
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.muted),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.mutedForeground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: value != null ? AppTheme.capriBlue : AppTheme.mutedForeground,
                      fontSize: 14,
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

