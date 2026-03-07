import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';
import '../../models/event.dart';
import '../../services/storage_service.dart';
import '../../widgets/event_card_common.dart';
import '../../widgets/event_filter_bar.dart';
import '../../utils/event_filter_utils.dart';
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
    // 先按类型筛选
    var filtered = events;
    if (_selectedType != null) {
      filtered = filtered.where((event) => event.type == _selectedType).toList();
    }

    // 再按时间范围筛选和排序
    return EventFilterUtils.filterAndSortEvents(
      filtered,
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
    return Column(
      children: [
        // 筛选栏
        EventFilterBar(
          selectedType: _selectedType,
          selectedTimeRange: _selectedTimeRange,
          onTypeChanged: (type) => _updateFilter(type: type, updateType: true),
          onTimeRangeChanged: (timeRange) => _updateFilter(timeRange: timeRange),
        ),
        // 活动列表
        Expanded(
          child: _buildEventsList(),
        ),
      ],
    );
  }

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
            return EventCard(
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
