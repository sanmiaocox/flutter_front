import 'package:flutter/material.dart';
import '../../../models/tmdb_movie.dart';
import '../../../services/api_service.dart';
import '../../index/movie_detail/movie_detail_page.dart';

/// 年代回忆杀游戏页面
/// 用户选择年代，查看该年代高分经典电影 Top10
class EraMovieGamePage extends StatefulWidget {
  const EraMovieGamePage({super.key});

  @override
  State<EraMovieGamePage> createState() => _EraMovieGamePageState();
}

class _EraMovieGamePageState extends State<EraMovieGamePage> {
  static const List<_EraOption> _eras = [
    _EraOption(
      label: '60年代', sub: '1960–1969',
      startYear: 1960, endYear: 1969,
      color: Color(0xFFD4A843), icon: '🎞️',
    ),
    _EraOption(
      label: '70年代', sub: '1970–1979',
      startYear: 1970, endYear: 1979,
      color: Color(0xFFE07B54), icon: '📽️',
    ),
    _EraOption(
      label: '80年代', sub: '1980–1989',
      startYear: 1980, endYear: 1989,
      color: Color(0xFFE91E8C), icon: '🕹️',
    ),
    _EraOption(
      label: '90年代', sub: '1990–1999',
      startYear: 1990, endYear: 1999,
      color: Color(0xFF9C27B0), icon: '📼',
    ),
    _EraOption(
      label: '00年代', sub: '2000–2009',
      startYear: 2000, endYear: 2009,
      color: Color(0xFF2196F3), icon: '💿',
    ),
    _EraOption(
      label: '10年代', sub: '2010–2019',
      startYear: 2010, endYear: 2019,
      color: Color(0xFF00BCD4), icon: '📱',
    ),
    _EraOption(
      label: '20年代', sub: '2020–至今',
      startYear: 2020, endYear: 2029,
      color: Color(0xFF4CAF50), icon: '🎬',
    ),
  ];

