import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/event.dart';
import '../../app_theme.dart';
import '../../widgets/event_card_common.dart';
import '../../widgets/popular_event_filter_bar.dart';
import '../../utils/event_filter_utils.dart';

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

  // 筛选条件
  String? _selectedType; // 活动类型筛选
  String _selectedTimeRange = 'all'; // 时间范围筛选：all, today, week, month

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
        type: _selectedType, // 传递类型筛选参数
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final content = data['content'] as List<dynamic>;
        var events = content.map((item) => Event.fromJson(item as Map<String, dynamic>)).toList();

        // 前端过滤和排序
        events = _filterAndSortEvents(events);

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

  /// 过滤和排序活动列表
  List<Event> _filterAndSortEvents(List<Event> events) {
    return EventFilterUtils.filterAndSortEvents(
      events,
      timeRange: _selectedTimeRange,
      filterPastEvents: true,
    );
  }

  /// 更新筛选条件
  void _updateFilter({String? type, String? timeRange, bool updateType = false}) {
    setState(() {
      if (updateType) _selectedType = type; // 使用标志位来判断是否更新类型
      if (timeRange != null) _selectedTimeRange = timeRange;
    });
    _loadEvents();
  }

  /// 清除所有筛选
  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedTimeRange = 'all';
    });
    _loadEvents();
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    await _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 筛选栏
        _buildFilterBar(),
        // 活动列表
        Expanded(
          child: _buildEventsList(),
        ),
      ],
    );
  }

  /// 构建筛选栏
  Widget _buildFilterBar() {
    return PopularEventFilterBar(
      selectedType: _selectedType,
      selectedTimeRange: _selectedTimeRange,
      onTypeChanged: (type) => _updateFilter(type: type, updateType: true),
      onTimeRangeChanged: (timeRange) => _updateFilter(timeRange: timeRange),
    );
  }

  /// 构建活动列表
  Widget _buildEventsList() {
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
              '暂无符合条件的活动',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '试试调整筛选条件',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground.withOpacity(0.7),
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
            return EventCard(
              event: event,
              onTap: widget.onTapEvent != null ? () => widget.onTapEvent!(event.id) : null,
              onJoin: widget.onJoin != null ? () => widget.onJoin!(event.id) : null,
              showJoinButton: true,
            );
          },
        ),
      ),
    );
  }
}
