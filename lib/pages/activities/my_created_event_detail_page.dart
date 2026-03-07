import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../services/api_service.dart';
import '../../../models/event.dart';
import '../../../models/event_participant.dart';
import 'edit_event_page.dart';

/// 我发起的活动详情页
///
/// 功能：
/// - 显示活动完整信息
/// - 查看参与人列表
/// - 移除参与人
/// - 修改活动信息
/// - 取消/删除活动
/// - 分享活动
class MyCreatedEventDetailPage extends StatefulWidget {
  const MyCreatedEventDetailPage({
    super.key,
    required this.eventId,
  });

  final int eventId;

  @override
  State<MyCreatedEventDetailPage> createState() => _MyCreatedEventDetailPageState();
}

class _MyCreatedEventDetailPageState extends State<MyCreatedEventDetailPage> {
  Event? _event;
  List<EventParticipant> _participants = [];
  bool _isLoading = true;
  bool _isLoadingParticipants = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载活动详情和参与人列表
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 并行加载活动详情和参与人列表
      final results = await Future.wait([
        ApiService.getEventDetail(widget.eventId),
        ApiService.getEventParticipants(widget.eventId),
      ]);

      final eventResponse = results[0] as dynamic;
      final participantsResponse = results[1] as dynamic;

      if (eventResponse.isSuccess && eventResponse.data != null) {
        setState(() {
          _event = eventResponse.data;
        });
      } else {
        setState(() {
          _errorMessage = eventResponse.message;
        });
      }

      if (participantsResponse.isSuccess && participantsResponse.data != null) {
        setState(() {
          _participants = participantsResponse.data ?? [];
        });
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

  /// 刷新参与人列表
  Future<void> _refreshParticipants() async {
    setState(() {
      _isLoadingParticipants = true;
    });

    try {
      final response = await ApiService.getEventParticipants(widget.eventId);
      if (response.isSuccess && response.data != null) {
        setState(() {
          _participants = response.data ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刷新失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingParticipants = false;
      });
    }
  }

  /// 移除参与人
  Future<void> _removeParticipant(EventParticipant participant) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: Text('确定要移除参与人"${participant.participantNickname}"吗？'),
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
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 注意：这里需要后端提供移除参与人的API
      // 暂时使用取消参加的API（需要后端支持管理员移除功能）
      final response = await ApiService.cancelJoinEvent(widget.eventId);

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('移除成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _refreshParticipants();
        await _loadData(); // 刷新活动信息（更新人数）
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('移除失败: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: $e')),
        );
      }
    }
  }

  /// 修改活动
  Future<void> _editEvent() async {
    if (_event == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(event: _event!),
      ),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  /// 删除活动
  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后将无法恢复，确定要删除这个活动吗？'),
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
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.deleteEvent(widget.eventId);

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('活动已删除'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // 返回并刷新列表
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除失败: ${response.message}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  /// 分享活动
  void _shareEvent() {
    if (_event == null) return;

    // TODO: 实现分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('分享功能开发中...')),
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
        title: const Text('我发起的活动'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editEvent,
            tooltip: '修改活动',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareEvent();
                  break;
                case 'delete':
                  _deleteEvent();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('分享活动'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除活动', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
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
              _buildParticipantsList(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建参与人列表
  Widget _buildParticipantsList() {
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
                const Text(
                  '参与人列表',
                  style: TextStyle(
                    color: AppTheme.capriBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '共${_participants.length}人',
                  style: TextStyle(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: AppTheme.capriBlue,
                    size: 20,
                  ),
                  onPressed: _isLoadingParticipants ? null : _refreshParticipants,
                ),
              ],
            ),
          ),

          if (_isLoadingParticipants)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.capriBlue),
              ),
            )
          else if (_participants.isEmpty)
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
                      '还没有人报名',
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
              itemCount: _participants.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 20,
                endIndent: 20,
                color: AppTheme.muted.withValues(alpha: 0.3),
              ),
              itemBuilder: (context, index) {
                final participant = _participants[index];
                return _buildParticipantItem(participant);
              },
            ),
        ],
      ),
    );
  }

  /// 构建参与人项
  Widget _buildParticipantItem(EventParticipant participant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户头像
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.capriBlue.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: participant.avatar != null && participant.avatar!.isNotEmpty
                  ? Image.network(
                      participant.avatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppTheme.capriBlue.withValues(alpha: 0.1),
                        child: Center(
                          child: Text(
                            participant.username.isNotEmpty
                                ? participant.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.capriBlue,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.capriBlue.withValues(alpha: 0.1),
                      child: Center(
                        child: Text(
                          participant.username.isNotEmpty
                              ? participant.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppTheme.capriBlue,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                
                // 个人简介
                if (participant.bio != null && participant.bio!.isNotEmpty) ...[
                  Text(
                    participant.bio!,
                    style: TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],
                
                // 报名信息
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.capriBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.capriBlue.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '报名信息',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildRegistrationInfoRow('昵称', participant.participantNickname),
                      const SizedBox(height: 4),
                      _buildRegistrationInfoRow('手机', participant.participantPhone),
                      if (participant.participantWechat != null && participant.participantWechat!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildRegistrationInfoRow('微信', participant.participantWechat!),
                      ],
                      if (participant.participantQq != null && participant.participantQq!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildRegistrationInfoRow('QQ', participant.participantQq!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // 报名时间
                Text(
                  '报名时间：${_formatDate(participant.joinedAt)}',
                  style: TextStyle(
                    color: AppTheme.mutedForeground.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 移除按钮
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _removeParticipant(participant),
            tooltip: '移除',
          ),
        ],
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

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

