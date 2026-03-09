import 'package:flutter/material.dart';
import '../models/feed.dart';
import '../services/storage_service.dart';
import '../pages/index/movie_detail/movie_detail_page.dart';
import '../pages/index/event_detail/event_detail_page.dart';
import '../pages/profile/user_profile_page.dart';
import '../pages/index/feed_detail/feed_detail_page.dart';

/// 动态卡片组件
class FeedCardWidget extends StatelessWidget {
  final Feed feed;
  final VoidCallback? onLike;
  final VoidCallback? onDelete;
  final VoidCallback? onRefresh; // 新增：数据变化时的刷新回调

  const FeedCardWidget({
    super.key,
    required this.feed,
    this.onLike,
    this.onDelete,
    this.onRefresh,
  });

  /// 格式化时间显示
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}月${time.day}日';
    }
  }

  /// 导航到用户主页
  void _navigateToUserProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfilePage(userId: feed.user.id),
      ),
    );
  }

  /// 导航到电影详情
  void _navigateToMovieDetail(BuildContext context) {
    if (feed.movie != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MovieDetailPage(movieId: feed.movie!.tmdbId),
        ),
      );
    }
  }

  /// 导航到活动详情
  void _navigateToEventDetail(BuildContext context) {
    if (feed.event != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailPage(eventId: feed.event!.id),
        ),
      );
    }
  }

  /// 导航到动态详情（评论页）
  Future<void> _navigateToFeedDetail(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FeedDetailPage(feedId: feed.id),
      ),
    );
    
    // 如果返回 true，说明数据有变化（删除或点赞等操作）
    if (result == true && context.mounted) {
      // 如果是删除操作，调用 onDelete
      // 否则调用 onRefresh 刷新数据
      onRefresh?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户信息行
            Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToUserProfile(context),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: feed.user.fullAvatarUrl != null
                        ? NetworkImage(feed.user.fullAvatarUrl!)
                        : null,
                    child: feed.user.fullAvatarUrl == null
                        ? Text(feed.user.username[0].toUpperCase())
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToUserProfile(context),
                        child: Text(
                          feed.user.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(feed.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                FutureBuilder<int?>(
                  future: StorageService.getUserId(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(width: 48, height: 48);
                    }
                    
                    final currentUserId = snapshot.data;
                    final isOwner = currentUserId == feed.user.id;
                    
                    return PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (value) {
                        if (value == 'delete') {
                          onDelete?.call();
                        } else if (value == 'report') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('举报功能开发中')),
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        if (isOwner)
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 12),
                                Text('删除', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        if (!isOwner)
                          const PopupMenuItem<String>(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(Icons.report, size: 20),
                                SizedBox(width: 12),
                                Text('举报'),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 动态内容
            Text(
              feed.content,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),

            // 图片网格
            if (feed.fullImageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildImageGrid(context),
            ],

            // 关联电影
            if (feed.movie != null) ...[
              const SizedBox(height: 12),
              _buildMovieCard(context),
            ],

            // 关联活动
            if (feed.event != null) ...[
              const SizedBox(height: 12),
              _buildEventCard(context),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // 操作按钮行
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onLike,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          feed.isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: feed.isLiked ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          feed.likeCount > 0 ? '${feed.likeCount}' : '点赞',
                          style: TextStyle(
                            fontSize: 14,
                            color: feed.isLiked ? Colors.red : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey[300],
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _navigateToFeedDetail(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.comment_outlined, size: 20, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          feed.commentCount > 0 ? '${feed.commentCount}' : '评论',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图片网格
  Widget _buildImageGrid(BuildContext context) {
    final images = feed.fullImageUrls;
    final count = images.length;

    if (count == 1) {
      return GestureDetector(
        onTap: () => _showImageViewer(context, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            images[0],
            fit: BoxFit.cover,
            height: 200,
            width: double.infinity,
          ),
        ),
      );
    }

    // 2列布局，最多显示4张图片
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: count > 4 ? 4 : count,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _showImageViewer(context, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  images[index],
                  fit: BoxFit.cover,
                ),
                if (index == 3 && count > 4)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Text(
                        '+${count - 4}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 显示图片查看器
  void _showImageViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerPage(
          images: feed.fullImageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  /// 构建电影卡片
  Widget _buildMovieCard(BuildContext context) {
    final movie = feed.movie!;
    return InkWell(
      onTap: () => _navigateToMovieDetail(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (movie.posterUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  movie.posterUrl!,
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
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
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        movie.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// 构建活动卡片
  Widget _buildEventCard(BuildContext context) {
    final event = feed.event!;
    return InkWell(
      onTap: () => _navigateToEventDetail(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (event.fullImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  event.fullImageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            event.location!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (event.eventDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          _formatEventDate(event.eventDate!),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// 格式化活动日期
  String _formatEventDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 图片查看器页面
class ImageViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1}/${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

