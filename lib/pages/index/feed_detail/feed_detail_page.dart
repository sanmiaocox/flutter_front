import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../data/home_mock_data.dart';
import '../../../widgets/share_action_sheet.dart';
import '../../../widgets/feed_action_sheet.dart';
import '../../../widgets/report_dialog.dart';
import '../movie_detail/movie_detail_page.dart';

/// 动态详情（二级，属主页）：上半部分是动态内容，下半部分是评论，底部是评论输入栏。
class FeedDetailPage extends StatefulWidget {
  const FeedDetailPage({super.key, required this.feed});

  final FeedItem feed;

  @override
  State<FeedDetailPage> createState() => _FeedDetailPageState();
}

class _FeedDetailPageState extends State<FeedDetailPage> {
  late bool _liked;
  late int _likes;
  late List<CommentItem> _comments;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _liked = false;
    _likes = HomeMockData.likeCountForFeed(widget.feed.id);
    _comments = HomeMockData.commentsForFeed(widget.feed.id);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      if (_liked) {
        HomeMockData.addLike(widget.feed.id);
      } else {
        HomeMockData.removeLike(widget.feed.id);
      }
      _likes = HomeMockData.likeCountForFeed(widget.feed.id);
    });
  }

  void _sendComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final newComment = CommentItem(
      id: _comments.length + 1,
      userName: '我',
      userAvatar:
          'https://images.unsplash.com/photo-1763536529823-953ff472bf35?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400',
      content: text,
      timeAgo: '刚刚',
      likes: 0,
    );
    HomeMockData.addComment(widget.feed.id, newComment);
    setState(() {
      _comments = HomeMockData.commentsForFeed(widget.feed.id);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = widget.feed;
    final canSend = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: const Text('动态详情'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                children: [
                  _buildFeedContent(feed),
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.muted.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.lycheeWhite,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.muted.withValues(alpha: 0.4),
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: '说点什么...',
                          hintStyle: TextStyle(
                            color:
                                AppTheme.mutedForeground.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _sendComment(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: canSend ? _sendComment : null,
                    style: IconButton.styleFrom(
                      backgroundColor: canSend
                          ? AppTheme.capriBlue
                          : AppTheme.muted.withValues(alpha: 0.9),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedContent(FeedItem feed) {
    final shareCount = HomeMockData.shareCountForFeed(feed.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(feed.userAvatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feed.userName,
                      style: const TextStyle(
                        color: AppTheme.capriBlue,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      feed.timeAgo,
                      style: const TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz,
                    color: AppTheme.mutedForeground),
                onPressed: () {
                  FeedActionSheet.show(
                    context,
                    onReport: () {
                      ReportDialog.show(
                        context,
                        onSubmit: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('投诉已提交'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      );
                    },
                    onFavorite: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('收藏成功'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feed.content,
            style:
                const TextStyle(color: AppTheme.capriBlue, fontSize: 15),
          ),
          if (feed.movieTitle != null && feed.moviePoster != null) ...[
            const SizedBox(height: 12),
            Container(
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
                      feed.moviePoster!,
                      width: 80,
                      height: 112,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feed.movieTitle!,
                          style: const TextStyle(
                            color: AppTheme.capriBlue,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        if (feed.rating != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text('⭐',
                                  style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                feed.rating!.toString(),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: feed.movieId != null
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MovieDetailPage(
                                        movieId: feed.movieId!,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: const Text(
                            '查看详情',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.muted.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatButton(
                icon: _liked ? Icons.favorite : Icons.favorite_border,
                count: _likes,
                color: _liked ? AppTheme.softPeach : AppTheme.mutedForeground,
                onTap: _toggleLike,
              ),
              const SizedBox(width: 24),
              _buildStatButton(
                icon: Icons.chat_bubble_outline,
                count: _comments.length,
                onTap: () {},
              ),
              const SizedBox(width: 24),
              _buildStatButton(
                icon: Icons.share_outlined,
                count: shareCount,
                onTap: () {
                  ShareActionSheet.show(
                    context,
                    title: '分享动态',
                    description: feed.content,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '全部评论 (${_comments.length})',
            style: const TextStyle(
              color: AppTheme.capriBlue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          if (_comments.isEmpty)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 40, color: AppTheme.muted),
                const SizedBox(height: 8),
                Text(
                  '暂无评论，快来抢沙发吧～',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            )
          else
            Column(
              children: _comments
                  .map((c) => _CommentItemWidget(comment: c))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatButton({
    required IconData icon,
    required int count,
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? AppTheme.mutedForeground),
            const SizedBox(width: 4),
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

class _CommentItemWidget extends StatefulWidget {
  const _CommentItemWidget({required this.comment});

  final CommentItem comment;

  @override
  State<_CommentItemWidget> createState() => _CommentItemWidgetState();
}

class _CommentItemWidgetState extends State<_CommentItemWidget> {
  late bool _liked;
  late int _likes;

  @override
  void initState() {
    super.initState();
    _liked = false;
    _likes = widget.comment.likes;
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(c.userAvatar),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lycheeWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.userName,
                        style: const TextStyle(
                          color: AppTheme.capriBlue,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.content,
                        style: const TextStyle(
                          color: AppTheme.capriBlue,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      c.timeAgo,
                      style: const TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _toggleLike,
                      borderRadius: BorderRadius.circular(8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _liked ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: _liked
                                ? AppTheme.softPeach
                                : AppTheme.mutedForeground,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$_likes',
                            style: TextStyle(
                              color: _liked
                                  ? AppTheme.softPeach
                                  : AppTheme.mutedForeground,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

