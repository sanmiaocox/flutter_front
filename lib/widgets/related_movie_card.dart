import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../pages/index/movie_detail/movie_detail_page.dart';

/// 关联电影卡片组件
/// 
/// 用于在活动详情页面中显示关联的电影信息
/// 遵循DRY原则，统一管理关联电影的展示样式
class RelatedMovieCard extends StatelessWidget {
  const RelatedMovieCard({
    super.key,
    required this.movieTmdbId,
    this.movieTitle,
    this.moviePosterUrl,
  });

  final int movieTmdbId;
  final String? movieTitle;
  final String? moviePosterUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailPage(movieId: movieTmdbId),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lycheeWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.muted.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            // 电影海报或图标
            if (moviePosterUrl != null && moviePosterUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  moviePosterUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildMovieIcon(),
                ),
              )
            else
              _buildMovieIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '相关电影',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    movieTitle ?? '未知电影',
                    style: const TextStyle(
                      color: AppTheme.capriBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.mutedForeground,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建电影图标（当没有海报时使用）
  Widget _buildMovieIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.capriBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.movie,
        color: AppTheme.capriBlue,
        size: 24,
      ),
    );
  }
}

