import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';
import '../../models/watched_movie.dart';
import '../../mixins/auto_refresh_mixin.dart';
import '../../utils/route_observer.dart';

/// 看过记录页面
class WatchedMoviesPage extends StatefulWidget {
  const WatchedMoviesPage({super.key});

  @override
  State<WatchedMoviesPage> createState() => _WatchedMoviesPageState();
}

class _WatchedMoviesPageState extends State<WatchedMoviesPage> 
    with RouteAware, AutoRefreshMixin {
  List<WatchedMovie> _watchedMovies = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWatchedMovies();
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
    debugPrint('已看片单：从子页面返回，自动刷新数据');
    await _refreshData();
  }

  /// 加载看过的电影列表
  Future<void> _loadWatchedMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getWatchedMovies();
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _watchedMovies = response.data!;
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

  /// 刷新数据
  Future<void> _refreshData() async {
    await _loadWatchedMovies();
  }

  /// 取消看过标记
  Future<void> _unmarkAsWatched(WatchedMovie movie) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要从看过列表中移除《${movie.movieInfo?['title'] ?? '未知电影'}》吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.unmarkAsWatched(movie.movieId);

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已移除')),
        );
        _refreshData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: ${response.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: $e')),
        );
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
        title: const Text('看过的电影'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.capriBlue),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : _watchedMovies.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      color: AppTheme.capriBlue,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _watchedMovies.length,
                        itemBuilder: (context, index) {
                          return _buildMovieCard(_watchedMovies[index]);
                        },
                      ),
                    ),
    );
  }

  /// 错误视图
  Widget _buildErrorView() {
    return Center(
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
            _errorMessage ?? '加载失败',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.capriBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 空状态视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            size: 80,
            color: AppTheme.mutedForeground.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            '还没有看过的电影',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '去发现页面标记看过的电影吧',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// 电影卡片
  Widget _buildMovieCard(WatchedMovie movie) {
    final movieInfo = movie.movieInfo;
    final title = movieInfo?['title'] ?? '未知电影';
    final posterUrl = movieInfo?['posterUrl'];
    final tmdbRating = movieInfo?['rating'];
    final year = movieInfo?['year'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: AppTheme.capriBlue.withOpacity(0.1),
        child: InkWell(
          onTap: () {
            // TODO: 跳转到电影详情页
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('查看《$title》详情')),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 电影海报
                Container(
                  width: 80,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppTheme.muted.withOpacity(0.2),
                  ),
                  child: posterUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.movie,
                              size: 40,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.movie,
                          size: 40,
                          color: AppTheme.mutedForeground,
                        ),
                ),
                const SizedBox(width: 16),

                // 电影信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.capriBlue,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // 年份
                      if (year != null)
                        Text(
                          year.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      const SizedBox(height: 8),

                      // TMDB评分
                      if (tmdbRating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tmdbRating.toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.mutedForeground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'TMDB',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.mutedForeground.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),

                      // 我的评分
                      if (movie.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '我的评分: ${movie.rating}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 8),

                      // 观影笔记
                      if (movie.note != null && movie.note!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.muted.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            movie.note!,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedForeground,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const SizedBox(height: 8),

                      // 观看时间
                      Text(
                        '观看于 ${_formatDate(movie.watchedAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.mutedForeground.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // 删除按钮
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppTheme.mutedForeground,
                  onPressed: () => _unmarkAsWatched(movie),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 格式化日期
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}

