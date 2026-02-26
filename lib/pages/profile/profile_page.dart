import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../app_theme.dart';
import 'edit_profile_page.dart';
import 'follow_list_page.dart';

/// 个人中心（底部导航最后一个）。
/// 包含：用户信息、收藏夹、动态、片单、小游戏等功能模块。
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  // 模拟用户数据
  String _userName = '电影爱好者';
  String _userBio = '热爱电影，享受生活 🎬';
  final String _userId = 'movie_lover_2024';
  String _avatarUrl = ''; // 空字符串表示使用默认头像
  String? _localAvatarPath; // 本地头像路径
  final int _followingCount = 128;
  final int _followersCount = 256;
  final int _friendsCount = 42;
  final int _moviesWatched = 342;
  
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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    // 模拟网络请求
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        // 这里可以更新用户数据
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('数据已更新'),
          duration: Duration(seconds: 1),
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

    if (result != null && mounted) {
      setState(() {
        _userName = result['userName'] as String;
        _userBio = result['userBio'] as String;
        if (result['avatarPath'] != null) {
          _localAvatarPath = result['avatarPath'] as String;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('资料已更新')),
      );
    }
  }

  void _copyUserId() {
    Clipboard.setData(ClipboardData(text: _userId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ID已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onFollowingTap() {
    // 模拟关注列表数据
    final users = List.generate(
      10,
      (index) => UserItem(
        userName: '用户${index + 1}',
        bio: '这是用户${index + 1}的个人简介',
        isFollowing: true,
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListPage(
          title: '我的关注',
          users: users,
        ),
      ),
    );
  }

  void _onFollowersTap() {
    // 模拟粉丝列表数据
    final users = List.generate(
      15,
      (index) => UserItem(
        userName: '粉丝${index + 1}',
        bio: '这是粉丝${index + 1}的个人简介',
        isFollowing: index % 2 == 0,
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListPage(
          title: '我的粉丝',
          users: users,
        ),
      ),
    );
  }

  void _onFriendsTap() {
    // 模拟好友列表数据
    final users = List.generate(
      8,
      (index) => UserItem(
        userName: '好友${index + 1}',
        bio: '这是好友${index + 1}的个人简介',
        isFollowing: true,
        showFollowButton: false,
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListPage(
          title: '我的好友',
          users: users,
        ),
      ),
    );
  }

  void _onSettingsTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置功能开发中...')),
    );
  }

  void _onPublishPost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('发布动态功能开发中...')),
    );
  }

  void _onFavoritesTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('收藏夹功能开发中...')),
    );
  }

  void _onPostsTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('我的动态功能开发中...')),
    );
  }

  void _onPlaylistsTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('我的片单功能开发中...')),
    );
  }

  void _onGameTap(String gameName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$gameName 开发中...')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            AppTheme.lycheeWhite.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.capriBlue.withValues(alpha: 0.12),
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
                        AppTheme.capriBlue.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.capriBlue.withValues(alpha: 0.4),
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
                    // ID
                    GestureDetector(
                      onTap: _copyUserId,
                      child: Row(
                        children: [
                          Text(
                            'ID: $_userId',
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
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.softPeach.withValues(alpha: 0.2),
                  AppTheme.capriBlue.withValues(alpha: 0.1),
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
              ],
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
                color: AppTheme.muted.withValues(alpha: 0.2),
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
      color: AppTheme.muted.withValues(alpha: 0.3),
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
            color: AppTheme.capriBlue.withValues(alpha: 0.1),
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
            label: '我的片单',
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
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
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
            color: AppTheme.capriBlue.withValues(alpha: 0.08),
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
                  color: AppTheme.softPeach.withValues(alpha: 0.2),
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
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
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
