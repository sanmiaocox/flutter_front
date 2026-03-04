import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../services/api_service.dart';
import '../../../models/collection.dart';
import '../../../models/favorite_item.dart';

/// 收藏夹详情页面
/// 展示收藏夹中的所有收藏项
class CollectionDetailPage extends StatefulWidget {
  final Collection collection;

  const CollectionDetailPage({
    super.key,
    required this.collection,
  });

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  List<FavoriteItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  /// 加载收藏项
  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getFavoriteItems(widget.collection.id);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _items = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 刷新数据
  Future<void> _refreshData() async {
    await _loadItems();
  }

  /// 移除收藏项
  Future<void> _removeItem(FavoriteItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: const Text('确定要从收藏夹中移除这个项目吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.removeFavoriteItem(
        collectionId: widget.collection.id,
        itemType: item.itemType,
        itemId: item.itemId,
      );

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已移除')),
        );
        _refreshData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: ${response.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失败: $e')),
        );
      }
    }
  }

  /// 编辑收藏夹
  void _editCollection() {
    // TODO: 实现编辑收藏夹功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中...')),
    );
  }

  /// 删除收藏夹
  Future<void> _deleteCollection() async {
    if (widget.collection.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('系统收藏夹不能删除')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个收藏夹吗？收藏夹中的所有项目也会被移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.deleteCollection(widget.collection.id);

      if (response.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('收藏夹已删除')),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: ${response.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMovie = widget.collection.type == 'MOVIE';
    final color = isMovie ? Colors.red.shade400 : Colors.deepPurple.shade400;

    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      body: CustomScrollView(
        slivers: [
          // 自定义AppBar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.capriBlue,
            foregroundColor: AppTheme.lycheeWhite,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editCollection();
                  } else if (value == 'delete') {
                    _deleteCollection();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 12),
                        Text('编辑'),
                      ],
                    ),
                  ),
                  if (!widget.collection.isSystem)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.collection.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.capriBlue,
                      color.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: widget.collection.fullCoverImageUrl != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            widget.collection.fullCoverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('详情页封面加载失败: $error');
                              debugPrint('原始URL: ${widget.collection.coverImage}');
                              debugPrint('完整URL: ${widget.collection.fullCoverImageUrl}');
                              return const SizedBox();
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Icon(
                          isMovie ? Icons.movie : Icons.event,
                          size: 80,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
              ),
            ),
          ),

          // 收藏夹信息
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.capriBlue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isMovie ? Icons.movie : Icons.event,
                              size: 16,
                              color: color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isMovie ? '电影' : '活动',
                              style: TextStyle(
                                fontSize: 13,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        widget.collection.isPublic
                            ? Icons.public
                            : Icons.lock_outline,
                        size: 18,
                        color: AppTheme.mutedForeground,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.collection.isPublic ? '公开' : '私密',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                      if (widget.collection.isSystem) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.softPeach.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '系统收藏夹',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.softPeach,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (widget.collection.description != null && widget.collection.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.collection.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '共 ${widget.collection.itemCount} 项',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.capriBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 收藏项列表
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.capriBlue),
              ),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: _buildErrorView(),
            )
          else if (_items.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyView(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildItemCard(_items[index]),
                  childCount: _items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 错误视图
  Widget _buildErrorView() {
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
            _errorMessage ?? '加载失败',
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

  /// 空状态视图
  Widget _buildEmptyView() {
    final isMovie = widget.collection.type == 'MOVIE';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMovie ? Icons.movie_outlined : Icons.event_outlined,
            size: 80,
            color: AppTheme.mutedForeground.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            '收藏夹是空的',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isMovie ? '去发现页面收藏喜欢的电影吧' : '去活动页面收藏感兴趣的活动吧',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// 收藏项卡片
  Widget _buildItemCard(FavoriteItem item) {
    final isMovie = item.itemType == 'MOVIE';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: AppTheme.capriBlue.withOpacity(0.1),
        child: InkWell(
          onTap: () {
            // TODO: 跳转到详情页
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('查看${isMovie ? "电影" : "活动"}详情')),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 封面图
                Container(
                  width: 60,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.muted.withOpacity(0.2),
                  ),
                  child: item.itemDetail != null && item.itemDetail!['posterUrl'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.itemDetail!['posterUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              isMovie ? Icons.movie : Icons.event,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        )
                      : Icon(
                          isMovie ? Icons.movie : Icons.event,
                          color: AppTheme.mutedForeground,
                        ),
                ),
                const SizedBox(width: 12),

                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemDetail?['title'] ?? '未知标题',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.capriBlue,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.itemDetail?['year'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.itemDetail!['year'].toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                      if (item.itemDetail?['rating'] != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.itemDetail!['rating'].toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.mutedForeground,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedForeground.withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // 删除按钮
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppTheme.mutedForeground,
                  onPressed: () => _removeItem(item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

