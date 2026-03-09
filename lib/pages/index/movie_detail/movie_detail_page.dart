import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../services/api_service.dart';
import '../../../widgets/image_viewer.dart';
import '../../../models/collection.dart';
import '../../../models/event.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../utils/route_observer.dart';
import '../event_detail/event_detail_page.dart';

/// 电影详情页（二级，属主页）：展示TMDB电影完整信息
class MovieDetailPage extends StatefulWidget {
  const MovieDetailPage({super.key, required this.movieId});

  final int movieId; // TMDB电影ID

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> 
    with RouteAware, AutoRefreshMixin {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _movieDetail;
  Map<String, dynamic>? _movieCredits;
  List<Event> _relatedEvents = [];
  bool _isLoadingEvents = false;
  bool _isWatched = false;
  bool _isFavorited = false;
  int? _localMovieId; // 本地数据库中的电影ID

  @override
  void initState() {
    super.initState();
    _loadMovieDetail();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscribe(routeObserver);
  }

  @override
  void dispose() {
    unsubscribe(routeObserver);
    super.dispose();
  }

  @override
  Future<void> onRefresh() async {
    debugPrint('电影详情：从子页面返回，自动刷新数据');
    await _loadMovieDetail();
  }

  Future<void> _loadMovieDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getMovieDetail(widget.movieId),
        ApiService.getMovieCredits(widget.movieId),
        ApiService.checkWatchedStatus(widget.movieId), // 检查是否已看过
      ]);

      if (!mounted) return;

      final detailResponse = results[0];
      final creditsResponse = results[1];
      final watchedResponse = results[2];

      if (detailResponse.isSuccess && detailResponse.data != null) {
        setState(() {
          _movieDetail = detailResponse.data;
          _movieCredits = creditsResponse.data;
          // 设置是否已看过状态
          if (watchedResponse.isSuccess && watchedResponse.data != null) {
            _isWatched = watchedResponse.data!['isWatched'] as bool? ?? false;
          }
          _isLoading = false;
        });
        
        // 加载相关活动
        _loadRelatedEvents();
      } else {
        setState(() {
          _errorMessage = '加载失败: ${detailResponse.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '网络错误: $e';
        _isLoading = false;
      });
    }
  }

  /// 加载相关活动
  Future<void> _loadRelatedEvents() async {
    setState(() {
      _isLoadingEvents = true;
    });

    try {
      // 首先保存电影到数据库，获取本地电影ID
      final saveResponse = await ApiService.saveMovieToDatabase(widget.movieId);
      
      if (saveResponse.isSuccess && saveResponse.data != null) {
        _localMovieId = saveResponse.data!['id'] as int;
        
        // 使用本地电影ID查询相关活动
        final eventsResponse = await ApiService.getEvents(
          movieId: _localMovieId,
          page: 0,
          size: 10,
        );

        if (!mounted) return;

        if (eventsResponse.isSuccess && eventsResponse.data != null) {
          final data = eventsResponse.data!;
          final content = data['content'] as List<dynamic>;
          final events = content.map((item) => Event.fromJson(item as Map<String, dynamic>)).toList();

          setState(() {
            _relatedEvents = events;
            _isLoadingEvents = false;
          });
        } else {
          setState(() {
            _isLoadingEvents = false;
          });
        }
      } else {
        setState(() {
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  void _openImageViewer(String imageUrl) {
    if (imageUrl.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ImageViewerPage(
              imageUrls: [imageUrl],
              initialIndex: 0,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('电影详情'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.capriBlue),
        ),
      );
    }

    if (_errorMessage != null || _movieDetail == null) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('电影详情'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.mutedForeground),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? '未找到电影信息',
                style: TextStyle(color: AppTheme.mutedForeground, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMovieDetail,
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

    final backdropPath = _movieDetail!['backdrop_path'] as String?;
    final backdropUrl = backdropPath != null 
        ? 'https://image.tmdb.org/t/p/w780$backdropPath' 
        : '';

    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(backdropUrl),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildMovieHeader(),
                const SizedBox(height: 16),
                _buildSynopsis(),
                const SizedBox(height: 16),
                _buildCast(),
                const SizedBox(height: 16),
                _buildRelatedEvents(),
                const SizedBox(height: 16),
                _buildActionButtons(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(String backdropUrl) {
    final title = _movieDetail!['title'] as String? ?? '未知电影';
    final voteAverage = (_movieDetail!['vote_average'] as num?)?.toDouble() ?? 0.0;

    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.capriBlue,
      foregroundColor: AppTheme.lycheeWhite,
      flexibleSpace: FlexibleSpaceBar(
        background: GestureDetector(
          onTap: () => _openImageViewer(backdropUrl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              backdropUrl.isNotEmpty
                  ? Image.network(
                      backdropUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.muted,
                        child: const Icon(Icons.movie, size: 64),
                      ),
                    )
                  : Container(
                      color: AppTheme.muted,
                      child: const Icon(Icons.movie, size: 64),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black45)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.softPeach,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TMDB',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMovieHeader() {
    final title = _movieDetail!['title'] as String? ?? '未知电影';
    final originalTitle = _movieDetail!['original_title'] as String? ?? '';
    final releaseDate = _movieDetail!['release_date'] as String? ?? '';
    final runtime = _movieDetail!['runtime'] as int? ?? 0;
    final genres = (_movieDetail!['genres'] as List?)?.map((g) => g['name'] as String).toList() ?? [];
    final voteAverage = (_movieDetail!['vote_average'] as num?)?.toDouble() ?? 0.0;
    final voteCount = _movieDetail!['vote_count'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('片名', title),
          if (originalTitle != title) ...[
            const SizedBox(height: 12),
            _buildInfoRow('原名', originalTitle),
          ],
          const SizedBox(height: 12),
          _buildInfoRow('评分', 'TMDB ${voteAverage.toStringAsFixed(1)}分 ($voteCount票)'),
          if (releaseDate.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('上映', releaseDate),
          ],
          if (runtime > 0) ...[
            const SizedBox(height: 12),
            _buildInfoRow('时长', '$runtime分钟'),
          ],
          if (genres.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow('类型', genres.join(' / ')),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            '$label：',
            style: const TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.capriBlue,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSynopsis() {
    final overview = _movieDetail!['overview'] as String? ?? '';
    if (overview.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                '剧情简介',
                style: TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            overview,
            style: const TextStyle(
              color: AppTheme.capriBlue,
              fontSize: 14,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCast() {
    if (_movieCredits == null) return const SizedBox.shrink();

    final cast = (_movieCredits!['cast'] as List?)?.take(10).toList() ?? [];
    if (cast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
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
                '演员阵容',
                style: TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: cast.length,
            itemBuilder: (context, index) {
              final actor = cast[index] as Map<String, dynamic>;
              final name = actor['name'] as String? ?? '';
              final character = actor['character'] as String? ?? '';
              final profilePath = actor['profile_path'] as String?;

              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: profilePath != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w185$profilePath',
                              width: 100,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 100,
                                height: 120,
                                color: AppTheme.muted,
                                child: const Icon(Icons.person),
                              ),
                            )
                          : Container(
                              width: 100,
                              height: 120,
                              color: AppTheme.muted,
                              child: const Icon(Icons.person),
                            ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (character.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        character,
                        style: TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 构建相关活动板块
  Widget _buildRelatedEvents() {
    if (_isLoadingEvents) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.capriBlue),
        ),
      );
    }

    if (_relatedEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
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
                '相关活动',
                style: TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_relatedEvents.length} 个活动',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _relatedEvents.length,
            itemBuilder: (context, index) {
              final event = _relatedEvents[index];
              return _EventCard(
                event: event,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventDetailPage(eventId: event.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showCollectionDialog,
              icon: Icon(_isFavorited ? Icons.favorite : Icons.favorite_border),
              label: const Text('收藏'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.capriBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isWatched ? null : _markAsWatched,
              icon: Icon(_isWatched ? Icons.check_circle : Icons.check_circle_outline),
              label: Text(_isWatched ? '已看' : '标记看过'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isWatched ? AppTheme.softPeach : AppTheme.capriBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: AppTheme.softPeach,
                disabledForegroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示收藏夹选择对话框
  Future<void> _showCollectionDialog() async {
    try {
      // 获取用户的电影收藏夹列表
      final response = await ApiService.getCollectionsByType('MOVIE');
      
      if (!response.isSuccess || response.data == null || response.data!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('您还没有创建电影收藏夹，请先创建收藏夹')),
        );
        return;
      }

      final collections = response.data!;
      
      if (!mounted) return;
      
      // 显示收藏夹选择对话框
      await showDialog(
        context: context,
        builder: (context) => _CollectionSelectionDialog(
          collections: collections,
          movieId: widget.movieId,
          onCollectionsSelected: (selectedCollections) async {
            await _addToCollections(selectedCollections);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载收藏夹失败: $e')),
      );
    }
  }

  /// 添加到多个收藏夹
  Future<void> _addToCollections(List<Collection> collections) async {
    if (collections.isEmpty) return;

    int successCount = 0;
    int failCount = 0;

    for (final collection in collections) {
      try {
        final response = await ApiService.addFavoriteItem(
          collectionId: collection.id,
          itemType: 'MOVIE',
          tmdbId: widget.movieId,  // 使用 tmdbId 而不是 itemId
        );

        if (response.isSuccess) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    if (!mounted) return;

    if (successCount > 0) {
      setState(() {
        _isFavorited = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功添加 $successCount 个到收藏夹${failCount > 0 ? '，$failCount 个失败' : ''}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('添加失败，请重试'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 标记为看过
  Future<void> _markAsWatched() async {
    try {
      final response = await ApiService.markAsWatched(
        tmdbId: widget.movieId,  // 使用 tmdbId
      );

      if (!mounted) return;

      if (response.isSuccess) {
        setState(() {
          _isWatched = true;
        });

        // 显示成功对话框
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('标记成功'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '已将《${_movieDetail!['title']}》标记为看过',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Text(
                  '您可以在个人中心的"已看片单"中查看',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('知道了'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('标记失败: ${response.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('标记失败: $e')),
      );
    }
  }
}

/// 收藏夹选择对话框
class _CollectionSelectionDialog extends StatefulWidget {
  const _CollectionSelectionDialog({
    required this.collections,
    required this.movieId,
    required this.onCollectionsSelected,
  });

  final List<Collection> collections;
  final int movieId;
  final Future<void> Function(List<Collection>) onCollectionsSelected;

  @override
  State<_CollectionSelectionDialog> createState() => _CollectionSelectionDialogState();
}

class _CollectionSelectionDialogState extends State<_CollectionSelectionDialog> {
  final Set<int> _selectedCollectionIds = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('选择收藏夹'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '可以选择多个收藏夹',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.collections.length,
                itemBuilder: (context, index) {
                  final collection = widget.collections[index];
                  final isSelected = _selectedCollectionIds.contains(collection.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCollectionIds.add(collection.id);
                        } else {
                          _selectedCollectionIds.remove(collection.id);
                        }
                      });
                    },
                    title: Text(collection.name),
                    subtitle: collection.description != null
                        ? Text(
                            collection.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.capriBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.folder,
                        color: AppTheme.capriBlue,
                      ),
                    ),
                    activeColor: AppTheme.capriBlue,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSubmitting || _selectedCollectionIds.isEmpty
              ? null
              : () async {
                  setState(() {
                    _isSubmitting = true;
                  });

                  final selectedCollections = widget.collections
                      .where((c) => _selectedCollectionIds.contains(c.id))
                      .toList();

                  await widget.onCollectionsSelected(selectedCollections);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.capriBlue,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('添加 (${_selectedCollectionIds.length})'),
        ),
      ],
    );
  }
}

/// 活动卡片组件
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    this.onTap,
  });

  final Event event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 活动封面
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  if (event.fullImageUrl != null)
                    Image.network(
                      event.fullImageUrl!,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: AppTheme.muted,
                        child: const Icon(
                          Icons.event,
                          size: 40,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 120,
                      color: AppTheme.muted,
                      child: const Icon(
                        Icons.event,
                        size: 40,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  // 状态标签
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(event.statusColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // 活动类型
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.softPeach,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 活动标题
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: AppTheme.capriBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // 活动时间
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
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 活动地点
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
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 参与人数
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 14,
                        color: AppTheme.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.participants}/${event.maxParticipants}人',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 11,
                        ),
                      ),
                      if (event.isFull) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.softPeach.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '已满',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.softPeach,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
