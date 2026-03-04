import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../app_theme.dart';
import '../../../services/api_service.dart';

/// 创建收藏夹页面
class CreateCollectionPage extends StatefulWidget {
  final String type; // MOVIE 或 EVENT

  const CreateCollectionPage({
    super.key,
    required this.type,
  });

  @override
  State<CreateCollectionPage> createState() => _CreateCollectionPageState();
}

class _CreateCollectionPageState extends State<CreateCollectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coverImageController = TextEditingController();
  bool _isPublic = true;
  bool _isSubmitting = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _coverImageController.dispose();
    super.dispose();
  }

  /// 选择封面图片
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  /// 移除封面图片
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _coverImageController.clear();
    });
  }

  /// 创建收藏夹
  Future<void> _createCollection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? coverImageUrl;
      
      // 优先上传本地图片
      if (_selectedImage != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正在上传封面图片...')),
          );
        }
        
        final uploadResponse = await ApiService.uploadImage(_selectedImage!);
        
        if (uploadResponse.isSuccess && uploadResponse.data != null) {
          coverImageUrl = uploadResponse.data;
          debugPrint('图片上传成功: $coverImageUrl');
        } else {
          // 上传失败，询问用户是否继续
          if (mounted) {
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('图片上传失败'),
                content: Text('封面图片上传失败: ${uploadResponse.message}\n\n是否继续创建收藏夹（不设置封面）？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('继续'),
                  ),
                ],
              ),
            );
            
            if (shouldContinue != true) {
              setState(() {
                _isSubmitting = false;
              });
              return;
            }
          }
        }
      } 
      // 其次使用URL输入框的值
      else if (_coverImageController.text.trim().isNotEmpty) {
        coverImageUrl = _coverImageController.text.trim();
      }

      final response = await ApiService.createCollection(
        name: _nameController.text.trim(),
        type: widget.type,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        isPublic: _isPublic,
        coverImage: coverImageUrl,
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('收藏夹创建成功')),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: ${response.message}')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMovie = widget.type == 'MOVIE';
    final color = isMovie ? Colors.red.shade400 : Colors.deepPurple.shade400;

    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: Text(isMovie ? '创建电影收藏夹' : '创建活动收藏夹'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 类型提示卡片
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isMovie ? Icons.movie : Icons.event,
                    size: 40,
                    color: color,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMovie ? '电影收藏夹' : '活动收藏夹',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isMovie ? '只能收藏电影' : '只能收藏活动',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 收藏夹名称
            Text(
              '收藏夹名称',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.capriBlue,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: isMovie ? '例如：我的科幻片单' : '例如：想参加的活动',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.muted.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.muted.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.capriBlue,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入收藏夹名称';
                }
                if (value.trim().length > 50) {
                  return '名称不能超过50个字符';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // 收藏夹描述
            Text(
              '收藏夹描述（可选）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.capriBlue,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '简单描述一下这个收藏夹...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.muted.withOpacity(0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.muted.withOpacity(0.3),
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
              validator: (value) {
                if (value != null && value.trim().length > 200) {
                  return '描述不能超过200个字符';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // 封面图片
            Text(
              '封面图片（可选）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.capriBlue,
              ),
            ),
            const SizedBox(height: 8),
            
            // 图片预览或选择按钮
            if (_selectedImage != null)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.capriBlue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.6),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            else
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.muted.withOpacity(0.3),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: AppTheme.mutedForeground,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '点击选择封面图片',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '建议尺寸：16:9',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 12),

            // 公开性设置
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.muted.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '隐私设置',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.capriBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<bool>(
                    value: true,
                    groupValue: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value!;
                      });
                    },
                    title: const Row(
                      children: [
                        Icon(Icons.public, size: 20),
                        SizedBox(width: 8),
                        Text('公开'),
                      ],
                    ),
                    subtitle: Text(
                      '所有人都可以查看这个收藏夹',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    activeColor: AppTheme.capriBlue,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<bool>(
                    value: false,
                    groupValue: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value!;
                      });
                    },
                    title: const Row(
                      children: [
                        Icon(Icons.lock_outline, size: 20),
                        SizedBox(width: 8),
                        Text('私密'),
                      ],
                    ),
                    subtitle: Text(
                      '只有你自己可以查看',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    activeColor: AppTheme.capriBlue,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 创建按钮
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _createCollection,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.capriBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppTheme.muted,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '创建收藏夹',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // 提示信息
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.softPeach.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppTheme.softPeach,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '创建后可以在收藏夹中添加${isMovie ? "电影" : "活动"}，也可以随时修改收藏夹的名称、描述和封面',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
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
}

