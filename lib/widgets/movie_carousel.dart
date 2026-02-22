import 'dart:async';
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/home_mock_data.dart';

/// 轮播图：PageView + 自动切换 + 渐变 + 评分/标题/描述/查看详情。仅展示图片与信息，无播放功能。可复用。
class MovieCarouselWidget extends StatefulWidget {
  const MovieCarouselWidget({
    super.key,
    required this.movies,
    this.onTap,
  });

  final List<CarouselMovie> movies;
  final void Function(CarouselMovie)? onTap;

  @override
  State<MovieCarouselWidget> createState() => _MovieCarouselWidgetState();
}

class _MovieCarouselWidgetState extends State<MovieCarouselWidget> {
  late PageController _controller;
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    if (widget.movies.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!_controller.hasClients) return;
        final next = (_current + 1) % widget.movies.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 224,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: widget.movies.length,
            itemBuilder: (context, i) {
              final m = widget.movies[i];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CarouselItem(
                  movie: m,
                  onTap: () => widget.onTap?.call(m),
                ),
              );
            },
          ),
        ),
        if (widget.movies.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.movies.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i
                      ? AppTheme.softPeach
                      : AppTheme.muted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CarouselItem extends StatelessWidget {
  const _CarouselItem({
    required this.movie,
    this.onTap,
  });

  final CarouselMovie movie;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              movie.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppTheme.muted),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppTheme.capriBlue.withValues(alpha: 0.5),
                    AppTheme.capriBlue.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.softPeach,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 14, color: AppTheme.capriBlue),
                              const SizedBox(width: 4),
                              Text(
                                movie.rating.toString(),
                                style: const TextStyle(
                                  color: AppTheme.capriBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '热门推荐',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.softPeach,
                        foregroundColor: AppTheme.capriBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: onTap,
                      icon: const Icon(Icons.info_outline, size: 20),
                      label: const Text('查看详情'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
