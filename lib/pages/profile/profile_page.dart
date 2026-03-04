import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../app_theme.dart';
import '../../services/storage_service.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import 'edit_profile_page.dart';
import 'follow_list_page.dart';
import 'settings_page.dart';
import 'favorites/favorites_page.dart';
import 'watched_movies_page.dart';

/// 个人中心（底部导航最后一个）。
/// 包含：用户信息、收藏夹、动态、片单、小游戏等功能模块。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  // 用户数据
  User? _currentUser;
  String _userName = '加载中...';
  String _userBio = '热爱电影，享受生活 🎬';
  String _userCode = '';  // 4位数字用户识别码
  String _phone = '';
  String _avatarUrl = '';
  String? _localAvatarPath;
  bool _isLoading = true;
  
  // 统计数据
  int _followingCount = 0;
  int _followersCount = 0;
  int _friendsCount = 0;
  int _moviesWatched = 0;  // 已观看电影数量
  
  // 动画控制器
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // 下拉刷新
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadUserInfo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 加载用户信息
  Future<void> _loadUserInfo() async {
    try {
      final user = await StorageService.getUser();
      debugPrint('=== ProfilePage: 加载用户信息 ===');
      debugPrint('用户对象是否为null: ${user == null}');
      if (user != null) {
        debugPrint('用户ID: ${user.id}');
        debugPrint('用户名: ${user.username}');
        debugPrint('用户Bio: ${user.bio}');
        debugPrint('Bio是否为null: ${user.bio == null}');
        debugPrint('Bio是否为空字符串: ${user.bio?.isEmpty}');
      }
      
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _userName = user.username;
          _userCode = user.userCode;
          _phone = user.phone;
          _avatarUrl = user.avatar ?? '';
          _userBio = user.bio ?? '热爱电影，享受生活 🎬';
          _isLoading = false;
        });
        debugPrint('设置后的_userBio值: $_userBio');
        _animationController.forward();
        
        // 加载统计数据
        _loadUserStats();
      } else {
        // 没有用户信息，可能未登录
        if (mounted) {
          setState(() {
            _userName = '未登录';
            _isLoading = false;
          });
          _showLoginPrompt();
        }
      }
    } catch (e) {
      debugPrint('加载用户信息失败: $e');
      if (mounted) {
        setState(() {
          _userName = '加载失败';
          _isLoading = false;
        });
      }
    }
  }

  /// 加载用户统计数据
  Future<void> _loadUserStats() async {
    if (_currentUser == null) return;
    
    try {
      // 加载关注统计
      final statsResponse = await ApiService.getUserStats(_currentUser!.id);
      if (statsResponse.isSuccess && statsResponse.data != null && mounted) {
        setState(() {
          _followingCount = statsResponse.data!.followingCount;
          _followersCount = statsResponse.data!.followerCount;
          _friendsCount = statsResponse.data!.friendCount;
        });
      }
      
      // 加载已观看电影数量
      final watchedCountResponse = await ApiService.getWatchedMoviesCount();
      if (watchedCountResponse.isSuccess && watchedCountResponse.data != null && mounted) {
        setState(() {
          _moviesWatched = watchedCountResponse.data!;
        });
      }
    } catch (e) {
      debugPrint('加载统计数据失败: $e');
    }
  }

  /// 显示登录提示
  void _showLoginPrompt() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('未登录'),
          content: const Text('请先登录以查看个人信息'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text('去登录'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _refreshData() async {
    debugPrint('=== ProfilePage: 开始刷新数据 ===');
    // 从服务器获取最新用户信息
    final response = await ApiService.getCurrentUserProfile();
    debugPrint('刷新响应成功: ${response.isSuccess}');
    debugPrint('刷新响应数据: ${response.data}');
    
    if (response.isSuccess && response.data != null && mounted) {
      debugPrint('刷新获取的Bio: ${response.data!.bio}');
      setState(() {
        _currentUser = response.data;
        _userName = response.data!.username;
        _userCode = response.data!.userCode;
        _phone = response.data!.phone;
        _avatarUrl = response.data!.avatar ?? '';
        _userBio = response.data!.bio ?? '热爱电影，享受生活 🎬';
      });
      debugPrint('刷新后的_userBio值: $_userBio');
      // 重新加载统计数据
      await _loadUserStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据已更新'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('刷新失败: ${response.message}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _onEditProfile() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          userName: _userName,
          userBio: _userBio,
          avatarUrl: _avatarUrl,
        ),
      ),
    );

    if (result != null && result['success'] == true && mounted) {
      // 刷新用户信息
      await _refreshData();
      
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '资料更新成功'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _copyUserId() {
    Clipboard.setData(ClipboardData(text: _userCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('用户ID已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onFollowingTap() async {
    if (_currentUser == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListPage(
          title: '我的关注',
          userId: _currentUser!.id,
          listType: FollowListType.following,
        ),
      ),
    );
  }

  void _onFollowersTap() async {
    if (_currentUser == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListPage(
          title: '我的粉丝',
          userId: _currentUser!.id,
          listType: FollowListType.followers,
        ),
      ),
    );
  }

  void _onFriendsTap() async {
    if (_currentUser == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListPage(
          title: '我的好友',
          userId: _currentUser!.id,
          listType: FollowListType.friends,
        ),
      ),
    );
  }

  void _onSettingsTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SettingsPage(),
      ),
    );
  }

  void _onPublishPost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('发布动态功能开发中...')),
    );
  }

  void _onFavoritesTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FavoritesPage(),
      ),
    );
  }

  void _onPostsTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('我的动态功能开发中...')),
    );
  }

  void _onPlaylistsTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WatchedMoviesPage(),
      ),
    );
  }

  void _onGameTap(String gameName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$gameName 开发中...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在加载，显示加载指示器
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('个人中心'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.capriBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      body: RefreshIndicator(
        key: _refreshKey,
        onRefresh: _refreshData,
        color: AppTheme.capriBlue,
        child: CustomScrollView(
          slivers: [
            // 自定义 AppBar
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              backgroundColor: AppTheme.capriBlue,
              foregroundColor: AppTheme.lycheeWhite,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 28),
                onPressed: _onPublishPost,
                tooltip: '发布动态',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 26),
                  onPressed: _onSettingsTap,
                  tooltip: '设置',
                ),
                const SizedBox(width: 8),
              ],
              title: const Text(
                '个人中心',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              centerTitle: true,
            ),

            // 内容区域
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // 第一部分：用户信息卡片
                    _buildUserInfoSection(),

                    const SizedBox(height: 12),

                    // 第二部分：功能按钮区
                    _buildFunctionButtons(),

                    const SizedBox(height: 12),

                    // 第三部分：电影小游戏
                    _buildGamesSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 第一部分：用户信息
  Widget _buildUserInfoSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            AppTheme.lycheeWhite.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
              Hero(
                tag: 'user_avatar',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.capriBlue,
                        AppTheme.capriBlue.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.capriBlue.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _localAvatarPath != null
                      ? ClipOval(
                          child: Image.file(
                            File(_localAvatarPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : _avatarUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 44,
                              color: Colors.white,
                            )
                          : ClipOval(
                              child: Image.network(
                                _avatarUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                ),
              ),
              const SizedBox(width: 16),

              // 名称和ID
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _userName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.capriBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 用户ID（4位数字识别码）
                    GestureDetector(
                      onTap: _copyUserId,
                      child: Row(
                        children: [
                          Text(
                            'ID: $_userCode',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.copy,
                            size: 14,
                            color: AppTheme.mutedForeground,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // 个人简介
                    Text(
                      _userBio,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedForeground,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 编辑资料按钮
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _onEditProfile,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('编辑资料'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.capriBlue,
                side: const BorderSide(color: AppTheme.capriBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 观影统计
          GestureDetector(
            onTap: _onPlaylistsTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.softPeach.withOpacity(0.2),
                    AppTheme.capriBlue.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.movie_outlined,
                    color: AppTheme.capriBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '已观看 ',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  Text(
                    '$_moviesWatched',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.capriBlue,
                    ),
                  ),
                  Text(
                    ' 部电影',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppTheme.mutedForeground,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 关注数据
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.muted.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('关注', _followingCount, _onFollowingTap),
                _buildDivider(),
                _buildStatItem('被关注', _followersCount, _onFollowersTap),
                _buildDivider(),
                _buildStatItem('好友', _friendsCount, _onFriendsTap),
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

  /// 第二部分：功能按钮
  Widget _buildFunctionButtons() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFunctionButton(
            icon: Icons.favorite,
            label: '收藏夹',
            color: Colors.red.shade400,
            onTap: _onFavoritesTap,
          ),
          _buildFunctionButton(
            icon: Icons.article,
            label: '动态',
            color: AppTheme.capriBlue,
            onTap: _onPostsTap,
          ),
          _buildFunctionButton(
            icon: Icons.video_library,
            label: '已看片单',
            color: Colors.deepPurple.shade400,
            onTap: _onPlaylistsTap,
          ),
        ],
      ),
    );
  }

  /// 功能按钮
  Widget _buildFunctionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.2),
                    color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.capriBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 第三部分：电影小游戏
  Widget _buildGamesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.capriBlue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.games,
                color: AppTheme.softPeach,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '电影小游戏',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.capriBlue,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.softPeach.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '敬请期待',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.softPeach,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '通过趣味小游戏，测试你的电影知识！',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 16),

          // 游戏卡片网格
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildGameCard(
                icon: Icons.quiz,
                title: '电影问答',
                color: Colors.purple.shade400,
              ),
              _buildGameCard(
                icon: Icons.image_search,
                title: '猜电影',
                color: Colors.orange.shade400,
              ),
              _buildGameCard(
                icon: Icons.music_note,
                title: '听歌识影',
                color: Colors.blue.shade400,
              ),
              _buildGameCard(
                icon: Icons.emoji_emotions,
                title: '表情猜片',
                color: Colors.green.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 游戏卡片
  Widget _buildGameCard({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _onGameTap(title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
