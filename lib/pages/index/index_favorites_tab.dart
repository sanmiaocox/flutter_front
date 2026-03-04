import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/api_service.dart';
import '../../models/collection.dart';
import '../../models/favorite_item.dart';

/// 主页 - 我的收藏 Tab 内容：网格或空状态
class IndexFavoritesTab extends StatefulWidget {
  const IndexFavoritesTab({
    super.key,
    this.onTapMovie,
  });

  final void Function(int movieId)? onTapMovie;

  @override
  State<IndexFavoritesTab> createState() => _IndexFavoritesTabState();
}

class _IndexFavoritesTabState extends State<IndexFavoritesTab> {
  bool _isLoading = true;
  String? _errorMessage;
  List<FavoriteItem> _favoriteItems = [];
  Collection? _defaultCollection;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 获取电影类型的收藏夹
      final collectionsResponse = await ApiService.getCollectionsByType('MOVIE');

      if (!mounted) return;

      if (collectionsResponse.isSuccess && 
          collectionsResponse.data != null && 
          collectionsResponse.data!.isNotEmpty) {
        // 使用第一个收藏夹（通常是默认收藏夹）
        _defaultCollection = collectionsResponse.data!.first;

        // 获取收藏夹中的电影
        final itemsResponse = await ApiService.getFavoriteItems(_defaultCollection!.id);

        if (!mounted) return;

        if (itemsResponse.isSuccess && itemsResponse.data != null) {
          setState(() {
            _favoriteItems = itemsResponse.data!;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = '加载收藏失败: ${itemsResponse.message}';
            _isLoading = false;
          });
        }
      } else {
        // 没有收藏夹，显示空状态
        setState(() {
          _favoriteItems = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '网络错误: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.capriBlue,
        ),
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
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFavorites,
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

    if (_favoriteItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: AppTheme.muted,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无收藏',
              style: TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '快去添加你喜欢的电影吧！',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: AppTheme.capriBlue,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              '我的收藏 (${_favoriteItems.length})',
              style: const TextStyle(
                color: AppTheme.capriBlue,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const crossCount = 3;
              const spacing = 12.0;
                final width = (constraints.maxWidth - spacing * (crossCount - 1)) / crossCount;
                
              return Wrap(
                spacing: spacing,
                runSpacing: 16,
                  children: _favoriteItems.map((item) {
                  return SizedBox(
                    width: width,
                      child: _buildMovieCard(item, width),
                  );
                }).toList(),
              );
            },
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard(FavoriteItem item, double width) {
    final itemDetail = item.itemDetail;
    
    return GestureDetector(
      onTap: widget.onTapMovie != null 
          ? () => widget.onTapMovie!(item.itemId)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: itemDetail != null && itemDetail['posterUrl'] != null
                ? Image.network(
                    itemDetail['posterUrl'] as String,
                    width: width,
                    height: width * 1.5,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: width,
                      height: width * 1.5,
                      color: AppTheme.muted,
                      child: const Icon(Icons.movie, size: 48),
                    ),
                  )
                : Container(
                    width: width,
                    height: width * 1.5,
                    color: AppTheme.muted,
                    child: const Icon(Icons.movie, size: 48),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            itemDetail?['title'] as String? ?? '未知电影',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (itemDetail != null && itemDetail['rating'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  (itemDetail['rating'] as num).toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
