import 'package:flutter/material.dart';
import '../models/event.dart';
import '../app_theme.dart';

/// 通用活动卡片组件
/// 
/// 遵循 DRY 原则，统一管理活动卡片的展示逻辑
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onJoin,
    this.showCreatorBadge = false,
    this.showJoinButton = false,
  });

  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool showCreatorBadge; // 是否显示"发起人"标识
  final bool showJoinButton; // 是否显示报名按钮

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    
    // 判断活动是否已结束（精确到分钟）
    final isEnded = event.eventDate.isBefore(now);
    
    // 判断是否在7天内开始（用于显示"即将开始"标识）
    final showUpcomingBadge = !isEnded && event.eventDate.difference(now).inDays <= 7;
    
    // 判断是否显示"已结束"标识
    final showEndedBadge = isEnded;

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
            _buildCoverImage(showUpcomingBadge, showEndedBadge),
            // 活动信息
            _buildEventInfo(),
          ],
        ),
      ),
    );
  }

  /// 构建封面图片区域
  Widget _buildCoverImage(bool showUpcomingBadge, bool showEndedBadge) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 封面图片
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
          
          // 活动类型标签（右上角）
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
          
          // 活动状态标签（左上角）
          // 优先显示"已结束"，其次显示"即将开始"（7天内）
          if (showEndedBadge)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9E9E9E), // 灰色表示已结束
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '已结束',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (showUpcomingBadge)
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
          
          // 创建者标识（右上角第二行）
          if (showCreatorBadge)
            Positioned(
              top: 50,
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
    );
  }

  /// 构建活动信息区域
  Widget _buildEventInfo() {
    return Padding(
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
          
          // 活动时间
          _EventInfoRow(
            icon: Icons.calendar_today_outlined,
            text: _formatDate(event.eventDate),
          ),
          const SizedBox(height: 8),
          
          // 活动地点
          _EventInfoRow(
            icon: Icons.location_on_outlined,
            text: event.location,
          ),
          const SizedBox(height: 8),
          
          // 参与人数
          _EventInfoRow(
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
          
          // 报名按钮
          if (showJoinButton) ...[
            const SizedBox(height: 16),
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
        ],
      ),
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// 活动信息行组件
class _EventInfoRow extends StatelessWidget {
  const _EventInfoRow({
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