  int? _selectedIndex;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  List<TmdbMovie> _movies = [];
  String? _errorMsg;
  final int _starIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        _selectedIndex != null) {
      _loadMoreMovies();
    }
  }

  Future<void> _onEraTap(int index) async {
    if (_selectedIndex == index) return;
    final era = _eras[index];
    setState(() {
      _selectedIndex = index;
      _isLoading = true;
      _movies = [];
      _errorMsg = null;
      _currentPage = 1;
      _hasMore = true;
    });
    await _fetchMovies(era, page: 1, isFirstLoad: true);
  }

  Future<void> _loadMoreMovies() async {
    if (_selectedIndex == null) return;
    final era = _eras[_selectedIndex!];
    setState(() => _isLoadingMore = true);
    await _fetchMovies(era, page: _currentPage + 1, isFirstLoad: false);
  }

  Future<void> _fetchMovies(_EraOption era, {required int page, required bool isFirstLoad}) async {
    try {
      final seenIds = isFirstLoad ? <int>{} : _movies.map((m) => m.id).toSet();
      final newMovies = <TmdbMovie>[];

      // 后端只支持 primary_release_year（单年），对年代内每一年分别请求再合并
      final totalYears = era.endYear - era.startYear + 1;
      // 每次加载取年代内 min(5,totalYears) 个年份，按 page 轮转
      final yearsPerPage = totalYears <= 5 ? totalYears : 5;
      final yearOffset = ((page - 1) * yearsPerPage) % totalYears;
      final years = List.generate(
        yearsPerPage,
        (i) => era.startYear + (yearOffset + i) % totalYears,
      );

      for (final year in years) {
        final resp = await ApiService.discoverMovies(
          primaryReleaseYear: year,
          sortBy: 'popularity.desc',
          page: 1,
        );
        if (resp.isSuccess && resp.data != null) {
          for (final m in resp.data!.results) {
            if (!seenIds.contains(m.id) &&
                m.posterPath != null &&
                m.voteCount >= 50) {
              seenIds.add(m.id);
              newMovies.add(m);
            }
          }
        }
      }

      // 按人气降序排列
      newMovies.sort((a, b) => b.popularity.compareTo(a.popularity));

      // 当所有年份都已轮转一遍时，认为没有更多
      if (page * yearsPerPage >= totalYears) _hasMore = false;

      setState(() {
        if (isFirstLoad) {
          _movies = newMovies;
          _isLoading = false;
          if (newMovies.isEmpty) _errorMsg = '该年代暂无足够数据';
        } else {
          _movies = [..._movies, ...newMovies];
          _isLoadingMore = false;
          if (newMovies.isEmpty) _hasMore = false;
        }
        _currentPage = page;
      });
    } catch (e) {
      setState(() {
        if (isFirstLoad) {
          _isLoading = false;
          _errorMsg = '加载失败，请重试';
        } else {
          _isLoadingMore = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        foregroundColor: Colors.white,
        title: const Text('年代回忆杀',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('选择一个年代',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Text('看看那个年代有哪些让人难忘的经典',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          // 年代横向选择器
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _eras.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final era = _eras[index];
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () => _onEraTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? era.color
                          : era.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            era.color.withOpacity(isSelected ? 1.0 : 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: era.color.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(era.icon,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          era.label,
                          style: TextStyle(
                            color:
                                isSelected ? Colors.white : era.color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildResultArea()),
        ],
      ),
    );
  }

  Widget _buildResultArea() {
    if (_selectedIndex == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('🎬', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              '请选择一个年代\n探索那个时代的经典电影',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white38, fontSize: 15, height: 1.6),
            ),
          ],
        ),
      );
    }
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white38));
    }
    if (_errorMsg != null) {
      return Center(
          child: Text(_errorMsg!,
              style:
                  const TextStyle(color: Colors.white38, fontSize: 15)));
    }
    if (_movies.isEmpty) return const SizedBox();

    final era = _eras[_selectedIndex!];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: _movies.length + 2, // +1 header, +1 footer
      itemBuilder: (context, index) {
        // header
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: era.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${era.label} 大众热门',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  era.sub,
                  style: TextStyle(
                      color: era.color.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          );
        }
        // footer
        if (index == _movies.length + 1) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: _isLoadingMore
                  ? const CircularProgressIndicator(color: Colors.white38)
                  : _hasMore
                      ? Text('继续下拉加载更多',
                          style: TextStyle(
                              color: era.color.withOpacity(0.5),
                              fontSize: 12))
                      : const Text('已加载全部',
                          style: TextStyle(
                              color: Colors.white24, fontSize: 12)),
            ),
          );
        }

        final movieIndex = index - 1;
        final movie = _movies[movieIndex];
        final isStar = movieIndex == _starIndex;
        final posterUrl = movie.getPosterUrl(size: 'w342') ?? '';
        final rating = movie.voteAverage;
        final year = movie.year ?? '';
        final overview = movie.overview ?? '';
        // 人气数值显示
        final popularity = movie.popularity.toInt();

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + movieIndex * 60),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(30 * (1 - value), 0),
              child: child,
            ),
          ),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MovieDetailPage(movieId: movie.id),
              ),
            ),
            child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF141B2D),
              borderRadius: BorderRadius.circular(16),
              border: isStar
                  ? Border.all(
                      color: era.color.withOpacity(0.6), width: 1.5)
                  : null,
              boxShadow: isStar
                  ? [
                      BoxShadow(
                        color: era.color.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // 排名
                SizedBox(
                  width: 36,
                  child: Center(
                    child: isStar
                        ? const Text('👑',
                            style: TextStyle(fontSize: 20))
                        : Text(
                            '${movieIndex + 1}',
                            style: TextStyle(
                              color: movieIndex < 3
                                  ? era.color
                                  : Colors.white38,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // 海报
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: posterUrl.isNotEmpty
                      ? Image.network(
                          posterUrl,
                          width: 64,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildPosterPlaceholder(),
                        )
                      : _buildPosterPlaceholder(),
                ),
                const SizedBox(width: 12),
                // 信息
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isStar)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: era.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: era.color.withOpacity(0.5)),
                            ),
                            child: Text(
                              '${era.label}最热',
                              style: TextStyle(
                                color: era.color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          movie.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department,
                                size: 13, color: era.color),
                            const SizedBox(width: 3),
                            Text(
                              '热度 $popularity',
                              style: TextStyle(
                                color: era.color,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.star,
                                size: 12, color: Colors.white38),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            if (year.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(year,
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12)),
                            ],
                          ],
                        ),
                        if (overview.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            overview,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildPosterPlaceholder() {
    return Container(
      width: 64,
      height: 96,
      color: const Color(0xFF1E2A3A),
      child: const Icon(Icons.movie, color: Colors.white12, size: 28),
    );
  }
}

class _EraOption {
  final String label;
  final String sub;
  final int startYear;
  final int endYear;
  final Color color;
  final String icon;

  const _EraOption({
    required this.label,
    required this.sub,
    required this.startYear,
    required this.endYear,
    required this.color,
    required this.icon,
  });
}
