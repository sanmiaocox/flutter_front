import 'package:flutter/material.dart';
import '../app_theme.dart';

/// 动态操作弹窗：投诉和收藏
class FeedActionSheet {
  static void show(
    BuildContext context, {
    required VoidCallback onReport,
    required VoidCallback onFavorite,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.muted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _ActionItem(
                icon: Icons.bookmark_border,
                label: '收藏',
                onTap: () {
                  Navigator.pop(context);
                  onFavorite();
                },
              ),
              Divider(
                height: 1,
                color: AppTheme.muted.withValues(alpha: 0.3),
              ),
              _ActionItem(
                icon: Icons.report_outlined,
                label: '投诉',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  onReport();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppTheme.capriBlue;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

