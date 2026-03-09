import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../models/event.dart';
import '../../../models/event_participant.dart';
import '../../../models/user.dart';
import '../../../widgets/related_movie_card.dart';
import '../profile/user_profile_page.dart';

/// 我参与的活动详情页
/// 
/// 功能：
/// - 显示活动完整信息
/// - 显示我的报名信息
/// - 退出活动
/// - 联系发起人
/// - 分享活动
/// - 查看其他参与者
class MyJoinedEventDetailPage extends StatefulWidget {
  const MyJoinedEventDetailPage({
    super.key,
    required this.eventId,
  });

  final int eventId;

  @override
  State<MyJoinedEventDetailPage> createState() => _MyJoinedEventDetailPageState();
}

class _MyJoinedEventDetailPageState extends State<MyJoinedEventDetailPage> {
  Event? _event;
  EventParticipant? _myParticipation;
  List<EventParticipant> _allParticipants = []; // 所有参与者（包括自己）
  User? _creator;
  bool _isLoading = true;
  String? _errorMessage;
  
  // 关注状态管理
  final Map<int, bool> _followStatusMap = {}; // 用户ID -> 是否已关注
  final Set<int> _loadingFollowIds = {}; // 正在加载关注状态的用户ID

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载活动详情和参与信息
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 获取当前用户
      final currentUser = await StorageService.getUser();
      if (currentUser == null) {
        setState(() {
          _errorMessage = '请先登录';
          _isLoading = false;
        });
        return;
      }

      // 加载活动详情和参与人列表
      final results = await Future.wait([
        ApiService.getEventDetail(widget.eventId),
        ApiService.getEventParticipants(widget.eventId),
      ]);

      final eventResponse = results[0] as dynamic;
      final participantsResponse = results[1] as dynamic;

      if (eventResponse.isSuccess && eventResponse.data != null) {
        final event = eventResponse.data as Event;
        setState(() {
          _event = event;
        });

        // 加载发起人信息
        if (event.creatorId != null) {
          final creatorResponse = await ApiService.getUserProfile(event.creatorId!);
          if (creatorResponse.isSuccess && creatorResponse.data != null) {
            setState(() {
              _creator = creatorResponse.data;
            });
            // 检查发起人的关注状态
            _checkFollowStatus(event.creatorId!);
          }
        }
      } else {
        setState(() {
          _errorMessage = eventResponse.message;
        });
      }

