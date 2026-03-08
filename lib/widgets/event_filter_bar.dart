import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../constants/event_constants.dart';

/// 活动筛选栏组件
/// 
/// 遵循 DRY 原则，统一管理活动筛选栏的展示和交互逻辑
class EventFilterBar extends StatelessWidget {
  const EventFilterBar({
    super.key,
    required this.selectedType,
    required this.selectedTimeRange,
    required this.onTypeChanged,
    required this.onTimeRangeChanged,
  });

  final String? selectedType;
  final String selectedTimeRange;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String> onTimeRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.lycheeWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间范围筛选
          _buildTimeFilter(),
          const SizedBox(height: 12),
          // 活动类型筛选
          _buildTypeFilter(),
        ],
      ),
    );
  }

  /// 构建时间筛选行
  Widget _buildTimeFilter() {
    return Row(
      children: [
        const Icon(Icons.access_time, size: 18, color: AppTheme.capriBlue),
        const SizedBox(width: 8),
        const Text(
          '时间',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.capriBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimeChip('全部', 'all'),
                const SizedBox(width: 8),
                _buildTimeChip('今天', 'today'),
                const SizedBox(width: 8),
                _buildTimeChip('本周', 'week'),
                const SizedBox(width: 8),
                _buildTimeChip('本月', 'month'),
                const SizedBox(width: 8),
                _buildTimeChip('已结束', 'ended'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建类型筛选行
  Widget _buildTypeFilter() {
    return Row(
      children: [
        const Icon(Icons.category, size: 18, color: AppTheme.capriBlue),
        const SizedBox(width: 8),
        const Text(
          '类型',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.capriBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTypeChip('全部', null),
                const SizedBox(width: 8),
                ...EventConstants.eventTypes.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildTypeChip(type, type),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建时间筛选芯片
  Widget _buildTimeChip(String label, String value) {
    final isSelected = selectedTimeRange == value;
    return GestureDetector(
      onTap: () => onTimeRangeChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.capriBlue : AppTheme.muted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : AppTheme.mutedForeground,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 构建类型筛选芯片
  Widget _buildTypeChip(String label, String? value) {
    final isSelected = selectedType == value;
    return GestureDetector(
      onTap: () => onTypeChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.softPeach : AppTheme.muted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? AppTheme.capriBlue : AppTheme.mutedForeground,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

