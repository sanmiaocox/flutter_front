import 'package:flutter/material.dart';

import '../app_theme.dart';

/// 统一的转发/分享弹窗组件。
/// 仅展示操作选项，不真正执行分享逻辑，后续接入系统分享或复制功能时可在此扩展。
class ShareActionSheet {
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? description,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.capriBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close,
                          size: 20, color: AppTheme.mutedForeground),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                ] else
                  const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ShareOption(
                      icon: Icons.person_add_alt_1,
                      label: '转发给好友',
                      onTap: () {
                        Navigator.of(context).pop();
                        // 预留：后续接入系统分享或站内好友选择。
                      },
                    ),
                    _ShareOption(
                      icon: Icons.link,
                      label: '复制链接',
                      onTap: () {
                        Navigator.of(context).pop();
                        // 预留：后续接入剪贴板复制。
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.lycheeWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.muted.withValues(alpha: 0.4),
              ),
            ),
            child: Icon(icon, color: AppTheme.capriBlue, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

