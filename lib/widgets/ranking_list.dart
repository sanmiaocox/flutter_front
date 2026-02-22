import 'package:flutter/material.dart';
import '../data/home_mock_data.dart';
import 'section_title.dart';
import 'ranking_row.dart';

/// 排行榜区块：标题 + 多行 RankingRow。可复用。
class RankingListWidget extends StatelessWidget {
  const RankingListWidget({
    super.key,
    required this.title,
    required this.movies,
    this.onMore,
    this.onTapMovie,
  });

  final String title;
  final List<RankingMovie> movies;
  final VoidCallback? onMore;
  final void Function(RankingMovie)? onTapMovie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: title, onMore: onMore),
        ...movies.map(
          (m) => RankingRowWidget(
            movie: m,
            onTap: () => onTapMovie?.call(m),
          ),
        ),
      ],
    );
  }
}
