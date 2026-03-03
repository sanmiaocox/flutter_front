import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';
import '../../models/tmdb_movie.dart';
import '../../data/home_mock_data.dart';

/// 主页 - 热门榜单 Tab 内容：轮播 + 本周热门 + 最新上映横向列表
class IndexRankingTab extends StatefulWidget {
  const IndexRankingTab({
    super.key,
    this.onTapMovie,
    this.onTapCarousel,
    this.onMoreRanking,
    this.onMoreNewReleases,
  });

  final void Function(int movieId)? onTapMovie;
  final void Function(int movieId)? onTapCarousel;
  final VoidCallback? onMoreRanking;
  final VoidCallback? onMoreNewReleases;

  @override
  State<IndexRankingTab> createState() => _IndexRankingTabState();
}

class _IndexRankingTabState extends State<IndexRankingTab> {
  bool _isLoading = true;
  String? _errorMessage;
  
  List<TmdbMovie> _popularMovies = [];
  List<TmdbMovie> _topRatedMovies = [];
  List<TmdbMovie> _nowPlayingMovies = [];

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 并行请求三个接口
      final results = await Future.wait([
        ApiService.getPopularMovies(page: 1),
        ApiService.getTopRatedMovies(page: 1),
        ApiService.getNowPlayingMovies(page: 1),
      ]);

      if (!mounted) return;

      final popularResponse = results[0];
      final topRatedResponse = results[1];
      final nowPlayingResponse = results[2];

      if (popularResponse.isSuccess && 
          topRatedResponse.isSuccess && 
          nowPlayingResponse.isSuccess) {
        setState(() {
          _popularMovies = popularResponse.data?.results ?? [];
          _topRatedMovies = topRatedResponse.data?.results ?? [];
          _nowPlayingMovies = nowPlayingResponse.data?.results ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '加载失败: ${popularResponse.message}';
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.capriBlue,
        ),
      );
    }

    if (_errorMessage != null) {
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
              _errorMessage!,
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadMovies,
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

    return RefreshIndicator(
      onRefresh: _loadMovies,
      color: AppTheme.capriBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            
            // 轮播图 - 使用热门电影
            _buildCarousel(),
            
            const SizedBox(height: 20),
            
            // 本周热门 - 使用高分电影
            _buildTopRatedSection(),
            
            const SizedBox(height: 20),
            
            // 最新上映
            _buildNowPlayingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    if (_popularMovies.isEmpty) return const SizedBox.shrink();
    
    final carouselMovies = _popularMovies.take(5).toList();
    
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: carouselMovies.length,
        itemBuilder: (context, index) {
          final movie = carouselMovies[index];
          return GestureDetector(
            onTap: widget.onTapCarousel != null 
                ? () => widget.onTapCarousel!(movie.id)
                : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    movie.getBackdropUrl() != null
                        ? Image.network(
                            movie.getBackdropUrl()!,
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
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
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
                            movie.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                movie.formattedRating,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopRatedSection() {
    if (_topRatedMovies.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '本周热门电影',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.capriBlue,
                ),
              ),
              if (widget.onMoreRanking != null)
                TextButton(
                  onPressed: widget.onMoreRanking,
                  child: Text(
                    '更多',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _topRatedMovies.take(10).length,
          itemBuilder: (context, index) {
            final movie = _topRatedMovies[index];
            return _buildRankingItem(index + 1, movie);
          },
        ),
      ],
    );
  }

  Widget _buildRankingItem(int rank, TmdbMovie movie) {
    return InkWell(
      onTap: widget.onTapMovie != null 
          ? () => widget.onTapMovie!(movie.id)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? AppTheme.softPeach : AppTheme.mutedForeground,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.getPosterUrl() != null
                  ? Image.network(
                      movie.getPosterUrl(size: 'w185')!,
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 90,
                        color: AppTheme.muted,
                        child: const Icon(Icons.movie),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 90,
                      color: AppTheme.muted,
                      child: const Icon(Icons.movie),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.formattedRating,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                      if (movie.year != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          movie.year!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.mutedForeground,
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

  Widget _buildNowPlayingSection() {
    if (_nowPlayingMovies.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '最新上映',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.capriBlue,
                ),
              ),
              if (widget.onMoreNewReleases != null)
                TextButton(
                  onPressed: widget.onMoreNewReleases,
                  child: Text(
                    '更多',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _nowPlayingMovies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final movie = _nowPlayingMovies[index];
              return _buildMovieCard(movie);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovieCard(TmdbMovie movie) {
    return GestureDetector(
      onTap: widget.onTapMovie != null 
          ? () => widget.onTapMovie!(movie.id)
          : null,
      child: SizedBox(
        width: 128,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.getPosterUrl() != null
                  ? Image.network(
                      movie.getPosterUrl(size: 'w342')!,
                      width: 128,
                      height: 170,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 128,
                        height: 170,
                        color: AppTheme.muted,
                        child: const Icon(Icons.movie, size: 48),
                      ),
                    )
                  : Container(
                      width: 128,
                      height: 170,
                      color: AppTheme.muted,
                      child: const Icon(Icons.movie, size: 48),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              movie.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  movie.formattedRating,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
