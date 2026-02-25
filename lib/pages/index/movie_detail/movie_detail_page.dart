import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app_theme.dart';
import '../../../data/home_mock_data.dart';
import '../../../widgets/image_viewer.dart';
import '../event_detail/event_detail_page.dart';

/// 电影详情页（二级，属主页）：展示电影完整信息、观影团活动、外部影评链接
class MovieDetailPage extends StatefulWidget {
  const MovieDetailPage({super.key, required this.movieId});

  final int movieId;

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  late PageController _posterPageController;
  int _currentPosterIndex = 0;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  bool _isVerticalDrag = false;
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();
    _posterPageController = PageController();
  }

  @override
  void dispose() {
    _posterPageController.dispose();
    super.dispose();
  }

  void _openImageViewer(List<String> posterUrls) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ImageViewerPage(
              imageUrls: posterUrls,
              initialIndex: _currentPosterIndex,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 后续根据 movieId 从 API 获取数据，现在使用 Mock 数据
    final movie = HomeMockData.getMovieDetailById(widget.movieId);

    // 如果找不到电影数据，显示错误页面
    if (movie == null) {
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
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.mutedForeground,
              ),
              const SizedBox(height: 16),
              Text(
                '未找到电影信息',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 确保 posterUrls 不为空，如果为空则使用 posterUrl 作为默认值
    final posterUrls = movie.posterUrls.isNotEmpty 
        ? movie.posterUrls 
        : [movie.posterUrl];

    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, movie, posterUrls),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildMovieHeader(movie),
                const SizedBox(height: 16),
                _buildSynopsis(movie),
                const SizedBox(height: 16),
                _buildViewingParties(context, movie),
                const SizedBox(height: 16),
                _buildExternalReviews(movie),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MovieDetail movie, List<String> posterUrls) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.capriBlue,
      foregroundColor: AppTheme.lycheeWhite,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // 图片轮播（底层，可以横向滑动）
            PageView.builder(
              controller: _posterPageController,
              itemCount: posterUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPosterIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Image.network(
                  posterUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.muted,
                  ),
                );
              },
            ),
            // 手势检测层（只拦截垂直拖动和点击，横向滑动穿透到PageView）
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _openImageViewer(posterUrls),
              onPanStart: (details) {
                _dragStartPosition = details.globalPosition;
                _isVerticalDrag = false;
              },
              onPanUpdate: (details) {
                if (_dragStartPosition == null) return;
                
                final dx = (details.globalPosition.dx - _dragStartPosition!.dx).abs();
                final dy = details.globalPosition.dy - _dragStartPosition!.dy;
                
                // 判断是否为垂直拖动（垂直移动距离大于5）
                if (!_isVerticalDrag && dy > 5) {
                  _isVerticalDrag = true;
                  setState(() {
                    _isDragging = true;
                    _dragOffset = 0.0;
                  });
                }
                
                // 只有确认是垂直拖动时才更新偏移量
                if (_isVerticalDrag) {
                  setState(() {
                    _dragOffset = dy;
                    // 限制拖动范围，只允许向下拖动
                    if (_dragOffset < 0) _dragOffset = 0;
                    // 最大拖动距离为100像素
                    if (_dragOffset > 100) _dragOffset = 100;
                  });
                }
              },
              onPanEnd: (details) {
                if (_isVerticalDrag) {
                  // 如果拖动距离超过50像素或速度足够快，则打开图片查看器
                  if (_dragOffset > 50 || (details.velocity.pixelsPerSecond.dy > 300)) {
                    _openImageViewer(posterUrls);
                  }
                }
                setState(() {
                  _isDragging = false;
                  _dragOffset = 0.0;
                  _isVerticalDrag = false;
                  _dragStartPosition = null;
                });
              },
              onPanCancel: () {
                setState(() {
                  _isDragging = false;
                  _dragOffset = 0.0;
                  _isVerticalDrag = false;
                  _dragStartPosition = null;
                });
              },
              child: AnimatedContainer(
                duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
                transform: Matrix4.translationValues(0, _dragOffset, 0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 半透明遮罩（拖动时显示）
                    if (_isDragging && _dragOffset > 0)
                      Container(
                        color: Colors.black.withValues(alpha: _dragOffset / 100 * 0.3),
                      ),
                    // 下拉提示（拖动时显示）
                    if (_isDragging && _dragOffset > 20)
                      Positioned(
                        top: 60,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _dragOffset > 50 ? '松开查看大图' : '继续下拉',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // 图片指示器
                    if (posterUrls.length > 1 && !(_isDragging && _dragOffset > 20))
                      Positioned(
                        top: 60,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentPosterIndex + 1}/${posterUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    // 底部圆点指示器
                    if (posterUrls.length > 1)
                      Positioned(
                        bottom: 80,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              posterUrls.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPosterIndex == index
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 渐变遮罩（在最上层，但不拦截手势）
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            // 底部信息（在最上层，但不拦截手势）
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.softPeach,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                movie.rating.toString(),
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
                          movie.ratingSource,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    )
    );
  }

  Widget _buildMovieHeader(MovieDetail movie) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('片名', '${movie.title} (${movie.releaseDate.split('(')[0]})'),
          const SizedBox(height: 12),
          _buildInfoRow('别名', movie.aliases.join(' ')),
          const SizedBox(height: 12),
          _buildInfoRow('评分', '${movie.ratingSource}评分${movie.rating}分'),
          const SizedBox(height: 12),
          _buildInfoRow('上映', movie.releaseDate),
          if (movie.episodes != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('集数', movie.episodes!),
          ],
          const SizedBox(height: 12),
          _buildInfoRow('类别', movie.genres.join(' ')),
          const SizedBox(height: 12),
          _buildInfoRow('地区', movie.region),
          const SizedBox(height: 12),
          _buildInfoRow('语言', movie.languages.join(' ')),
          const SizedBox(height: 12),
          _buildInfoRow('导演', movie.directors.join(' ')),
          const SizedBox(height: 12),
          _buildInfoRow('演员', movie.actors.join(' ')),
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

  Widget _buildSynopsis(MovieDetail movie) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
            movie.synopsis,
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

  Widget _buildViewingParties(BuildContext context, MovieDetail movie) {
    if (movie.viewingParties.isEmpty) return const SizedBox.shrink();

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
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: movie.viewingParties.length,
            itemBuilder: (context, index) {
              final party = movie.viewingParties[index];
              return _buildPartyCard(party, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPartyCard(ViewingParty party, int index) {
    final colors = [
      AppTheme.capriBlue,
      AppTheme.softPeach,
      AppTheme.muted,
    ];
    final color = colors[index % colors.length];

    return InkWell(
      onTap: () {
        // 跳转到活动详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailPage(eventId: party.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '观影团',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              party.title,
              style: const TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    party.date,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    party.location,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  '${party.participants}/${party.maxParticipants}人',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExternalReviews(MovieDetail movie) {
    final reviews = movie.externalReviews;
    final items = [
      if (reviews.doubanUrl != null)
        _ReviewItem('豆瓣影评', Icons.movie, AppTheme.capriBlue, reviews.doubanUrl!),
      if (reviews.zhihuUrl != null)
        _ReviewItem('知乎评论', Icons.question_answer, AppTheme.softPeach, reviews.zhihuUrl!),
      if (reviews.imdbUrl != null)
        _ReviewItem('IMDb', Icons.star_rate, Color(0xFFF5C518), reviews.imdbUrl!),
      if (reviews.rottenTomatoesUrl != null)
        _ReviewItem('烂番茄', Icons.local_movies, Color(0xFFFA320A), reviews.rottenTomatoesUrl!),
      if (reviews.tmdbUrl != null)
        _ReviewItem('TMDB', Icons.video_library, Color(0xFF01B4E4), reviews.tmdbUrl!),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                '外部影评',
                style: TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => _buildReviewButton(item)),
        ],
      ),
    );
  }

  Widget _buildReviewButton(_ReviewItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: item.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _launchUrl(item.url),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: item.color.withValues(alpha: 0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ReviewItem {
  final String name;
  final IconData icon;
  final Color color;
  final String url;

  _ReviewItem(this.name, this.icon, this.color, this.url);
}
