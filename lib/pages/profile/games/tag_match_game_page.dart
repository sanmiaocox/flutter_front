import 'dart:math';
import 'package:flutter/material.dart';
import '../../../models/tmdb_movie.dart';
import '../../../services/api_service.dart';
import '../../index/movie_detail/movie_detail_page.dart';

/// 电影标签匹配游戏页面
class TagMatchGamePage extends StatefulWidget {
  const TagMatchGamePage({super.key});

  @override
  State<TagMatchGamePage> createState() => _TagMatchGamePageState();
}

class _TagMatchGamePageState extends State<TagMatchGamePage>
    with SingleTickerProviderStateMixin {
  static const List<_TagPreset> _presets = [
    _TagPreset(
      label: '🚀 科幻·高分', emoji: '🚀', name: '科幻·高分',
      genreIds: '878', minRating: 7.5, sortBy: 'vote_average.desc',
      color: Color(0xFF3A86FF),
    ),
    _TagPreset(
      label: '😂 喜剧·轻松', emoji: '😂', name: '喜剧·轻松',
      genreIds: '35', minRating: 6.5, sortBy: 'popularity.desc',
      color: Color(0xFFFF9F1C),
    ),
    _TagPreset(
      label: '💕 爱情·经典', emoji: '💕', name: '爱情·经典',
      genreIds: '10749', minRating: 7.0, sortBy: 'vote_average.desc',
      color: Color(0xFFFF6B9D),
    ),
    _TagPreset(
      label: '🎬 剧情·神作', emoji: '🎬', name: '剧情·神作',
      genreIds: '18', minRating: 8.0, sortBy: 'vote_average.desc',
      color: Color(0xFF8338EC),
    ),
    _TagPreset(
      label: '⚡ 动作·爽片', emoji: '⚡', name: '动作·爽片',
      genreIds: '28', minRating: 7.0, sortBy: 'popularity.desc',
      color: Color(0xFFFF4444),
    ),
    _TagPreset(
      label: '🧩 悬疑·烧脑', emoji: '🧩', name: '悬疑·烧脑',
      genreIds: '9648', minRating: 7.5, sortBy: 'vote_average.desc',
      color: Color(0xFF2EC4B6),
    ),
    _TagPreset(
      label: '🧙 奇幻·冒险', emoji: '🧙', name: '奇幻·冒险',
      genreIds: '14,12', minRating: 7.0, sortBy: 'vote_average.desc',
      color: Color(0xFF06D6A0),
    ),
    _TagPreset(
      label: '😰 惊悚·恐怖', emoji: '😰', name: '惊悚·恐怖',
      genreIds: '53,27', minRating: 6.5, sortBy: 'popularity.desc',
      color: Color(0xFF6C757D),
    ),
  ];

  int? _selectedIndex;
  bool _isLoading = false;
  List<TmdbMovie> _results = [];
  String? _errorMsg;

  Future<void> _onPresetTap(int index) async {
    // 同一标签再次点击也刷新（随机新结果）
    final preset = _presets[index];
    setState(() {
      _selectedIndex = index;
      _isLoading = true;
      _results = [];
      _errorMsg = null;
    });

    try {
      // 随机选取第 1-5 页，让每次结果不同
      final randomPage = Random().nextInt(5) + 1;
      final response = await ApiService.discoverMovies(
        withGenres: preset.genreIds,
        voteAverageGte: preset.minRating,
        sortBy: preset.sortBy,
        page: randomPage,
      );

      if (response.isSuccess && response.data != null) {
        final all = response.data!.results
            .where((m) => m.posterPath != null)
            .toList();
        // 打乱后取6部，保证每次顺序也不同
        all.shuffle();
        setState(() {
          _results = all.take(6).toList();
          _isLoading = false;
        });
      } else {
        // 若随机页无数据则退回第1页
        final fallback = await ApiService.discoverMovies(
          withGenres: preset.genreIds,
          voteAverageGte: preset.minRating,
          sortBy: preset.sortBy,
          page: 1,
        );
        if (fallback.isSuccess && fallback.data != null) {
          final all = fallback.data!.results
              .where((m) => m.posterPath != null)
              .toList();
          all.shuffle();
          setState(() {
            _results = all.take(6).toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMsg = '暂无匹配电影';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = '加载失败，请稍后重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1923),
        foregroundColor: Colors.white,
        title: const Text('电影标签匹配',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择你的心情标签',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '点击标签，发现专属于你此刻的电影',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.4,
                    ),
                    itemCount: _presets.length,
                    itemBuilder: (context, index) {
                      final preset = _presets[index];
                      final isSelected = _selectedIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _onPresetTap(index),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? preset.color
                                    : preset.color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: preset.color.withOpacity(
                                      isSelected ? 1.0 : 0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color:
                                              preset.color.withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  preset.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : preset.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 结果标题
          if (_selectedIndex != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _presets[_selectedIndex!].color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_presets[_selectedIndex!].name} 推荐',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    // 换一批按钮
                    if (!_isLoading)
                      GestureDetector(
                        onTap: () => _onPresetTap(_selectedIndex!),
                        child: Row(
                          children: [
                            Icon(
                              Icons.refresh,
                              size: 15,
                              color: _presets[_selectedIndex!].color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '换一批',
                              style: TextStyle(
                                color: _presets[_selectedIndex!].color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                    child: CircularProgressIndicator(color: Colors.white54)),
              ),
            )
          else if (_errorMsg != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(_errorMsg!,
                      style: const TextStyle(color: Colors.white38)),
                ),
              ),
            )
          else if (_results.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final movie = _results[index];
                    final posterUrl =
                        movie.getPosterUrl(size: 'w342') ?? '';
                    final accentColor = _presets[_selectedIndex!].color;

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration:
                          Duration(milliseconds: 300 + index * 80),
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
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
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF1A2332),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: posterUrl.isNotEmpty
                                  ? Image.network(
                                      posterUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    movie.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.star,
                                          size: 11, color: accentColor),
                                      const SizedBox(width: 2),
                                      Text(
                                        movie.voteAverage
                                            .toStringAsFixed(1),
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
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
                  childCount: _results.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1A2332),
      child: const Center(
          child: Icon(Icons.movie, color: Colors.white12, size: 36)),
    );
  }
}

class _TagPreset {
  final String label;
  final String emoji;
  final String name;
  final String genreIds;
  final double minRating;
  final String sortBy;
  final Color color;

  const _TagPreset({
    required this.label,
    required this.emoji,
    required this.name,
    required this.genreIds,
    required this.minRating,
    required this.sortBy,
    required this.color,
  });
}
