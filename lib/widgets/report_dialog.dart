import 'package:flutter/material.dart';
import '../app_theme.dart';

/// 投诉对话框
class ReportDialog {
  static void show(BuildContext context, {required VoidCallback onSubmit}) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          '投诉',
          style: TextStyle(
            color: AppTheme.capriBlue,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请描述投诉原因：',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.lycheeWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.muted.withValues(alpha: 0.4),
                ),
              ),
              child: TextField(
                controller: controller,
                maxLines: 5,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: '请输入投诉内容...',
                  hintStyle: TextStyle(
                    color: AppTheme.mutedForeground.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: const TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 15,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.capriBlue,
              foregroundColor: AppTheme.lycheeWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入投诉内容'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              onSubmit();
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }
}

