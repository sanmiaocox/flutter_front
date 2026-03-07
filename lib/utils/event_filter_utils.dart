import '../models/event.dart';

/// 活动筛选工具类
/// 
/// 遵循 DRY 原则，统一管理活动的过滤和排序逻辑
class EventFilterUtils {
  EventFilterUtils._(); // 私有构造函数，防止实例化

  /// 过滤和排序活动列表
  /// 
  /// [events] 原始活动列表
  /// [timeRange] 时间范围筛选：all, today, week, month, ended
  /// [filterPastEvents] 是否过滤掉已开始的活动（当 timeRange 为 'ended' 时此参数无效）
  static List<Event> filterAndSortEvents(
    List<Event> events, {
    String timeRange = 'all',
    bool filterPastEvents = true,
  }) {
    final now = DateTime.now();
    var filtered = events;

    // 特殊处理：如果选择"已结束"，只显示已结束的活动
    if (timeRange == 'ended') {
      filtered = filtered.where((event) => event.eventDate.isBefore(now)).toList();
      // 按开始时间降序排序（最近结束的在前）
      filtered.sort((a, b) => b.eventDate.compareTo(a.eventDate));
      return filtered;
    }

    // 1. 过滤掉已开始的活动（可选）
    if (filterPastEvents) {
      filtered = filtered.where((event) => event.eventDate.isAfter(now)).toList();
    }

    // 2. 根据时间范围筛选
    if (timeRange != 'all') {
      filtered = filtered.where((event) {
        switch (timeRange) {
          case 'today':
            // 今天
            return event.eventDate.year == now.year &&
                   event.eventDate.month == now.month &&
                   event.eventDate.day == now.day;
          case 'week':
            // 本周（未来7天）
            final weekLater = now.add(const Duration(days: 7));
            return event.eventDate.isBefore(weekLater);
          case 'month':
            // 本月（未来30天）
            final monthLater = now.add(const Duration(days: 30));
            return event.eventDate.isBefore(monthLater);
          default:
            return true;
        }
      }).toList();
    }

    // 3. 按开始时间升序排序（最近的在前）
    filtered.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    return filtered;
  }

  /// 判断活动是否在指定天数内开始
  /// 
  /// [event] 活动对象
  /// [days] 天数，默认7天
  static bool isEventStartingSoon(Event event, {int days = 7}) {
    final now = DateTime.now();
    final daysUntilEvent = event.eventDate.difference(now).inDays;
    return daysUntilEvent >= 0 && daysUntilEvent <= days;
  }
}

