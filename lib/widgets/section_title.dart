import 'package:flutter/material.dart';
import '../app_theme.dart';

/// 区块标题，可选右侧「更多」链接。可复用。
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.onMore,
  });

  final String title;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.capriBlue,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onMore != null)
            TextButton(
              onPressed: onMore,
              child: const Text('更多', style: TextStyle(color: AppTheme.capriBlue)),
            ),
        ],
      ),
    );
  }
}
