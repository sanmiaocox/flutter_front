import 'package:flutter/material.dart';
import '../../../app_theme.dart';

/// 活动详情页（二级，属主页）：占位，后续接活动信息、报名、讨论等。
class EventDetailPage extends StatelessWidget {
  const EventDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        title: const Text('活动详情'),
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
      ),
      body: const Center(
        child: Text(
          '活动详情页待完善',
          style: TextStyle(color: AppTheme.mutedForeground),
        ),
      ),
    );
  }
}
