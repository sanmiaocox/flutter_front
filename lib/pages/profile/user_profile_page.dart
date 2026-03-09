import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../models/feed.dart';
import '../../models/event.dart';
import '../../mixins/auto_refresh_mixin.dart';
import '../../utils/route_observer.dart';
import '../../widgets/feed_card_widget.dart';
import '../../widgets/event_card_common.dart';
import '../index/event_detail/event_detail_page.dart';
import 'follow_list_page.dart';

/// 其他用户主页
class UserProfilePage extends StatefulWidget {
  final int userId;

  const UserProfilePage({
    super.key,
    required this.userId,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> 
    with TickerProviderStateMixin, RouteAware, AutoRefreshMixin {
  User? _user;
  bool _isLoading = true;
  bool _isFollowing = false;
  String? _errorMessage;
  
  int _followingCount = 0;
  int _followersCount = 0;
  int _friendsCount = 0;
  
  // Tab 控制器
  late TabController _tabController;
  
  // 动态列表
  final List<Feed> _feeds = [];
  bool _isLoadingFeeds = false;
  bool _hasMoreFeeds = true;
  int _currentFeedPage = 0;
  final ScrollController _feedScrollController = ScrollController();
  
  // 活动列表
  final List<Event> _events = [];
  bool _isLoadingEvents = false;
  bool _hasMoreEvents = true;
  int _currentEventPage = 0;
  final ScrollController _eventScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadUserProfile();
    _loadFeeds();
    _feedScrollController.addListener(_onFeedScroll);
    _eventScrollController.addListener(_onEventScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscribe(routeObserver);
  }

  @override
  void dispose() {
    unsubscribe(routeObserver);
    _tabController.dispose();
    _feedScrollController.dispose();
    _eventScrollController.dispose();
    super.dispose();
  }
  
  /// Tab 切换监听
  void _onTabChanged() {
    if (_tabController.index == 1 && _events.isEmpty && !_isLoadingEvents) {
      _loadEvents();
    }
  }
  
  /// 动态列表滚动监听
  void _onFeedScroll() {
    if (_feedScrollController.position.pixels >= 
        _feedScrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingFeeds && _hasMoreFeeds) {
        _loadMoreFeeds();
      }
    }
  }
  
  /// 活动列表滚动监听
  void _onEventScroll() {
    if (_eventScrollController.position.pixels >= 
        _eventScrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingEvents && _hasMoreEvents) {
        _loadMoreEvents();
      }
    }
  }

  @override
  Future<void> onRefresh() async {
    debugPrint('用户主页：从子页面返回，自动刷新数据');
    await _loadUserProfile();
  }

  /// 加载用户信息
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getUserProfile(widget.userId);
      
      if (response.code == 200 && response.data != null) {
        setState(() {
          _user = response.data;
          _isLoading = false;
        });
        _loadUserStats();
        _checkFollowStatus();
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

  /// 检查关注状态
  Future<void> _checkFollowStatus() async {
    try {
      final response = await ApiService.getFollowStatus(widget.userId);
      if (response.code == 200 && response.data != null && mounted) {
        setState(() {
          _isFollowing = response.data!['isFollowing'] as bool? ?? false;
        });
      }
    } catch (e) {
      debugPrint('检查关注状态失败: $e');
    }
  }

  /// 加载统计数据
  Future<void> _loadUserStats() async {
    try {
      final statsResponse = await ApiService.getUserStats(widget.userId);
      if (statsResponse.isSuccess && statsResponse.data != null && mounted) {
        setState(() {
          _followingCount = statsResponse.data!.followingCount;
          _followersCount = statsResponse.data!.followerCount;
          _friendsCount = statsResponse.data!.friendCount;
        });
      }
    } catch (e) {
      debugPrint('加载统计数据失败: $e');
    }
  }

  /// 关注/取消关注
  Future<void> _toggleFollow() async {
    try {
      final response = _isFollowing
          ? await ApiService.unfollowUser(widget.userId)
          : await ApiService.followUser(widget.userId);
      
      if (response.code == 200) {
        setState(() {
          _isFollowing = !_isFollowing;
          _followersCount += _isFollowing ? 1 : -1;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isFollowing ? '关注成功' : '已取消关注')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '操作失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  /// 加载动态列表
  Future<void> _loadFeeds() async {
    if (_isLoadingFeeds) return;

    setState(() {
      _isLoadingFeeds = true;
    });

    try {
      final response = await ApiService.getUserFeeds(
        userId: widget.userId,
        page: 0,
        size: 20,
      );
      
      if (response.code == 200 && response.data != null && mounted) {
        final pageData = response.data!;
        setState(() {
          _feeds.clear();
          _feeds.addAll(pageData.content);
          _currentFeedPage = 0;
          _hasMoreFeeds = pageData.number < pageData.totalPages - 1;
          _isLoadingFeeds = false;
        });
      } else {
        setState(() {
          _isLoadingFeeds = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFeeds = false;
      });
      debugPrint('加载动态失败: $e');
    }
  }
  
  /// 加载更多动态
  Future<void> _loadMoreFeeds() async {
    if (_isLoadingFeeds || !_hasMoreFeeds) return;

    setState(() {
      _isLoadingFeeds = true;
    });

    try {
      final response = await ApiService.getUserFeeds(
        userId: widget.userId,
        page: _currentFeedPage + 1,
        size: 20,
      );
      
      if (response.code == 200 && response.data != null && mounted) {
        final pageData = response.data!;
        setState(() {
          _feeds.addAll(pageData.content);
          _currentFeedPage = pageData.number;
          _hasMoreFeeds = pageData.number < pageData.totalPages - 1;
          _isLoadingFeeds = false;
        });
      } else {
        setState(() {
          _isLoadingFeeds = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFeeds = false;
      });
    }
  }
  
  /// 加载活动列表
  Future<void> _loadEvents() async {
    if (_isLoadingEvents) return;

    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final response = await ApiService.getUserEvents(
        userId: widget.userId,
        page: 0,
        size: 20,
      );
      
      if (response.isSuccess && response.data != null && mounted) {
        final data = response.data!;
        final content = data['content'] as List<dynamic>;
        final totalPages = data['totalPages'] as int? ?? 1;
        
        setState(() {
          _events.clear();
          _events.addAll(
            content.map((item) => Event.fromJson(item as Map<String, dynamic>)).toList()
          );
          _currentEventPage = 0;
          _hasMoreEvents = _currentEventPage + 1 < totalPages;
          _isLoadingEvents = false;
        });
      } else {
        setState(() {
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingEvents = false;
      });
      debugPrint('加载活动失败: $e');
    }
  }
  
  /// 加载更多活动
  Future<void> _loadMoreEvents() async {
    if (_isLoadingEvents || !_hasMoreEvents) return;

    setState(() {
      _isLoadingEvents = true;
    });

    try {
      final response = await ApiService.getUserEvents(
        userId: widget.userId,
        page: _currentEventPage + 1,
        size: 20,
      );
      
      if (response.isSuccess && response.data != null && mounted) {
        final data = response.data!;
        final content = data['content'] as List<dynamic>;
        final totalPages = data['totalPages'] as int? ?? 1;
        
        setState(() {
          _events.addAll(
            content.map((item) => Event.fromJson(item as Map<String, dynamic>)).toList()
          );
          _currentEventPage += 1;
          _hasMoreEvents = _currentEventPage + 1 < totalPages;
          _isLoadingEvents = false;
        });
      } else {
        setState(() {
          _isLoadingEvents = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }
  
  /// 点赞动态
  Future<void> _onLikeFeed(Feed feed) async {
    try {
      final response = feed.isLiked 
          ? await ApiService.unlikeFeed(feed.id)
          : await ApiService.likeFeed(feed.id);
      
      if (response.code == 200 && response.data != null && mounted) {
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
  
  /// 删除动态
  void _onDeleteFeed(Feed feed) {
    setState(() {
      _feeds.removeWhere((f) => f.id == feed.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: Text(_user?.username ?? '用户主页'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 用户信息区域
                    _buildUserInfoSection(),
                    const SizedBox(height: 16),
                    
                    // Tab 切换栏
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.capriBlue,
                        unselectedLabelColor: AppTheme.mutedForeground,
                        indicatorColor: AppTheme.capriBlue,
                        tabs: const [
                          Tab(text: '动态'),
                          Tab(text: '活动'),
                        ],
                      ),
                    ),
                    
                    // Tab 内容区域
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFeedsTab(),
                          _buildEventsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  /// 用户信息区域
  Widget _buildUserInfoSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.capriBlue.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头像和基本信息
          Row(
            children: [
              // 头像
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.capriBlue,
                      AppTheme.capriBlue.withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.capriBlue.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _user?.avatar != null && _user!.avatar!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _user!.avatar!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: 44,
                        color: Colors.white,
                      ),
              ),
              const SizedBox(width: 16),

              // 名称和简介
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user?.username ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.capriBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ID: ${_user?.userCode ?? ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    if (_user?.bio != null && _user!.bio!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        _user!.bio!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedForeground,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 关注/取消关注按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleFollow,
              icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add),
              label: Text(_isFollowing ? '已关注' : '关注'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? AppTheme.mutedForeground : AppTheme.capriBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 关注数据
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.lycheeWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('关注', _followingCount, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowListPage(
                        title: '${_user?.username}的关注',
                        userId: widget.userId,
                        listType: FollowListType.following,
                      ),
                    ),
                  );
                }),
                _buildDivider(),
                _buildStatItem('被关注', _followersCount, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowListPage(
                        title: '${_user?.username}的粉丝',
                        userId: widget.userId,
                        listType: FollowListType.followers,
                      ),
                    ),
                  );
                }),
                _buildDivider(),
                _buildStatItem('好友', _friendsCount, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FollowListPage(
                        title: '${_user?.username}的好友',
                        userId: widget.userId,
                        listType: FollowListType.friends,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 统计项
  Widget _buildStatItem(String label, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.capriBlue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分隔线
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 32,
      color: AppTheme.muted.withOpacity(0.3),
    );
  }

  /// 动态 Tab
  Widget _buildFeedsTab() {
    if (_feeds.isEmpty && !_isLoadingFeeds) {
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

    return RefreshIndicator(
      onRefresh: _loadFeeds,
      child: ListView.builder(
        controller: _feedScrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _feeds.length + (_hasMoreFeeds ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _feeds.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final feed = _feeds[index];
          return FeedCardWidget(
            feed: feed,
            onLike: () => _onLikeFeed(feed),
            onDelete: () => _onDeleteFeed(feed),
            onRefresh: () => _loadFeeds(),
          );
        },
      ),
    );
  }
  
  /// 活动 Tab
  Widget _buildEventsTab() {
    if (_events.isEmpty && !_isLoadingEvents) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '还没有发布活动',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        controller: _eventScrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: _events.length + (_hasMoreEvents ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _events.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final event = _events[index];
          return EventCard(
            event: event,
            onTap: () {
              // 导航到活动详情页
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailPage(eventId: event.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


