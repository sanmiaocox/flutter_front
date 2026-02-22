import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/home_mock_data.dart';

/// 排行榜单行：排名徽章、海报、标题、类型、评分、涨跌。可复用。
class RankingRowWidget extends StatelessWidget {
  const RankingRowWidget({
    super.key,
    required this.movie,
    this.onTap,
  });

  final RankingMovie movie;
  final VoidCallback? onTap;

  static Color _rankBg(int rank) {
    if (rank == 1) return AppTheme.softPeach;
    if (rank == 2) return AppTheme.muted;
    if (rank == 3) return AppTheme.mutedForeground;
    return Colors.white;
  }

  static Color _rankFg(int rank) {
    if (rank == 3) return Colors.white;
    return AppTheme.capriBlue;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _rankBg(movie.rank),
                borderRadius: BorderRadius.circular(8),
                border: movie.rank > 3
                    ? Border.all(color: AppTheme.muted.withValues(alpha: 0.3))
                    : null,
              ),
              child: Text(
                '${movie.rank}',
                style: TextStyle(
                  color: _rankFg(movie.rank),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                movie.imageUrl,
                width: 48,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 64,
                  color: AppTheme.muted,
                ),
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
                      color: AppTheme.capriBlue,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        movie.genre,
                        style: const TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '⭐ ${movie.rating}',
                        style: const TextStyle(
                          color: AppTheme.softPeach,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _TrendWidget(change: movie.change),
          ],
        ),
      ),
    );
  }
}

class _TrendWidget extends StatelessWidget {
  const _TrendWidget({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.remove;
    Color color = AppTheme.mutedForeground;
    if (change > 0) {
      icon = Icons.trending_up;
      color = Colors.green;
    } else if (change < 0) {
      icon = Icons.trending_down;
      color = Colors.red;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        if (change != 0) ...[
          const SizedBox(width: 2),
          Text(
            change.abs().toString(),
            style: const TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
