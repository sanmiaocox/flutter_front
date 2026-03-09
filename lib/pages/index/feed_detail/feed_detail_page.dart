import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../models/feed.dart';
import '../../../models/comment.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../utils/route_observer.dart';
import '../../../widgets/feed_card_widget.dart';

/// 动态详情页面（评论页）
class FeedDetailPage extends StatefulWidget {
  final int feedId;

  const FeedDetailPage({
    super.key,
    required this.feedId,
  });

  @override
  State<FeedDetailPage> createState() => _FeedDetailPageState();
}

class _FeedDetailPageState extends State<FeedDetailPage> 
    with RouteAware, AutoRefreshMixin {
  bool _hasDataChanged = false; // 标记数据是否发生变化
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Feed? _feed;
  final List<Comment> _comments = [];
  
  bool _isLoadingFeed = true;
  bool _isLoadingComments = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeedDetail();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscribe(routeObserver);
  }

  @override
  void dispose() {
    unsubscribe(routeObserver);
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Future<void> onRefresh() async {
    debugPrint('动态详情：从子页面返回，自动刷新数据');
    await _loadFeedDetail();
  }

  /// 滚动监听
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingComments && _hasMore) {
        _loadMore();
      }
    }
  }

  /// 加载动态详情
  Future<void> _loadFeedDetail() async {
    setState(() {
      _isLoadingFeed = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getFeedDetail(widget.feedId);
      
      if (response.code == 200 && response.data != null) {
        setState(() {
          _feed = response.data;
          _isLoadingFeed = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? '加载失败';
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误: $e';
        _isLoadingFeed = false;
      });
    }
  }

  /// 加载评论列表
  Future<void> _loadComments() async {
    if (_isLoadingComments) return;

    setState(() {
      _isLoadingComments = true;
    });

    try {
      final response = await ApiService.getComments(
        feedId: widget.feedId,
        page: 0,
        size: 20,
      );
      
      if (response.code == 200 && response.data != null) {
        final pageData = response.data!;
        setState(() {
          _comments.clear();
          _comments.addAll(pageData.content);
          _currentPage = 0;
          _hasMore = pageData.number < pageData.totalPages - 1;
          _isLoadingComments = false;
        });
      } else {
        setState(() {
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  /// 加载更多评论
  Future<void> _loadMore() async {
    if (_isLoadingComments || !_hasMore) return;

    setState(() {
      _isLoadingComments = true;
    });

    try {
      final response = await ApiService.getComments(
        feedId: widget.feedId,
        page: _currentPage + 1,
        size: 20,
      );
      
      if (response.code == 200 && response.data != null) {
        final pageData = response.data!;
        setState(() {
          _comments.addAll(pageData.content);
          _currentPage = pageData.number;
          _hasMore = pageData.number < pageData.totalPages - 1;
          _isLoadingComments = false;
        });
      } else {
        setState(() {
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  /// 发表评论
  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入评论内容')),
      );
      return;
    }

    if (content.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('评论内容不能超过500字')),
      );
      return;
    }

    try {
      final response = await ApiService.createComment(
        feedId: widget.feedId,
        content: content,
      );
      
      if (response.code == 200 && response.data != null) {
        setState(() {
          _comments.insert(0, response.data!);
          _commentController.clear();
          if (_feed != null) {
            _feed = _feed!.copyWith(commentCount: _feed!.commentCount + 1);
          }
        });
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('评论成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '评论失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('评论失败: $e')),
      );
    }
  }

  /// 点赞评论
  Future<void> _onLikeComment(Comment comment) async {
    try {
      final response = comment.isLiked 
          ? await ApiService.unlikeComment(comment.id)
          : await ApiService.likeComment(comment.id);
      
      if (response.code == 200 && response.data != null) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            _comments[index] = _comments[index].copyWith(
              isLiked: response.data!.isLiked,
              likeCount: response.data!.likeCount,
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    }
  }

  /// 删除动态
  Future<void> _onDeleteFeed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条动态吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.deleteFeed(widget.feedId);
      
      if (response.code == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
          // 标记数据已变化，并返回上一页
          _hasDataChanged = true;
          Navigator.pop(context, true); // 返回上一页并传递删除成功标志
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '删除失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  /// 删除评论
  Future<void> _onDeleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条评论吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.deleteComment(comment.id);
      
      if (response.code == 200) {
        setState(() {
          _comments.removeWhere((c) => c.id == comment.id);
          if (_feed != null) {
            _feed = _feed!.copyWith(commentCount: _feed!.commentCount - 1);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('删除成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '删除失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 返回时如果数据有变化，通知上一页刷新
        if (_hasDataChanged) {
          Navigator.pop(context, true);
          return false;
        }
        return true;
      },
      child: Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: const Text('动态详情'),
      ),
      body: _isLoadingFeed
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFeedDetail,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 动态内容
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _comments.length + 1 + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // 动态卡片
                          if (index == 0) {
                            return FeedCardWidget(
                              feed: _feed!,
                              onLike: () async {
                                final response = _feed!.isLiked 
                                    ? await ApiService.unlikeFeed(_feed!.id)
                                    : await ApiService.likeFeed(_feed!.id);
                                
                                if (response.code == 200 && response.data != null) {
                                  setState(() {
                                    _feed = _feed!.copyWith(
                                      isLiked: response.data!.isLiked,
                                      likeCount: response.data!.likeCount,
                                    );
                                  });
                                  // 标记数据已变化
                                  _hasDataChanged = true;
                                }
                              },
                              onDelete: _onDeleteFeed,
                            );
                          }

                          // 加载更多指示器
                          if (index == _comments.length + 1) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          // 评论项
                          final comment = _comments[index - 1];
                          return _buildCommentItem(comment);
                        },
                      ),
                    ),

                    // 评论输入框
                    _buildCommentInput(),
                  ],
                ),
      ),
    );
  }

  /// 构建评论项
  Widget _buildCommentItem(Comment comment) {
    return FutureBuilder<int?>(
      future: StorageService.getUserId(),
      builder: (context, snapshot) {
        final currentUserId = snapshot.data;
        final isOwner = currentUserId == comment.user.id;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppTheme.muted.withValues(alpha: 0.2)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: comment.user.fullAvatarUrl != null
                    ? NetworkImage(comment.user.fullAvatarUrl!)
                    : null,
                child: comment.user.fullAvatarUrl == null
                    ? Text(comment.user.username[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.capriBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: const TextStyle(fontSize: 14, color: AppTheme.capriBlue),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _formatTime(comment.createdAt),
                          style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => _onLikeComment(comment),
                          child: Row(
                            children: [
                              Icon(
                                comment.isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: comment.isLiked ? AppTheme.softPeach : AppTheme.mutedForeground,
                              ),
                              if (comment.likeCount > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${comment.likeCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: comment.isLiked ? AppTheme.softPeach : AppTheme.mutedForeground,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 16),
                          InkWell(
                            onTap: () => _onDeleteComment(comment),
                            child: const Text(
                              '删除',
                              style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建评论输入框
  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.muted.withValues(alpha: 0.3)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: '说点什么...',
                  hintStyle: TextStyle(color: AppTheme.mutedForeground.withValues(alpha: 0.8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.lycheeWhite,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submitComment(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _submitComment,
              color: AppTheme.capriBlue,
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化时间
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
}
