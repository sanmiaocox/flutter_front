import 'package:flutter/material.dart';
import '../../../models/tmdb_movie.dart';
import '../../../services/api_service.dart';

/// 评分猜猜看游戏页面
class GuessRatingGamePage extends StatefulWidget {
  const GuessRatingGamePage({super.key});

  @override
  State<GuessRatingGamePage> createState() => _GuessRatingGamePageState();
}

class _GuessRatingGamePageState extends State<GuessRatingGamePage>
    with TickerProviderStateMixin {
  TmdbMovie? _currentMovie;
  bool _isLoading = true;
  bool _hasGuessed = false;
  double _userGuess = 5.0;
  double _realRating = 0.0;
  String _feedbackText = '';
  String _feedbackEmoji = '';

  List<TmdbMovie> _moviePool = [];
  int _poolIndex = 0;

  late AnimationController _revealController;
  late Animation<double> _revealAnimation;

  int _totalRounds = 0;
  int _closeGuesses = 0;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _revealAnimation = CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    );
    _loadMoviePool();
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _loadMoviePool() async {
    setState(() => _isLoading = true);
    try {
      final popular = await ApiService.getPopularMovies(page: 1);
      final topRated = await ApiService.getTopRatedMovies(page: 1);

      final pool = <TmdbMovie>[];
      if (popular.isSuccess && popular.data != null) {
        pool.addAll(popular.data!.results
            .where((m) => m.voteAverage > 0 && m.posterPath != null));
      }
      if (topRated.isSuccess && topRated.data != null) {
        pool.addAll(topRated.data!.results
            .where((m) => m.voteAverage > 0 && m.posterPath != null));
      }
      pool.shuffle();

      setState(() {
        _moviePool = pool;
        _poolIndex = 0;
        _isLoading = false;
      });
      _nextMovie(animate: false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _nextMovie({bool animate = true}) {
    if (_moviePool.isEmpty) return;
    if (_poolIndex >= _moviePool.length) {
      _poolIndex = 0;
      _moviePool.shuffle();
    }
    setState(() {
      _currentMovie = _moviePool[_poolIndex++];
      _hasGuessed = false;
      _userGuess = 5.0;
      _realRating = _currentMovie!.voteAverage;
      _feedbackText = '';
      _feedbackEmoji = '';
    });
    _revealController.reset();
  }

  void _submitGuess() {
    if (_hasGuessed || _currentMovie == null) return;
    final diff = (_userGuess - _realRating).abs();
    String emoji;
    String text;

    if (diff <= 0.3) {
      emoji = '🎯';
      text = '完美！误差仅 ${diff.toStringAsFixed(1)} 分，你是真正的影评人！';
      _closeGuesses++;
    } else if (diff <= 0.8) {
      emoji = '🎉';
      text = '很准！只差 ${diff.toStringAsFixed(1)} 分，品味不俗！';
      _closeGuesses++;
    } else if (diff <= 1.5) {
      emoji = '😊';
      text = '还不错，差了 ${diff.toStringAsFixed(1)} 分，继续练习！';
    } else if (diff <= 3.0) {
      emoji = '😅';
      text = '差了 ${diff.toStringAsFixed(1)} 分，多看看这部电影吧！';
    } else {
      emoji = '😱';
      text = '哇，差了 ${diff.toStringAsFixed(1)} 分，要重新认识这部电影了！';
    }

    _totalRounds++;
    setState(() {
      _hasGuessed = true;
      _feedbackText = text;
      _feedbackEmoji = emoji;
    });
    _revealController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: Colors.white,
        title: const Text('评分猜猜看',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_totalRounds > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '$_closeGuesses/$_totalRounds 猜准',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)))
          : _currentMovie == null
              ? _buildEmptyState()
              : _buildGameContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white38, size: 64),
          const SizedBox(height: 16),
          const Text('加载失败', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMoviePool,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700)),
            child: const Text('重试',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    final movie = _currentMovie!;
    final posterUrl = movie.getPosterUrl(size: 'w500') ?? '';
    final year = movie.year ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            '这部电影的 TMDB 评分是多少？',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 20),
          // 电影卡片
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // 海报完整显示，宽度撑满，高度自适应
                  posterUrl.isNotEmpty
                      ? Image.network(
                          posterUrl,
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          errorBuilder: (_, __, ___) =>
                              _buildPosterPlaceholder(),
                        )
                      : _buildPosterPlaceholder(),
                  // 底部渐变遮罩
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 电影名称覆盖在底部
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (year.isNotEmpty)
                          Text(year,
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          if (!_hasGuessed) _buildGuessingArea(),
          if (_hasGuessed)
            ScaleTransition(
              scale: _revealAnimation,
              child: _buildResultArea(),
            ),
          const SizedBox(height: 24),
          if (_hasGuessed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _nextMovie(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.skip_next),
                label: const Text('下一部',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuessingArea() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('我猜：',
                style: TextStyle(color: Colors.white60, fontSize: 16)),
            Text(
              _userGuess.toStringAsFixed(1),
              style: const TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(' 分',
                style: TextStyle(color: Colors.white60, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFFFD700),
            inactiveTrackColor: Colors.white12,
            thumbColor: const Color(0xFFFFD700),
            overlayColor: const Color(0xFFFFD700).withOpacity(0.2),
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 14),
            trackHeight: 6,
          ),
          child: Slider(
            value: _userGuess,
            min: 0.0,
            max: 10.0,
            divisions: 100,
            onChanged: (v) => setState(() => _userGuess = v),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text('5', style: TextStyle(color: Colors.white38, fontSize: 12)),
            Text('10',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitGuess,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('提交猜测',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultArea() {
    final diff = (_userGuess - _realRating).abs();
    final Color resultColor = diff <= 0.8
        ? const Color(0xFF4CAF50)
        : diff <= 1.5
            ? const Color(0xFFFFD700)
            : const Color(0xFFFF6B6B);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: resultColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: resultColor.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(_feedbackEmoji,
              style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('真实评分：',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 16)),
              Text(
                _realRating.toStringAsFixed(1),
                style: TextStyle(
                  color: resultColor,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(' 分',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('你猜：',
                  style:
                      TextStyle(color: Colors.white38, fontSize: 13)),
              Text('${_userGuess.toStringAsFixed(1)} 分',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 13)),
              const Text('  |  ',
                  style: TextStyle(color: Colors.white38)),
              Text(
                '差 ${diff.toStringAsFixed(1)} 分',
                style: TextStyle(
                    color: resultColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _feedbackText,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPosterPlaceholder() {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: Container(
        color: const Color(0xFF1E2328),
        child: const Icon(Icons.movie, color: Colors.white24, size: 80),
      ),
    );
  }
}
