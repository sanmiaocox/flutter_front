import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../data/home_mock_data.dart';
import '../../widgets/movie_card.dart';

/// 主页 - 我的收藏 Tab 内容：网格或空状态
class IndexFavoritesTab extends StatelessWidget {
  const IndexFavoritesTab({
    super.key,
    this.onTapMovie,
  });

  final void Function(int movieId)? onTapMovie;

  @override
  Widget build(BuildContext context) {
    final list = HomeMockData.favoriteMovies;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: AppTheme.muted,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无收藏',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '快去添加你喜欢的电影吧！',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '我的收藏 (${list.length})',
              style: const TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossCount = 3;
              const spacing = 12.0;
              final width =
                  (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
              return Wrap(
                spacing: spacing,
                runSpacing: 16,
                children: list.map((item) {
                  return SizedBox(
                    width: width,
                    child: MovieCardWidget(
                      item: item,
                      width: width,
                      onTap: onTapMovie != null ? () => onTapMovie!(item.id) : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
