import 'package:flutter/material.dart';
import '../../data/home_mock_data.dart';
import '../../widgets/movie_carousel.dart';
import '../../widgets/ranking_list.dart';
import '../../widgets/section_title.dart';
import '../../widgets/movie_card.dart';

/// 主页 - 热门榜单 Tab 内容：轮播 + 本周热门 + 最新上映横向列表
class IndexRankingTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final carousel = HomeMockData.carouselMovies;
    final ranking = HomeMockData.weeklyRanking;
    final newReleases = HomeMockData.favoriteMovies;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          MovieCarouselWidget(
            movies: carousel,
            onTap: onTapCarousel != null
                ? (m) => onTapCarousel!(m.id)
                : null,
          ),
          const SizedBox(height: 20),
          RankingListWidget(
            title: '本周热门电影',
            movies: ranking,
            onMore: onMoreRanking,
            onTapMovie: onTapMovie != null
                ? (m) => onTapMovie!(m.id)
                : null,
          ),
          const SizedBox(height: 20),
          SectionTitle(
            title: '最新上映',
            onMore: onMoreNewReleases,
          ),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: newReleases.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final item = newReleases[i];
                return MovieCardWidget(
                  item: item,
                  width: 128,
                  onTap: onTapMovie != null ? () => onTapMovie!(item.id) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
