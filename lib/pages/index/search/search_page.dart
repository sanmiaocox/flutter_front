import 'package:flutter/material.dart';
import '../../../app_theme.dart';

/// 搜索页（二级，属主页）：占位，后续可接电影/用户/活动搜索与列表。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: AppTheme.capriBlue, fontSize: 15),
            decoration: InputDecoration(
              hintText: '搜索电影、演员、导演...',
              hintStyle: TextStyle(
                  color: AppTheme.mutedForeground.withValues(alpha: 0.8),
                  fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                const Text('取消', style: TextStyle(color: AppTheme.lycheeWhite)),
          ),
        ],
      ),
      body: Center(
        child: Text(
          '搜索功能待对接 API',
          style: TextStyle(color: AppTheme.mutedForeground, fontSize: 15),
        ),
      ),
    );
  }
}
