import 'package:flutter/material.dart';
import '../../../app_theme.dart';

/// 电影详情页（二级，属主页）：占位，后续接海报、简介、评分、评论等；仅展示图片与信息，无播放功能。
class MovieDetailPage extends StatelessWidget {
  const MovieDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        title: const Text('电影详情'),
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
      ),
      body: const Center(
        child: Text(
          '电影详情页待完善',
          style: TextStyle(color: AppTheme.mutedForeground),
        ),
      ),
    );
  }
}
