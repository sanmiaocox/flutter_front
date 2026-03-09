import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/tmdb_movie.dart';
import '../../models/event.dart';

/// 发布动态页面
class CreateFeedPage extends StatefulWidget {
  final int? movieId;
  final int? eventId;

  const CreateFeedPage({
    super.key,
    this.movieId,
    this.eventId,
  });

  @override
  State<CreateFeedPage> createState() => _CreateFeedPageState();
}

class _CreateFeedPageState extends State<CreateFeedPage> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  
  bool _isSubmitting = false;
  int? _selectedMovieId;
  TmdbMovie? _selectedMovie;
  int? _selectedEventId;
  Event? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _selectedMovieId = widget.movieId;
    _selectedEventId = widget.eventId;
    if (_selectedMovieId != null) {
      _loadMovieInfo(_selectedMovieId!);
    }
    if (_selectedEventId != null) {
      _loadEventInfo(_selectedEventId!);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 加载电影信息
  Future<void> _loadMovieInfo(int movieId) async {
    try {
      final response = await ApiService.getMovieDetailByLocalId(movieId);
      if (response.code == 200 && response.data != null) {
        final tmdbId = response.data!['tmdbId'] as int;
        final detailResponse = await ApiService.getMovieDetail(tmdbId);
        if (detailResponse.code == 200 && detailResponse.data != null) {
          setState(() {
            _selectedMovie = TmdbMovie.fromJson(detailResponse.data!);
          });
        }
      }
    } catch (e) {
      debugPrint('加载电影信息失败: $e');
    }
  }

  /// 加载活动信息
  Future<void> _loadEventInfo(int eventId) async {
    try {
      final response = await ApiService.getEventDetail(eventId);
      if (response.code == 200 && response.data != null) {
        setState(() {
          _selectedEvent = response.data;
        });
      }
    } catch (e) {
      debugPrint('加载活动信息失败: $e');
    }
  }

  /// 选择图片
  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能选择4张图片')),
      );
      return;
    }

    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        final remaining = 4 - _selectedImages.length;
        final imagesToAdd = images.take(remaining).toList();
        
        setState(() {
          _selectedImages.addAll(imagesToAdd);
        });
        
        // 如果用户选择的图片超过了限制，给出提示
        if (images.length > remaining) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('最多只能选择4张图片，已自动选择前${remaining}张')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  /// 选择电影
  Future<void> _selectMovie() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const MovieSelectionDialog(),
    );
    
    if (result != null) {
      setState(() {
        _selectedMovieId = result['movieId'] as int;
        _selectedMovie = result['movie'] as TmdbMovie;
      });
    }
  }

  /// 选择活动
  Future<void> _selectEvent() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const EventSelectionDialog(),
    );
    
    if (result != null) {
      setState(() {
        _selectedEventId = result['eventId'] as int;
        _selectedEvent = result['event'] as Event;
      });
    }
  }

  /// 移除电影关联
  void _removeMovie() {
    setState(() {
      _selectedMovieId = null;
      _selectedMovie = null;
    });
  }

  /// 移除活动关联
  void _removeEvent() {
    setState(() {
      _selectedEventId = null;
      _selectedEvent = null;
    });
  }

  /// 移除图片
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// 发布动态
  Future<void> _submitFeed() async {
    final content = _contentController.text.trim();
    
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入动态内容')),
      );
      return;
    }

    if (content.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('动态内容不能超过2000字')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 先上传图片
      List<String>? imageUrls;
      if (_selectedImages.isNotEmpty) {
        imageUrls = [];
        for (final image in _selectedImages) {
          final response = await ApiService.uploadImage(File(image.path));
          if (response.code == 200 && response.data != null) {
            imageUrls.add(response.data!);
          } else {
            throw Exception('图片上传失败: ${response.message}');
          }
        }
      }

      // 发布动态
      final response = await ApiService.createFeed(
        content: content,
        images: imageUrls,
        movieId: _selectedMovieId,
        eventId: _selectedEventId,
      );

      if (response.code == 200 && response.data != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('发布成功')),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '发布失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
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
        title: const Text('发布动态'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.softPeach,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('发布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 内容输入框
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.muted.withValues(alpha: 0.3)),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                minLines: 8,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText: '分享你的想法...',
                  hintStyle: TextStyle(color: AppTheme.mutedForeground),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  counterStyle: TextStyle(color: AppTheme.mutedForeground),
                ),
                enabled: !_isSubmitting,
              ),
            ),
            const SizedBox(height: 16),

            // 图片网格 (2列布局)
            if (_selectedImages.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // 功能按钮区域
            const Text(
              '添加到动态',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.capriBlue,
              ),
            ),
            const SizedBox(height: 12),

            // 按钮行
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 添加图片按钮
                _buildActionButton(
                  icon: Icons.image_outlined,
                  label: '图片 (${_selectedImages.length}/4)',
                  onTap: _selectedImages.length < 4 && !_isSubmitting ? _pickImages : null,
                  color: AppTheme.capriBlue,
                ),
                
                // 关联电影按钮
                _buildActionButton(
                  icon: Icons.movie_outlined,
                  label: '电影',
                  onTap: !_isSubmitting ? _selectMovie : null,
                  color: Colors.orange,
                ),
                
                // 关联活动按钮
                _buildActionButton(
                  icon: Icons.event_outlined,
                  label: '活动',
                  onTap: !_isSubmitting ? _selectEvent : null,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 已关联的电影
            if (_selectedMovie != null) ...[
              _buildLinkedMovieCard(),
              const SizedBox(height: 12),
            ],

            // 已关联的活动
            if (_selectedEvent != null) ...[
              _buildLinkedEventCard(),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[200] : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDisabled ? Colors.grey[300]! : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isDisabled ? Colors.grey : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDisabled ? Colors.grey : color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建已关联的电影卡片
  Widget _buildLinkedMovieCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (_selectedMovie?.posterPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                'https://image.tmdb.org/t/p/w92${_selectedMovie!.posterPath}',
                width: 40,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 40,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.movie, color: Colors.grey),
                  );
                },
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '已关联电影',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedMovie?.title ?? '电影',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _isSubmitting ? null : _removeMovie,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  /// 构建已关联的活动卡片
  Widget _buildLinkedEventCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (_selectedEvent?.fullImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                _selectedEvent!.fullImageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.event, color: Colors.grey),
                  );
                },
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '已关联活动',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedEvent?.title ?? '活动',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _isSubmitting ? null : _removeEvent,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

