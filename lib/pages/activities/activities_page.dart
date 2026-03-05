import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';
import '../../models/event.dart';
import '../../services/storage_service.dart';
import 'create_event_page.dart';

/// 活动页面（底部导航第二个）
/// 包含两个Tab：我发起的 / 我参与的
class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  bool _showCreated = true; // true: 我发起的, false: 我参与的
  List<Event> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  /// 加载活动列表
  Future<void> _loadEvents({bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || _currentPage >= _totalPages - 1) return;
      setState(() => _isLoadingMore = true);
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // 获取当前用户ID
      final user = await StorageService.getUser();
      if (user == null) {
        setState(() {
          _errorMessage = '请先登录';
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final page = loadMore ? _currentPage + 1 : 0;
      
      // 根据当前Tab调用不同的API
      final response = _showCreated
          ? await ApiService.getUserCreatedEvents(userId: user.id, page: page, size: 20)
          : await ApiService.getUserJoinedEvents(userId: user.id, page: page, size: 20);

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final content = data['content'] as List<dynamic>;
        final events = content.map((item) => Event.fromJson(item as Map<String, dynamic>)).toList();

        setState(() {
          if (loadMore) {
            _events.addAll(events);
            _currentPage = page;
          } else {
            _events = events;
            _currentPage = 0;
          }
          _totalPages = data['totalPages'] as int? ?? 1;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    await _loadEvents();
  }

  /// 切换Tab
  void _toggleTab() {
    setState(() {
      _showCreated = !_showCreated;
    });
    _loadEvents();
  }

  /// 跳转到创建活动页面
  void _navigateToCreateEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEventPage(),
      ),
    );

    // 如果创建成功，刷新列表
    if (result == true) {
      setState(() {
        _showCreated = true; // 切换到"我发起的"Tab
      });
      _loadEvents();
    }
  }

  /// 跳转到活动详情
  void _navigateToEventDetail(int eventId) {
    // TODO: 跳转到活动详情页
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看活动详情: $eventId')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: const Text(
          '我的活动',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 28),
          onPressed: _navigateToCreateEvent,
          tooltip: '创建活动',
        ),
        actions: [
          // 切换按钮
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _toggleTab,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showCreated ? '我发起的' : '我参与的',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showCreated ? Icons.swap_horiz : Icons.swap_horiz,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.capriBlue),
      );
    }

    if (_errorMessage != null) {
      return Center(
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
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.capriBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_events.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.capriBlue,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoadingMore &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            _loadEvents(loadMore: true);
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _events.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == _events.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppTheme.capriBlue),
                ),
              );
            }

            final event = _events[i];
            return _EventCard(
              event: event,
              showCreatorBadge: _showCreated,
              onTap: () => _navigateToEventDetail(event.id),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showCreated ? Icons.event_note : Icons.event_available,
            size: 80,
            color: AppTheme.mutedForeground.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _showCreated ? '还没有发起过活动' : '还没有参加过活动',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _showCreated ? '点击左上角 + 号创建你的第一个活动' : '去首页发现感兴趣的活动吧',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground.withOpacity(0.8),
            ),
          ),
          if (_showCreated) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreateEvent,
              icon: const Icon(Icons.add),
              label: const Text('创建活动'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.capriBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 活动卡片组件
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.showCreatorBadge,
    this.onTap,
  });

  final Event event;
  final bool showCreatorBadge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 活动封面
            if (event.fullImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Image.network(
                      event.fullImageUrl!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: AppTheme.muted,
                        child: const Icon(
                          Icons.event,
                          size: 48,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ),
                    // 状态标签
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(event.statusColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // 创建者标识
                    if (showCreatorBadge)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.softPeach,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                size: 12,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '发起人',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
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
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 活动标题
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: AppTheme.capriBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // 活动信息
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: _formatDate(event.eventDate),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: event.location,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.people_outline,
                    text: '${event.participants}/${event.maxParticipants} 人',
                    trailing: event.isFull
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.softPeach.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '已满员',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.softPeach,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : null,
                  ),
                  // 活动类型
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.capriBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.type,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.capriBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.trailing,
  });

  final IconData icon;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedForeground),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
