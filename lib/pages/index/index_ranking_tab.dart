import 'dart:async';
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
  
  List<TmdbMovie> _nowPlayingMovies = []; // 正在热映（用于轮播图）
  List<TmdbMovie> _popularMovies = []; // 热门电影（用于排行榜）
  List<TmdbMovie> _topRatedMovies = []; // 高分电影（用于高分好评）
  
  PageController? _carouselController;
  int _currentCarouselPage = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();
    _loadMovies();
  }
  
  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselController?.dispose();
    super.dispose();
  }
  
  void _startAutoPlay() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_nowPlayingMovies.isEmpty || _carouselController == null) return;
      
      final nextPage = (_currentCarouselPage + 1) % _nowPlayingMovies.take(5).length;
      _carouselController!.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 并行请求三个接口
      // 1. 获取正在热映电影（用于轮播图）
      // 2. 获取热门电影（用于排行榜）
      // 3. 获取高分电影（用于高分好评）
      final results = await Future.wait([
        ApiService.getNowPlayingMovies(page: 1),
        ApiService.getPopularMovies(page: 1),
        ApiService.getTopRatedMovies(page: 1),
      ]);

      if (!mounted) return;

      final nowPlayingResponse = results[0];
      final popularResponse = results[1];
      final topRatedResponse = results[2];

      if (nowPlayingResponse.isSuccess && 
          popularResponse.isSuccess && 
          topRatedResponse.isSuccess) {
        setState(() {
          _nowPlayingMovies = nowPlayingResponse.data?.results ?? [];
          _popularMovies = popularResponse.data?.results ?? [];
          _topRatedMovies = topRatedResponse.data?.results ?? [];
          _isLoading = false;
        });
        // 启动自动播放
        _startAutoPlay();
      } else {
        setState(() {
          _errorMessage = '加载失败: ${nowPlayingResponse.message}';
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
            
          // 轮播图 - 正在热映
          _buildCarousel(),
          
          const SizedBox(height: 24),
          
          // 热门榜单
          _buildPopularSection(),
          
          const SizedBox(height: 20),
          
          // 高分好评
          _buildTopRatedSection(),
        ],
      ),
    ),
  );
}

  Widget _buildCarousel() {
    if (_nowPlayingMovies.isEmpty) return const SizedBox.shrink();
    
    final carouselMovies = _nowPlayingMovies.take(5).toList();
    
    return Column(
      children: [
          SizedBox(
            height: 220,
          child: PageView.builder(
            controller: _carouselController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselPage = index;
              });
            },
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
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.capriBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                                Colors.black.withOpacity(0.8),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
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
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (movie.year != null) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      movie.year!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
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
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // 指示器
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            carouselMovies.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentCarouselPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentCarouselPage == index 
                    ? AppTheme.capriBlue 
                    : AppTheme.muted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopularSection() {
    if (_popularMovies.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                    '热门榜单',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.capriBlue,
                    ),
                  ),
                ],
              ),
              if (widget.onMoreRanking != null)
                TextButton.icon(
                  onPressed: widget.onMoreRanking,
                  icon: Text(
                    '更多',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                  label: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppTheme.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _popularMovies.take(10).length,
          itemBuilder: (context, index) {
            final movie = _popularMovies[index];
            return _buildRankingItem(index + 1, movie);
          },
        ),
      ],
    );
  }

  Widget _buildRankingItem(int rank, TmdbMovie movie) {
    // 前三名使用渐变色
    Color getRankColor() {
      if (rank == 1) return const Color(0xFFFFD700); // 金色
      if (rank == 2) return const Color(0xFFC0C0C0); // 银色
      if (rank == 3) return const Color(0xFFCD7F32); // 铜色
      return AppTheme.mutedForeground;
    }
    
    return InkWell(
      onTap: widget.onTapMovie != null 
          ? () => widget.onTapMovie!(movie.id)
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rank <= 3 ? getRankColor() : AppTheme.muted,
                borderRadius: BorderRadius.circular(8),
                boxShadow: rank <= 3 ? [
                  BoxShadow(
                    color: getRankColor().withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: rank <= 3 ? Colors.white : AppTheme.mutedForeground,
                  ),
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
                  const SizedBox(height: 6),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber,
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
            Icon(
              Icons.chevron_right,
              color: AppTheme.mutedForeground,
            ),
          ],
        ),
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
                    '高分好评',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.softPeach,
                    ),
                  ),
                ],
              ),
              if (widget.onMoreNewReleases != null)
                TextButton.icon(
                  onPressed: widget.onMoreNewReleases,
                  icon: Text(
                    '更多',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                  label: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppTheme.mutedForeground,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _topRatedMovies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final movie = _topRatedMovies[index];
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
      child: Container(
        width: 128,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
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
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          movie.formattedRating,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  movie.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
