import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/home_mock_data.dart';
import 'share_action_sheet.dart';

/// 动态卡片：头像、昵称、时间、内容、可选电影信息、点赞/评论/分享。可复用。
class FeedCardWidget extends StatefulWidget {
  const FeedCardWidget({
    super.key,
    required this.item,
    this.onTapMovie,
    this.onTapComment,
  });

  final FeedItem item;
  final VoidCallback? onTapMovie;
  final void Function(FeedItem)? onTapComment;

  @override
  State<FeedCardWidget> createState() => _FeedCardWidgetState();
}

class _FeedCardWidgetState extends State<FeedCardWidget> {
  late bool _liked;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _liked = false;
    _likes = HomeMockData.likeCountForFeed(widget.item.id);
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      if (_liked) {
        HomeMockData.addLike(widget.item.id);
      } else {
        HomeMockData.removeLike(widget.item.id);
      }
      _likes = HomeMockData.likeCountForFeed(widget.item.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final commentCount = HomeMockData.commentCountForFeed(item.id);
    final shareCount = HomeMockData.shareCountForFeed(item.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(item.userAvatar),
                onBackgroundImageError: (_, __) {},
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
                      style: const TextStyle(
                        color: AppTheme.capriBlue,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz, color: AppTheme.mutedForeground),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.content,
            style: const TextStyle(color: AppTheme.capriBlue, fontSize: 15),
          ),
          if (item.movieTitle != null && item.moviePoster != null) ...[
            const SizedBox(height: 12),
            _MovieInline(
              title: item.movieTitle!,
              posterUrl: item.moviePoster!,
              rating: item.rating,
              onTap: widget.onTapMovie,
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.muted.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionButton(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                count: _likes,
                color: _liked ? AppTheme.softPeach : AppTheme.mutedForeground,
                onTap: _toggleLike,
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                count: commentCount,
                onTap: () => widget.onTapComment?.call(item),
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icons.share_outlined,
                count: shareCount,
                onTap: () {
                  ShareActionSheet.show(
                    context,
                    title: '分享动态',
                    description: item.content,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovieInline extends StatelessWidget {
  const _MovieInline({
    required this.title,
    required this.posterUrl,
    this.rating,
    this.onTap,
  });

  final String title;
  final String posterUrl;
  final double? rating;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lycheeWhite,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                posterUrl,
                width: 80,
                height: 112,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 112,
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
                    title,
                    style: const TextStyle(
                      color: AppTheme.capriBlue,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  if (rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          rating!.toString(),
                          style: const TextStyle(
                            color: AppTheme.softPeach,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.capriBlue,
                      foregroundColor: AppTheme.lycheeWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: onTap,
                    child: const Text('查看详情', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.count,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final int count;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? AppTheme.mutedForeground),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color ?? AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
