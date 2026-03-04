import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/event.dart';
import '../../app_theme.dart';

/// 主页 - 热门活动 Tab 内容
/// 已接入后端API：GET /api/events
class IndexEventsTab extends StatefulWidget {
  const IndexEventsTab({
    super.key,
    this.onTapEvent,
    this.onJoin,
  });

  final void Function(int eventId)? onTapEvent;
  final void Function(int eventId)? onJoin;

  @override
  State<IndexEventsTab> createState() => _IndexEventsTabState();
}

class _IndexEventsTabState extends State<IndexEventsTab> {
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
      final page = loadMore ? _currentPage + 1 : 0;
      final response = await ApiService.getEvents(
        page: page,
        size: 20,
      );

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

  @override
  Widget build(BuildContext context) {
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.mutedForeground.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无活动',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.mutedForeground,
              ),
            ),
          ],
        ),
      );
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
              onTap: widget.onTapEvent != null ? () => widget.onTapEvent!(event.id) : null,
              onJoin: widget.onJoin != null ? () => widget.onJoin!(event.id) : null,
            );
          },
        ),
      ),
    );
  }
}

/// 活动卡片组件
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    this.onJoin,
    this.onTap,
  });

  final Event event;
  final VoidCallback? onJoin;
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 活动封面图
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (event.fullImageUrl != null)
                    Image.network(
                      event.fullImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.muted,
                        child: const Icon(
                          Icons.event,
                          size: 48,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: AppTheme.muted,
                      child: const Icon(
                        Icons.event,
                        size: 48,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  // 活动类型标签
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.softPeach,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.type,
                        style: const TextStyle(
                          color: AppTheme.capriBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  // 活动状态标签
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
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // 活动时间
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    text: _formatDate(event.eventDate),
                  ),
                  const SizedBox(height: 8),
                  // 活动地点
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: event.location,
                  ),
                  const SizedBox(height: 8),
                  // 参与人数
                  _InfoRow(
                    icon: Icons.people_outline,
                    text: '${event.participants}/${event.maxParticipants} 人',
                  ),
                  const SizedBox(height: 16),
                  // 报名按钮
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: event.isFull
                            ? AppTheme.muted
                            : (event.isParticipant ? AppTheme.softPeach : AppTheme.capriBlue),
                        foregroundColor: event.isFull
                            ? AppTheme.mutedForeground
                            : (event.isParticipant ? AppTheme.capriBlue : AppTheme.lycheeWhite),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: event.isFull ? null : onJoin,
                      child: Text(
                        event.isFull
                            ? '已满员'
                            : (event.isParticipant ? '已报名' : '报名参加'),
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
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

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
      ],
    );
  }
}
