import 'package:flutter/material.dart';
import '../../data/home_mock_data.dart';
import '../../widgets/feed_card.dart';

/// 主页 - 动态 Tab 内容
class IndexFeedTab extends StatelessWidget {
  const IndexFeedTab({
    super.key,
    this.onTapMovie,
    this.onTapComment,
  });

  final void Function(int movieId)? onTapMovie;
  final void Function(FeedItem)? onTapComment;

  @override
  Widget build(BuildContext context) {
    final list = HomeMockData.feedList;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: list.length,
      itemBuilder: (context, i) {
        return FeedCardWidget(
          item: list[i],
          onTapMovie: onTapMovie,
          onTapComment: onTapComment,
        );
      },
    );
  }
}