      if (participantsResponse.isSuccess && participantsResponse.data != null) {
        final participants = participantsResponse.data as List<EventParticipant>;
        
        // 找出我的报名信息
        final myParticipation = participants.firstWhere(
          (p) => p.userId == currentUser.id,
          orElse: () => participants.first, // 如果找不到，返回第一个（理论上不应该发生）
        );

        setState(() {
          _myParticipation = myParticipation;
          _allParticipants = participants; // 保存所有参与者
        });
        
        // 检查所有其他参与者的关注状态
        final otherParticipants = participants.where((p) => p.userId != currentUser.id).toList();
        for (final participant in otherParticipants) {
          _checkFollowStatus(participant.userId);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 检查用户的关注状态
  Future<void> _checkFollowStatus(int userId) async {
    if (_followStatusMap.containsKey(userId)) return; // 已经检查过了
    
    try {
      final response = await ApiService.getFollowStatus(userId);
      if (response.isSuccess && response.data != null && mounted) {
        setState(() {
          _followStatusMap[userId] = response.data!['isFollowing'] as bool? ?? false;
        });
      }
    } catch (e) {
      debugPrint('检查关注状态失败: $e');
    }
  }

  /// 退出活动
  Future<void> _leaveEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出这个活动吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.cancelJoinEvent(widget.eventId);
      
      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已退出活动'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // 返回并刷新列表
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('退出失败: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('退出失败: $e')),
        );
      }
    }
  }

  /// 关注/取消关注用户
  Future<void> _toggleFollow(int userId) async {
    final isFollowing = _followStatusMap[userId] ?? false;
    
    setState(() {
      _loadingFollowIds.add(userId);
    });
    
    try {
      final response = isFollowing
          ? await ApiService.unfollowUser(userId)
          : await ApiService.followUser(userId);
      
      if (response.isSuccess) {
        setState(() {
          _followStatusMap[userId] = !isFollowing;
          _loadingFollowIds.remove(userId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFollowing ? '已取消关注' : '已关注'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        setState(() {
          _loadingFollowIds.remove(userId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '操作失败')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _loadingFollowIds.remove(userId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  /// 进入群聊（UI预留）
  void _enterGroupChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('群聊功能开发中...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('活动详情'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.capriBlue),
        ),
      );
    }

    if (_errorMessage != null || _event == null) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('活动详情'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.mutedForeground,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? '未找到活动信息',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.capriBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: const Text('我参与的活动'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: _enterGroupChat,
            tooltip: '群聊',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.capriBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildEventInfo(_event!),
              const SizedBox(height: 16),
              if (_myParticipation != null) _buildMyParticipationInfo(),
              const SizedBox(height: 16),
              _buildCreatorInfo(),
              const SizedBox(height: 16),
              _buildParticipantsList(),
              const SizedBox(height: 100), // 为底部按钮留出空间
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// 构建活动信息卡片
  Widget _buildEventInfo(Event event) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 活动封面
          if (event.fullImageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                event.fullImageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: AppTheme.muted,
                  child: const Icon(Icons.event, size: 64, color: AppTheme.mutedForeground),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 活动标题和类型
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          color: AppTheme.capriBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.softPeach,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        event.type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 活动信息
                _buildInfoRow(Icons.event, '活动时间', _formatDate(event.eventDate)),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on, '活动地点', event.location),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.people,
                  '报名人数',
                  '${event.participants}/${event.maxParticipants}人',
                ),
                
                if (event.registrationDeadline != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.how_to_reg,
                    '报名截止',
                    _formatDate(event.registrationDeadline!),
                  ),
                ],
                
                if (event.registrationNotice != null && event.registrationNotice!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    '报名须知',
                    style: TextStyle(
                      color: AppTheme.capriBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.registrationNotice!,
                    style: const TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
                
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    '活动描述',
                    style: TextStyle(
                      color: AppTheme.capriBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description!,
                    style: const TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ],
                
                // 相关电影
                if (event.movieTmdbId != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  RelatedMovieCard(
                    movieTmdbId: event.movieTmdbId!,
                    movieTitle: event.movieTitle,
                    moviePosterUrl: event.fullMoviePosterUrl,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建我的报名信息卡片
  Widget _buildMyParticipationInfo() {
    if (_myParticipation == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.softPeach,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '我的报名信息',
                style: TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMyInfoRow('昵称', _myParticipation!.participantNickname),
          const SizedBox(height: 12),
          _buildMyInfoRow('手机号', _myParticipation!.participantPhone),
          if (_myParticipation!.participantWechat != null && _myParticipation!.participantWechat!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMyInfoRow('微信号', _myParticipation!.participantWechat!),
          ],
          if (_myParticipation!.participantQq != null && _myParticipation!.participantQq!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildMyInfoRow('QQ号', _myParticipation!.participantQq!),
          ],
          const SizedBox(height: 12),
          _buildMyInfoRow('报名时间', _formatDate(_myParticipation!.joinedAt)),
        ],
      ),
    );
  }

  /// 构建发起人信息卡片
  Widget _buildCreatorInfo() {
    final isFollowing = _followStatusMap[_creator?.id] ?? false;
    final isLoadingFollow = _loadingFollowIds.contains(_creator?.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.capriBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '发起人',
                style: TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _creator != null ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(userId: _creator!.id),
                ),
              );
            } : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.capriBlue,
                          AppTheme.capriBlue.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: ClipOval(
                      child: _creator?.avatar != null && _creator!.avatar!.isNotEmpty
                          ? Image.network(
                              _creator!.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 28,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _creator?.username ?? '加载中...',
                          style: const TextStyle(
                            color: AppTheme.capriBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_creator?.userCode != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${_creator!.userCode}',
                            style: TextStyle(
                              color: AppTheme.mutedForeground,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoadingFollow)
            Center(
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.capriBlue,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _creator != null ? () => _toggleFollow(_creator!.id) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing 
                      ? AppTheme.mutedForeground 
                      : AppTheme.capriBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isFollowing ? '已关注' : '关注',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建参与人列表
  Widget _buildParticipantsList() {
    // 过滤掉自己，只显示其他参与者
    final otherParticipants = _allParticipants.where((p) => p.userId != _myParticipation?.userId).toList();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.softPeach,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '参与人',
                  style: TextStyle(
                    color: AppTheme.capriBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '共${otherParticipants.length}人',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          if (otherParticipants.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 64,
                      color: AppTheme.mutedForeground.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无其他参与者',
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: otherParticipants.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: AppTheme.muted.withValues(alpha: 0.3),
              ),
              itemBuilder: (context, index) {
                final participant = otherParticipants[index];
                return _buildParticipantItem(participant);
              },
            ),
        ],
      ),
    );
  }

  /// 邀请好友（UI预留）
  void _forwardEvent() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('邀请好友功能开发中...')),
    );
  }

  /// 构建底部操作栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 邀请按钮（占1/3宽度）
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: _forwardEvent,
                label: const Text('邀请好友'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.capriBlue,
                  side: const BorderSide(color: AppTheme.capriBlue),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 退出活动按钮（占2/3宽度）
            Expanded(
              flex: 3,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _leaveEvent,
                child: const Text(
                  '退出活动',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建参与人项
  Widget _buildParticipantItem(EventParticipant participant) {
    final isFollowing = _followStatusMap[participant.userId] ?? false;
    final isLoadingFollow = _loadingFollowIds.contains(participant.userId);
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfilePage(userId: participant.userId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 用户头像
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.capriBlue,
                    AppTheme.capriBlue.withOpacity(0.7),
                  ],
                ),
              ),
              child: ClipOval(
                child: participant.avatar != null && participant.avatar!.isNotEmpty
                    ? Image.network(
                        participant.avatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 用户名
                  Text(
                    participant.username,
                    style: const TextStyle(
                      color: AppTheme.capriBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // 用户ID
                  Text(
                    'ID: ${participant.userCode}',
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // 报名时间
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "参与时间",
                        style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(participant.joinedAt),
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 右侧箭头和关注按钮
            Column(
              children: [
                if (isLoadingFollow)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.capriBlue,
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _toggleFollow(participant.userId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing 
                          ? AppTheme.mutedForeground 
                          : AppTheme.capriBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      minimumSize: const Size(70, 32),
                    ),
                    child: Text(
                      isFollowing ? '已关注' : '关注',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建报名信息行
  Widget _buildRegistrationInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label：',
          style: TextStyle(
            color: AppTheme.mutedForeground.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.capriBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.capriBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.capriBlue,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

