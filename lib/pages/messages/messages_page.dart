import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../config/api_config.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../profile/user_profile_page.dart';
import 'chat_detail_page.dart';
import 'group_chat_page.dart';

/// 消息界面 — 聊天（默认）+ 通知 两个 Tab。
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        elevation: 0,
        title: const Text(
          '消息',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.softPeach,
          indicatorWeight: 3,
          labelColor: AppTheme.lycheeWhite,
          unselectedLabelColor: AppTheme.lycheeWhite.withAlpha(160),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: '聊天'),
            Tab(text: '通知'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _ChatsTab(),
          const _NotificationsTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 会话数据模型
// ─────────────────────────────────────────────────────────────

class _Conversation {
  final User friend;
  final String lastMessage;
  final DateTime lastTime;
  final int unread;
  final int conversationId;

  const _Conversation({
    required this.friend,
    required this.lastMessage,
    required this.lastTime,
    this.unread = 0,
    this.conversationId = 0,
  });
}

// ─────────────────────────────────────────────────────────────
// 聊天 Tab
// ─────────────────────────────────────────────────────────────

class _ChatsTab extends StatefulWidget {
  const _ChatsTab();

  @override
  State<_ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<_ChatsTab> {
  bool _loading = true;
  String? _error;
  List<_Conversation> _conversations = [];
  List<Map<String, dynamic>> _groups = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _loadAll(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        ApiService.getConversations(page: 0, size: 20),
        ApiService.getMyGroups(),
      ]);
      final convResp = results[0] as dynamic;
      final groupResp = results[1] as dynamic;

      List<_Conversation> conversations = [];
      if (convResp.isSuccess && convResp.data != null) {
        final content = convResp.data!['content'] as List<dynamic>? ?? [];
        conversations = content.map((item) {
          final map = item as Map<String, dynamic>;
          final otherUser = map['otherUser'] as Map<String, dynamic>;
          final friend = User(
            id: otherUser['id'] as int,
            userCode: otherUser['userCode'] as String? ?? '',
            username: otherUser['username'] as String? ?? '用户',
            phone: '',
            avatar: otherUser['avatar'] as String?,
            createdAt: '',
          );
          return _Conversation(
            friend: friend,
            lastMessage: map['lastMessage'] as String? ?? '',
            lastTime: map['lastMessageAt'] != null
                ? DateTime.parse(map['lastMessageAt'] as String)
                : DateTime.now(),
            unread: map['unreadCount'] as int? ?? 0,
            conversationId: map['conversationId'] as int? ?? 0,
          );
        }).toList();
      }

      List<Map<String, dynamic>> groups = [];
      if (groupResp.isSuccess && groupResp.data != null) {
        groups = (groupResp.data! as List<Map<String, dynamic>>);
      }

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _groups = groups;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '网络错误，请重试';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadConversations() => _loadAll();

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inHours < 24) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${t.month}/${t.day}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.capriBlue),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadConversations,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.capriBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty && _groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无会话',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Text(
              '参加活动可加入活动群聊，互相关注可发起私信',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.capriBlue,
      onRefresh: _loadAll,
      child: ListView(
        children: [
          if (_groups.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text('群聊',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.mutedForeground,
                      letterSpacing: 1)),
            ),
            ...List.generate(_groups.length, (index) {
              final g = _groups[index];
              final groupId = g['id'] as int;
              final groupName = g['name'] as String? ?? '群聊';
              final avatar = g['avatar'] as String?;
              final unread = g['unreadCount'] as int? ?? 0;
              final memberCount = g['memberCount'] as int? ?? 0;
              return Column(
                children: [
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupChatPage(
                            groupId: groupId,
                            groupName: groupName,
                            groupAvatar: avatar,
                            eventTitle: groupName,
                          ),
                        ),
                      );
                      if (mounted) _loadAll();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.muted,
                                backgroundImage: avatar != null
                                    ? NetworkImage(ApiConfig.getImageUrl(avatar))
                                    : null,
                                child: avatar == null
                                    ? const Icon(Icons.group_rounded,
                                        color: AppTheme.capriBlue, size: 24)
                                    : null,
                              ),
                              if (unread > 0)
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(minWidth: 18),
                                    height: 18,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(9),
                                      border: Border.all(
                                          color: Colors.white, width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(
                                        unread > 99 ? '99+' : '$unread',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  groupName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: unread > 0
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: AppTheme.capriBlue,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$memberCount 位成员',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.mutedForeground),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.mutedForeground, size: 20),
                        ],
                      ),
                    ),
                  ),
                  if (index < _groups.length - 1)
                    const Divider(
                        height: 1, indent: 80, color: AppTheme.muted),
                ],
              );
            }),
          ],
          if (_conversations.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text('私信',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.mutedForeground,
                      letterSpacing: 1)),
            ),
            ...List.generate(_conversations.length, (index) {
              final conv = _conversations[index];
              return Column(
                children: [
                  _ConversationTile(
                    conversation: conv,
                    timeText: _formatTime(conv.lastTime),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailPage(
                            friend: conv.friend,
                            conversationId: conv.conversationId,
                          ),
                        ),
                      );
                      if (mounted) _loadAll();
                    },
                  ),
                  if (index < _conversations.length - 1)
                    const Divider(
                        height: 1, indent: 80, color: AppTheme.muted),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final _Conversation conversation;
  final String timeText;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final friend = conversation.friend;
    final avatarUrl =
        friend.avatar != null ? ApiConfig.getImageUrl(friend.avatar!) : null;
    final hasUnread = conversation.unread > 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: hasUnread ? AppTheme.lycheeWhite : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildAvatar(avatarUrl, friend.username),
                if (hasUnread)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          conversation.unread > 99
                              ? '99+'
                              : '${conversation.unread}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          friend.username,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: AppTheme.capriBlue,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread
                              ? AppTheme.capriBlue
                              : AppTheme.mutedForeground,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    style: TextStyle(
                      fontSize: 13,
                      color: hasUnread
                          ? AppTheme.capriBlue
                          : AppTheme.mutedForeground,
                      fontWeight:
                          hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, String name) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage(url),
        backgroundColor: AppTheme.muted,
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.muted,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.capriBlue,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 通知 Tab
// ─────────────────────────────────────────────────────────────

enum _NotifType { like, comment, follow, event, system }

class _NotifItem {
  final int id;
  final _NotifType type;
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime time;
  final bool isRead;
  final int? targetId;
  final int? senderId;

  const _NotifItem({
    required this.id,
    required this.type,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.time,
    this.isRead = false,
    this.targetId,
    this.senderId,
  });
}

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  bool _loading = true;
  List<_NotifItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);

    try {
      final resp = await ApiService.getNotifications(page: 0, size: 30);
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data!;
        final content = data['content'] as List<dynamic>? ?? [];
        final list = content.map((item) {
          final map = item as Map<String, dynamic>;
          final sender = map['sender'] as Map<String, dynamic>?;
          final typeStr = map['type'] as String? ?? 'SYSTEM';
          _NotifType notifType;
          switch (typeStr) {
            case 'LIKE_FEED':
            case 'LIKE_COMMENT':
              notifType = _NotifType.like;
              break;
            case 'COMMENT_FEED':
              notifType = _NotifType.comment;
              break;
            case 'FOLLOW':
              notifType = _NotifType.follow;
              break;
            case 'EVENT_JOIN':
            case 'EVENT_QUIT':
              notifType = _NotifType.event;
              break;
            default:
              notifType = _NotifType.system;
          }
          final username = sender?['username'] as String? ?? '系统通知';
          final avatar = sender?['avatar'] as String?;
          String content2;
          switch (typeStr) {
            case 'LIKE_FEED':
              content2 = '赞了你的动态';
              break;
            case 'LIKE_COMMENT':
              content2 = '赞了你的评论';
              break;
            case 'COMMENT_FEED':
              final c = map['content'] as String?;
              content2 = '评论了你的动态${c != null ? "：$c" : ""}';
              break;
            case 'FOLLOW':
              content2 = '关注了你';
              break;
            case 'EVENT_JOIN':
              content2 = '报名了你的活动';
              break;
            case 'EVENT_QUIT':
              content2 = '退出了你的活动';
              break;
            default:
              content2 = map['content'] as String? ?? '系统通知';
          }
          return _NotifItem(
            id: map['id'] as int,
            type: notifType,
            username: username,
            avatarUrl: avatar != null ? ApiConfig.getImageUrl(avatar) : null,
            content: content2,
            time: DateTime.parse(map['createdAt'] as String),
            isRead: map['isRead'] as bool? ?? false,
            targetId: map['targetId'] as int?,
            senderId: sender?['id'] as int?,
          );
        }).toList();
        if (mounted) {
          setState(() {
            _notifications = list;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      debugPrint('加载通知失败: $e');
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }

  IconData _iconFor(_NotifType t) {
    switch (t) {
      case _NotifType.like:
        return Icons.favorite_rounded;
      case _NotifType.comment:
        return Icons.chat_bubble_rounded;
      case _NotifType.follow:
        return Icons.person_add_rounded;
      case _NotifType.event:
        return Icons.event_rounded;
      case _NotifType.system:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(_NotifType t) {
    switch (t) {
      case _NotifType.like:
        return Colors.redAccent;
      case _NotifType.comment:
        return AppTheme.capriBlue;
      case _NotifType.follow:
        return Colors.green;
      case _NotifType.event:
        return AppTheme.softPeach;
      case _NotifType.system:
        return AppTheme.mutedForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.capriBlue),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('暂无通知',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.capriBlue,
      onRefresh: _loadNotifications,
      child: Column(
        children: [
          // 全部已读按钮
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await ApiService.markAllNotificationsRead();
                    setState(() {
                      _notifications = _notifications.map((n) => _NotifItem(
                        id: n.id,
                        type: n.type,
                        username: n.username,
                        avatarUrl: n.avatarUrl,
                        content: n.content,
                        time: n.time,
                        isRead: true,
                        targetId: n.targetId,
                        senderId: n.senderId,
                      )).toList();
                    });
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: const Text('全部已读', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.capriBlue,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _notifications.length,
              separatorBuilder: (_, s) => const Divider(
                height: 1,
                indent: 72,
                color: AppTheme.muted,
              ),
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return _NotifTile(
                  notif: notif,
                  icon: _iconFor(notif.type),
                  iconColor: _colorFor(notif.type),
                  timeText: _formatTime(notif.time),
                  onTap: notif.type == _NotifType.follow && notif.senderId != null
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfilePage(userId: notif.senderId!),
                            ),
                          )
                      : null,
                  onMarkRead: () async {
                    await ApiService.markNotificationRead(notif.id);
                    setState(() {
                      _notifications[index] = _NotifItem(
                        id: notif.id,
                        type: notif.type,
                        username: notif.username,
                        avatarUrl: notif.avatarUrl,
                        content: notif.content,
                        time: notif.time,
                        isRead: true,
                        targetId: notif.targetId,
                        senderId: notif.senderId,
                      );
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final _NotifItem notif;
  final IconData icon;
  final Color iconColor;
  final String timeText;
  final VoidCallback? onTap;
  final VoidCallback onMarkRead;

  const _NotifTile({
    required this.notif,
    required this.icon,
    required this.iconColor,
    required this.timeText,
    this.onTap,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? onMarkRead,
      child: Container(
        color: notif.isRead ? Colors.transparent : AppTheme.lycheeWhite,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildAvatar(notif.avatarUrl, notif.username),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(icon, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.capriBlue),
                      children: [
                        TextSpan(
                          text: notif.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(text: notif.content),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.mutedForeground),
                  ),
                ],
              ),
            ),
            if (!notif.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: AppTheme.capriBlue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, String username) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppTheme.muted,
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.muted,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: const TextStyle(
            color: AppTheme.capriBlue,
            fontWeight: FontWeight.bold,
            fontSize: 16),
      ),
    );
  }
}
