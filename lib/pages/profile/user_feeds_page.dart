import 'package:flutter/material.dart';
import '../../models/feed.dart';
import '../../services/api_service.dart';
import '../../widgets/feed_card_widget.dart';

/// 用户动态列表页面
class UserFeedsPage extends StatefulWidget {
  final int userId;
  final String username;

  const UserFeedsPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<UserFeedsPage> createState() => _UserFeedsPageState();
}

class _UserFeedsPageState extends State<UserFeedsPage> {
  final List<Feed> _feeds = [];
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFeeds();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动监听
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMore();
      }
    }
  }

  /// 加载动态列表
  Future<void> _loadFeeds() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getUserFeeds(
        userId: widget.userId,
        page: 0,
        size: 20,
      );
      
      if (response.code == 200 && response.data != null) {
        final pageData = response.data!;
        setState(() {
          _feeds.clear();
          _feeds.addAll(pageData.content);
          _currentPage = 0;
          _hasMore = pageData.number < pageData.totalPages - 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? '加载失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误: $e';
        _isLoading = false;
      });
    }
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.getUserFeeds(
        userId: widget.userId,
        page: _currentPage + 1,
        size: 20,
      );
      
      if (response.code == 200 && response.data != null) {
        final pageData = response.data!;
        setState(() {
          _feeds.addAll(pageData.content);
          _currentPage = pageData.number;
          _hasMore = pageData.number < pageData.totalPages - 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 点赞动态
  Future<void> _onLike(Feed feed) async {
    try {
      final response = feed.isLiked 
          ? await ApiService.unlikeFeed(feed.id)
          : await ApiService.likeFeed(feed.id);
      
      if (response.code == 200 && response.data != null) {
        setState(() {
          final index = _feeds.indexWhere((f) => f.id == feed.id);
          if (index != -1) {
            _feeds[index] = _feeds[index].copyWith(
              isLiked: response.data!.isLiked,
              likeCount: response.data!.likeCount,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  /// 删除动态（或从详情页返回后刷新）
  void _onDelete(Feed feed) {
    // 从列表中移除该动态
    setState(() {
      _feeds.removeWhere((f) => f.id == feed.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.username}的动态'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // 错误状态
    if (_errorMessage != null && _feeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeeds,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 空状态
    if (!_isLoading && _feeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rss_feed_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '还没有发布动态',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // 列表状态
    return RefreshIndicator(
      onRefresh: _loadFeeds,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _feeds.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // 加载更多指示器
          if (index == _feeds.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final feed = _feeds[index];
          return FeedCardWidget(
            feed: feed,
            onLike: () => _onLike(feed),
            onDelete: () => _onDelete(feed),
            onRefresh: () => _loadFeeds(), // 添加刷新回调
          );
        },
      ),
    );
  }
}


