import 'package:flutter/material.dart';
import '../../app_theme.dart';

/// 关注/粉丝列表页面
class FollowListPage extends StatelessWidget {
  final String title;
  final List<UserItem> users;

  const FollowListPage({
    super.key,
    required this.title,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: Text(title),
      ),
      body: users.isEmpty
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                return _UserListItem(user: users[index]);
              },
            ),
    );
  }
}

class _UserListItem extends StatefulWidget {
  final UserItem user;

  const _UserListItem({required this.user});

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.user.isFollowing;
  }

  void _toggleFollow() {
    setState(() {
      _isFollowing = !_isFollowing;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFollowing ? '已关注' : '已取消关注'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: widget.user.avatarUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : ClipOval(
                    child: Image.network(
                      widget.user.avatarUrl,
                      fit: BoxFit.cover,
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
                  widget.user.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.capriBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.bio,
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
          if (widget.user.showFollowButton)
            ElevatedButton(
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

/// 用户数据模型
class UserItem {
  final String userName;
  final String bio;
  final String avatarUrl;
  final bool isFollowing;
  final bool showFollowButton;

  UserItem({
    required this.userName,
    required this.bio,
    this.avatarUrl = '',
    this.isFollowing = false,
    this.showFollowButton = true,
  });
}


