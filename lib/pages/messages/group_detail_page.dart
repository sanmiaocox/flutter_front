import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../config/api_config.dart';
import '../../models/api_response.dart';
import '../../models/event.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../profile/user_profile_page.dart';
import '../index/event_detail/event_detail_page.dart';

/// 群聊详情页面
class GroupDetailPage extends StatefulWidget {
  final int groupId;
  final String groupName;
  final String? groupAvatar;
  final int? eventId;

  const GroupDetailPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
    this.eventId,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  Map<String, dynamic>? _groupDetail;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  int _totalPages = 1;
  int? _myUserId;
  bool _isGroupOwner = false;
  String? _errorMessage;
  int? _eventIdFromDetail; // 从群聊详情中获取的活动ID
  int? _eventMaxParticipants; // 活动的最大参与人数

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myUserId = await StorageService.getUserId();
    await _loadGroupDetail();
  }

  Future<void> _loadGroupDetail() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final resp = await ApiService.getGroupDetail(widget.groupId);
      if (resp.isSuccess && resp.data != null) {
        final detail = resp.data!;
        final ownerId = (detail['owner'] as Map<String, dynamic>?)?['id'] as int?;
        final eventId = detail['eventId'] as int?;
        
        if (mounted) {
          setState(() {
            _groupDetail = detail;
            _isGroupOwner = ownerId == _myUserId;
            _eventIdFromDetail = eventId;
            _members = [];
            _currentPage = 0;
            _totalPages = 1;
          });
        }
        
        // 加载第一页成员
        await _loadMembers();
      } else {
        if (mounted) {
          setState(() => _errorMessage = resp.message);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = '加载失败: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMembers() async {
    if (_currentPage >= _totalPages) return;
    
    if (mounted) setState(() => _isLoadingMore = true);
    try {
      final resp = await ApiService.getGroupMembers(
        widget.groupId,
        page: _currentPage,
        size: 20,
      );
      
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data!;
        final content = (data['content'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        final totalPages = data['totalPages'] as int? ?? 1;
        
        if (mounted) {
          setState(() {
            _members.addAll(content);
            _currentPage++;
            _totalPages = totalPages;
          });
        }
      } else {
        // 如果 API 返回错误，使用 getGroupDetail 中的 members 字段
        if (_groupDetail != null && _groupDetail!['members'] != null) {
          final members = (_groupDetail!['members'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ?? [];
          if (mounted) {
            setState(() {
              _members.addAll(members);
              _currentPage = 1;
              _totalPages = 1;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('加载成员失败: $e');
      // 如果 API 调用失败，使用 getGroupDetail 中的 members 字段
      if (_groupDetail != null && _groupDetail!['members'] != null) {
        final members = (_groupDetail!['members'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ?? [];
        if (mounted) {
          setState(() {
            _members.addAll(members);
            _currentPage = 1;
            _totalPages = 1;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }


  Future<void> _kickMember(Map<String, dynamic> member) async {
    final userId = member['userId'] as int;
    final username = member['username'] as String;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认踢出'),
        content: Text('确定要踢出"$username"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('踢出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.kickGroupMember(widget.groupId, userId);
      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('踢出成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // 刷新成员列表
        setState(() {
          _members.clear();
          _currentPage = 0;
        });
        await _loadMembers();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('踢出失败: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('踢出失败: $e')),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    if (_isGroupOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('群主不能直接退出，请先解散群聊')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出该群聊吗？同时会退出关联的活动。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('退出'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 先退出群聊
      final leaveResp = await ApiService.leaveGroup(widget.groupId);
      if (!leaveResp.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('退出群聊失败: ${leaveResp.message}')),
          );
        }
        return;
      }

      // 再退出活动（优先使用从群聊详情中获取的 eventId）
      final eventId = _eventIdFromDetail ?? widget.eventId;
      if (eventId != null) {
        await ApiService.cancelJoinEvent(eventId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已退出群聊和活动'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  Future<void> _dissolveGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认解散群聊'),
        content: const Text('解散群聊后，群内所有消息将被清空，同时关联的活动也会被删除，此操作不可撤销。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('解散并删除活动'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 先解散群聊
      final dissolveResp = await ApiService.dissolveGroup(widget.groupId);
      if (!dissolveResp.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('解散群聊失败: ${dissolveResp.message}')),
          );
        }
        return;
      }

      // 再删除活动
      if (widget.eventId != null) {
        await ApiService.deleteEvent(widget.eventId!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('群聊已解散，活动已删除'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('群聊详情'),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.capriBlue),
        ),
      );
    }

    if (_errorMessage != null || _groupDetail == null) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('群聊详情'),
          elevation: 0,
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
                _errorMessage ?? '加载失败',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadGroupDetail,
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
        title: const Text('群聊详情'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 群聊信息头部（包含关联活动）
          _buildGroupHeader(),
          
          // 成员列表标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                const Text(
                  '群成员',
                  style: TextStyle(
                    color: AppTheme.capriBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_members.length}/${_eventMaxParticipants ?? '未知'}',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // 成员列表
          Expanded(
            child: _buildMembersList(),
          ),
        ],
      ),
      bottomSheet: _buildBottomActions(),
    );
  }

  Widget _buildGroupHeader() {
    // final memberCount = _groupDetail?['memberCount'] as int? ?? 0;成员数暂时用不上
    final avatar = _groupDetail?['avatar'] as String?;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.capriBlue,
            AppTheme.capriBlue.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                // ========== 添加 Align 包裹头像容器 ==========
                Align( // Align 让子组件按自身尺寸展示，不占满父组件宽度
                  alignment: Alignment.center, // 保持居中
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: avatar != null && avatar.isNotEmpty
                          ? NetworkImage(ApiConfig.getImageUrl(avatar))
                          : null,
                      child: avatar == null || avatar.isEmpty
                          ? const Icon(Icons.group_rounded, size: 48, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 群名称
                Text(
                  widget.groupName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // 关联活动卡片
                if (_eventIdFromDetail != null)
                  _buildEventCard(),

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard() {
    // 优先使用从群聊详情中获取的 eventId，其次使用 widget.eventId
    final eventId = _eventIdFromDetail ?? widget.eventId;
    
    if (eventId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<ApiResponse<Event>>(
      future: ApiService.getEventDetail(eventId),
      builder: (context, snapshot) {
        // 加载中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                height: 60,
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.capriBlue),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // 加载失败或无数据
        if (!snapshot.hasData || !snapshot.data!.isSuccess || snapshot.data!.data == null) {
          return const SizedBox.shrink();
        }

        final event = snapshot.data!.data!;
        
        // 保存活动的最大参与人数
        if (_eventMaxParticipants != event.maxParticipants) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() => _eventMaxParticipants = event.maxParticipants);
          });
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventDetailPage(eventId: event.id),
                ),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // 活动海报
                    if (event.fullImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          event.fullImageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.muted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.event, color: AppTheme.capriBlue),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.muted,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.event, color: AppTheme.capriBlue),
                      ),
                    const SizedBox(width: 12),
                    
                    // 活动信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '关联活动',
                            style: TextStyle(
                              color: AppTheme.mutedForeground,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.title,
                            style: const TextStyle(
                              color: AppTheme.capriBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: AppTheme.mutedForeground,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: TextStyle(
                                    color: AppTheme.mutedForeground,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: AppTheme.mutedForeground,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${event.eventDate.month}月${event.eventDate.day}日 ${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: AppTheme.mutedForeground,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // 箭头
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: AppTheme.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersList() {
    if (_members.isEmpty && !_isLoadingMore) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.mutedForeground.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '暂无成员',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _members.length + (_isLoadingMore ? 1 : 0) + (_currentPage < _totalPages ? 1 : 0),
      itemBuilder: (context, index) {
        // 加载更多按钮
        if (index == _members.length && _currentPage < _totalPages) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _loadMembers,
                icon: const Icon(Icons.expand_more),
                label: const Text('加载更多成员'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.capriBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          );
        }

        // 加载指示器
        if (index == _members.length && _isLoadingMore) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.capriBlue),
                ),
              ),
            ),
          );
        }

        final member = _members[index];
        return _buildMemberItem(member);
      },
    );
  }

  Widget _buildMemberItem(Map<String, dynamic> member) {
    final userId = member['userId'] as int;
    final username = member['username'] as String;
    final avatar = member['avatar'] as String?;
    final role = member['role'] as String? ?? 'MEMBER';
    final isOwner = role == 'OWNER';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePage(userId: userId),
            ),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // 头像
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.muted,
                      backgroundImage: avatar != null && avatar.isNotEmpty
                          ? NetworkImage(ApiConfig.getImageUrl(avatar))
                          : null,
                      child: avatar == null || avatar.isEmpty
                          ? Text(
                              username.isNotEmpty ? username[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: AppTheme.capriBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            )
                          : null,
                    ),
                    // 群主标签
                    if (isOwner)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.capriBlue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Text(
                            '主',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                
                // 用户信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: AppTheme.capriBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '#${member['userCode'] as String? ?? ''}',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 操作按钮（仅群主可见，且不能踢出自己）
                if (_isGroupOwner && userId != _myUserId)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                    onPressed: () => _kickMember(member),
                    tooltip: '踢出',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.muted.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isGroupOwner)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _dissolveGroup,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '解散群聊',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _leaveGroup,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '退出群聊',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

