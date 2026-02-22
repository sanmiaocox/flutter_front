import 'package:flutter/material.dart';
import '../../data/home_mock_data.dart';
import '../../widgets/event_card.dart';

/// 主页 - 热门活动 Tab 内容
class IndexEventsTab extends StatelessWidget {
  const IndexEventsTab({
    super.key,
    this.onTapEvent,
    this.onJoin,
  });

  final VoidCallback? onTapEvent;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final list = HomeMockData.events;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: list.length,
      itemBuilder: (context, i) {
        return EventCardWidget(
          event: list[i],
          onTap: onTapEvent,
          onJoin: onJoin,
        );
      },
    );
  }
}
