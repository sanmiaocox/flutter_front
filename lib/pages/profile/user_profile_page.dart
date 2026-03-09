import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../../mixins/auto_refresh_mixin.dart';
import '../../utils/route_observer.dart';
import 'user_feeds_page.dart';
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
    with RouteAware, AutoRefreshMixin {
  User? _user;
  bool _isLoading = true;
  bool _isFollowing = false;
  String? _errorMessage;
  
  int _followingCount = 0;
  int _followersCount = 0;
  int _friendsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscribe(routeObserver);
  }

  @override
  void dispose() {
    unsubscribe(routeObserver);
    super.dispose();
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

  /// 查看动态
  void _viewFeeds() {
    if (_user == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFeedsPage(
          userId: widget.userId,
          username: _user!.username,
        ),
      ),
    );
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
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildUserInfoSection(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  /// 用户信息区域
  Widget _buildUserInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
              label: Text(_isFollowing ? '取消关注' : '关注'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? Colors.grey : AppTheme.capriBlue,
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

  /// 操作按钮
  Widget _buildActionButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.capriBlue.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.article, color: AppTheme.capriBlue),
            title: const Text('查看动态'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _viewFeeds,
          ),
        ],
      ),
    );
  }
}