/// 电影选择对话框
class MovieSelectionDialog extends StatefulWidget {
  const MovieSelectionDialog({super.key});

  @override
  State<MovieSelectionDialog> createState() => _MovieSelectionDialogState();
}

class _MovieSelectionDialogState extends State<MovieSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<TmdbMovie> _movies = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadPopularMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 加载热门电影
  Future<void> _loadPopularMovies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getPopularMovies(page: 1);
      if (response.code == 200 && response.data != null) {
        setState(() {
          _movies.clear();
          _movies.addAll(response.data!.results);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 搜索电影
  Future<void> _searchMovies(String keyword) async {
    if (keyword.trim().isEmpty) {
      _loadPopularMovies();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await ApiService.searchMovies(keyword: keyword, page: 1);
      if (response.code == 200 && response.data != null) {
        setState(() {
          _movies.clear();
          _movies.addAll(response.data!.results);
          _isSearching = false;
        });
      } else {
        setState(() {
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  /// 选择电影
  Future<void> _selectMovie(TmdbMovie movie) async {
    // 先保存电影到数据库
    final response = await ApiService.saveMovieToDatabase(movie.id);
    if (response.code == 200 && response.data != null) {
      final movieId = response.data!['id'] as int;
      Navigator.pop(context, {
        'movieId': movieId,
        'movie': movie,
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '保存电影失败')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题
            Row(
              children: [
                const Text(
                  '选择电影',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.capriBlue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 搜索框
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索电影...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadPopularMovies();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _searchMovies,
            ),
            const SizedBox(height: 16),

            // 电影列表
            Expanded(
              child: _isLoading || _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _movies.isEmpty
                      ? const Center(
                          child: Text(
                            '没有找到电影',
                            style: TextStyle(color: AppTheme.mutedForeground),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _movies.length,
                          itemBuilder: (context, index) {
                            final movie = _movies[index];
                            return _buildMovieItem(movie);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建电影项
  Widget _buildMovieItem(TmdbMovie movie) {
    return InkWell(
      onTap: () => _selectMovie(movie),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.muted.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // 海报
            if (movie.posterPath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  'https://image.tmdb.org/t/p/w92${movie.posterPath}',
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 75,
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie, color: Colors.grey),
                    );
                  },
                ),
              )
            else
              Container(
                width: 50,
                height: 75,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.movie, color: Colors.grey),
              ),
            const SizedBox(width: 12),

            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (movie.releaseDate != null && movie.releaseDate!.length >= 4)
                    Text(
                      movie.releaseDate!.substring(0, 4),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        movie.voteAverage.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
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

/// 活动选择对话框
class EventSelectionDialog extends StatefulWidget {
  const EventSelectionDialog({super.key});

  @override
  State<EventSelectionDialog> createState() => _EventSelectionDialogState();
}

class _EventSelectionDialogState extends State<EventSelectionDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Event> _myEvents = [];
  final List<Event> _joinedEvents = [];
  bool _isLoadingMy = false;
  bool _isLoadingJoined = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 加载当前用户ID
  Future<void> _loadCurrentUser() async {
    final userId = await StorageService.getUserId();
    if (userId != null) {
      setState(() {
        _currentUserId = userId;
      });
      _loadMyEvents();
      _loadJoinedEvents();
    }
  }

  /// 加载我创建的活动
  Future<void> _loadMyEvents() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoadingMy = true;
    });

    try {
      final response = await ApiService.getUserCreatedEvents(
        userId: _currentUserId!,
        page: 0,
        size: 20,
      );
      
      if (response.code == 200 && response.data != null) {
        final content = response.data!['content'] as List<dynamic>;
        setState(() {
          _myEvents.clear();
          _myEvents.addAll(
            content.map((item) => Event.fromJson(item as Map<String, dynamic>)).toList(),
          );
          _isLoadingMy = false;
        });
      } else {
        setState(() {
          _isLoadingMy = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMy = false;
      });
    }
  }

  /// 加载我参加的活动
  Future<void> _loadJoinedEvents() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoadingJoined = true;
    });

    try {
      final response = await ApiService.getUserJoinedEvents(
        userId: _currentUserId!,
        page: 0,
        size: 20,
      );
      
      if (response.code == 200 && response.data != null) {
        final content = response.data!['content'] as List<dynamic>;
        setState(() {
          _joinedEvents.clear();
          _joinedEvents.addAll(
            content.map((item) => Event.fromJson(item as Map<String, dynamic>)).toList(),
          );
          _isLoadingJoined = false;
        });
      } else {
        setState(() {
          _isLoadingJoined = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingJoined = false;
      });
    }
  }

  /// 选择活动
  void _selectEvent(Event event) {
    Navigator.pop(context, {
      'eventId': event.id,
      'event': event,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 标题
            Row(
              children: [
                const Text(
                  '选择活动',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.capriBlue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab 栏
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.capriBlue,
              unselectedLabelColor: AppTheme.mutedForeground,
              indicatorColor: AppTheme.softPeach,
              tabs: const [
                Tab(text: '我创建的'),
                Tab(text: '我参加的'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab 内容
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEventList(_myEvents, _isLoadingMy),
                  _buildEventList(_joinedEvents, _isLoadingJoined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建活动列表
  Widget _buildEventList(List<Event> events, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (events.isEmpty) {
      return const Center(
        child: Text(
          '暂无活动',
          style: TextStyle(color: AppTheme.mutedForeground),
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventItem(event);
      },
    );
  }

  /// 构建活动项
  Widget _buildEventItem(Event event) {
    return InkWell(
      onTap: () => _selectEvent(event),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.muted.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // 封面
            if (event.fullImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  event.fullImageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.event, color: Colors.grey),
                    );
                  },
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.event, color: Colors.grey),
              ),
            const SizedBox(width: 12),

            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppTheme.mutedForeground),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppTheme.mutedForeground),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(event.eventDate),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}


