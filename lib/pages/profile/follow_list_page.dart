import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../mixins/auto_refresh_mixin.dart';
import '../../utils/route_observer.dart';

/// 关注列表类型
enum FollowListType {
  following, // 关注列表
  followers, // 粉丝列表
  friends,   // 好友列表
}

/// 关注/粉丝列表页面
class FollowListPage extends StatefulWidget {
  final String title;
  final int userId;
  final FollowListType listType;

  const FollowListPage({
    super.key,
    required this.title,
    required this.userId,
    required this.listType,
  });

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> 
    with RouteAware, AutoRefreshMixin {
  List<User> _users = [];
  bool _isLoading = true;
  int _currentPage = 0;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Future<void> onRefresh() async {
    debugPrint('关注列表：从子页面返回，自动刷新数据');
    await _loadUsers();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreUsers();
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
    });

    try {
      if (widget.listType == FollowListType.friends) {
        // 好友列表
        final response = await ApiService.getFriendsList(widget.userId);
        if (response.isSuccess && response.data != null && mounted) {
          setState(() {
            _users = response.data!;
            _isLoading = false;
            _hasMore = false; // 好友列表不分页
          });
        } else {
          _showError(response.message);
        }
      } else {
        // 关注或粉丝列表
        final response = widget.listType == FollowListType.following
            ? await ApiService.getFollowingList(widget.userId, page: 0, size: 20)
            : await ApiService.getFollowersList(widget.userId, page: 0, size: 20);

        if (response.isSuccess && response.data != null && mounted) {
          final content = response.data!['content'] as List<dynamic>;
          final totalPages = response.data!['totalPages'] as int;
          
          setState(() {
            _users = content.map((item) => User.fromJson(item as Map<String, dynamic>)).toList();
            _isLoading = false;
            _hasMore = _currentPage + 1 < totalPages;
          });
        } else {
          _showError(response.message);
        }
      }
    } catch (e) {
      _showError('加载失败: $e');
    }
  }

  Future<void> _loadMoreUsers() async {
    if (widget.listType == FollowListType.friends) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final response = widget.listType == FollowListType.following
          ? await ApiService.getFollowingList(widget.userId, page: nextPage, size: 20)
          : await ApiService.getFollowersList(widget.userId, page: nextPage, size: 20);

      if (response.isSuccess && response.data != null && mounted) {
        final content = response.data!['content'] as List<dynamic>;
        final totalPages = response.data!['totalPages'] as int;
        
        setState(() {
          _users.addAll(content.map((item) => User.fromJson(item as Map<String, dynamic>)).toList());
          _currentPage = nextPage;
          _isLoading = false;
          _hasMore = nextPage + 1 < totalPages;
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

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: Text(widget.title),
      ),
      body: _isLoading && _users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: AppTheme.mutedForeground.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无用户',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _users.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return _UserListItem(
                        user: _users[index],
                        currentUserId: widget.userId,
                        listType: widget.listType,
                        onFollowChanged: () {
                          // 刷新列表
                          _loadUsers();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

class _UserListItem extends StatefulWidget {
  final User user;
  final int currentUserId;
  final FollowListType listType;
  final VoidCallback onFollowChanged;

  const _UserListItem({
    required this.user,
    required this.currentUserId,
    required this.listType,
    required this.onFollowChanged,
  });

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    try {
      final response = await ApiService.getFollowStatus(widget.user.id);
      if (response.isSuccess && response.data != null && mounted) {
        setState(() {
          _isFollowing = response.data!['isFollowing'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('加载关注状态失败: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = _isFollowing
          ? await ApiService.unfollowUser(widget.user.id)
          : await ApiService.followUser(widget.user.id);

      if (response.isSuccess && mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? '已关注' : '已取消关注'),
            duration: const Duration(seconds: 1),
          ),
        );
        widget.onFollowChanged();
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 好友列表不显示关注按钮
    final showFollowButton = widget.listType != FollowListType.friends;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.capriBlue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.capriBlue,
                  AppTheme.capriBlue.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: widget.user.avatar == null || widget.user.avatar!.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : ClipOval(
                    child: Image.network(
                      widget.user.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.person, color: Colors.white, size: 28);
                      },
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.username,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.capriBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.bio ?? '这个人很懒，什么都没写',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // 关注按钮
          if (showFollowButton)
            _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isFollowing ? Colors.grey.shade300 : AppTheme.capriBlue,
                      foregroundColor:
                          _isFollowing ? AppTheme.mutedForeground : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isFollowing ? '已关注' : '关注',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
        ],
      ),
    );
  }
}
