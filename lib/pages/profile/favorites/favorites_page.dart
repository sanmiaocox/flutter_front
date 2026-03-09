import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../services/api_service.dart';
import '../../../models/collection.dart';
import '../../../mixins/auto_refresh_mixin.dart';
import '../../../utils/route_observer.dart';
import 'collection_detail_page.dart';
import 'create_collection_page.dart';

/// 收藏夹页面
/// 展示用户的所有收藏夹，支持按类型筛选（电影/活动）
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> 
    with SingleTickerProviderStateMixin, RouteAware, AutoRefreshMixin {
  late TabController _tabController;
  
  // 收藏夹数据
  List<Collection> _movieCollections = [];
  List<Collection> _eventCollections = [];
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCollections();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    subscribe(routeObserver);
  }

  @override
  void dispose() {
    unsubscribe(routeObserver);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Future<void> onRefresh() async {
    debugPrint('收藏夹列表：从子页面返回，自动刷新数据');
    await _refreshData();
  }

  /// 加载收藏夹列表
  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getCollections();
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _movieCollections = response.data!
              .where((c) => c.type == 'MOVIE')
              .toList();
          _eventCollections = response.data!
              .where((c) => c.type == 'EVENT')
              .toList();
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
    await _loadCollections();
  }

  /// 创建新收藏夹
  void _createCollection(String type) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateCollectionPage(type: type),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  /// 打开收藏夹详情
  void _openCollectionDetail(Collection collection) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CollectionDetailPage(collection: collection),
      ),
    );

    if (result == true) {
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        title: const Text('我的收藏夹'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.lycheeWhite,
          indicatorWeight: 3,
          labelColor: AppTheme.lycheeWhite,
          unselectedLabelColor: AppTheme.lycheeWhite.withOpacity(0.6),
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: '电影收藏夹'),
            Tab(text: '活动收藏夹'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.capriBlue),
            )
          : _errorMessage != null
              ? _buildErrorView()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCollectionList(_movieCollections, 'MOVIE'),
                    _buildCollectionList(_eventCollections, 'EVENT'),
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

  /// 收藏夹列表
  Widget _buildCollectionList(List<Collection> collections, String type) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppTheme.capriBlue,
      child: collections.isEmpty
          ? _buildEmptyView(type)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: collections.length + 1,
              itemBuilder: (context, index) {
                if (index == collections.length) {
                  return _buildCreateButton(type);
                }
                return _buildCollectionCard(collections[index]);
              },
            ),
    );
  }

  /// 空状态视图
  Widget _buildEmptyView(String type) {
    final isMovie = type == 'MOVIE';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 60),
        Icon(
          isMovie ? Icons.movie_outlined : Icons.event_outlined,
          size: 80,
          color: AppTheme.mutedForeground.withOpacity(0.5),
        ),
        const SizedBox(height: 24),
        Text(
          isMovie ? '还没有电影收藏夹' : '还没有活动收藏夹',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isMovie ? '创建收藏夹，开始收藏你喜欢的电影吧' : '创建收藏夹，收藏感兴趣的活动',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.mutedForeground.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 32),
        _buildCreateButton(type),
      ],
    );
  }

  /// 创建收藏夹按钮
  Widget _buildCreateButton(String type) {
    final isMovie = type == 'MOVIE';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () => _createCollection(type),
        icon: const Icon(Icons.add),
        label: Text(isMovie ? '创建电影收藏夹' : '创建活动收藏夹'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.capriBlue,
          side: BorderSide(
            color: AppTheme.capriBlue.withOpacity(0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  /// 收藏夹卡片
  Widget _buildCollectionCard(Collection collection) {
    final isMovie = collection.type == 'MOVIE';
    final color = isMovie ? Colors.red.shade400 : Colors.deepPurple.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: AppTheme.capriBlue.withOpacity(0.1),
        child: InkWell(
          onTap: () => _openCollectionDetail(collection),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 封面或图标
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: collection.fullCoverImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            collection.fullCoverImageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: color,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('封面图片加载失败: $error');
                              debugPrint('原始URL: ${collection.coverImage}');
                              debugPrint('完整URL: ${collection.fullCoverImageUrl}');
                              return Icon(
                                isMovie ? Icons.movie : Icons.event,
                                size: 40,
                                color: color,
                              );
                            },
                          ),
                        )
                      : Icon(
                          isMovie ? Icons.movie : Icons.event,
                          size: 40,
                          color: color,
                        ),
                ),
                const SizedBox(width: 16),

                // 收藏夹信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              collection.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.capriBlue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (collection.isSystem) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.softPeach.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '系统',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.softPeach,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (collection.description != null && collection.description!.isNotEmpty)
                        Text(
                          collection.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.mutedForeground,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            isMovie ? Icons.movie_outlined : Icons.event_outlined,
                            size: 16,
                            color: AppTheme.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${collection.itemCount} 项',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            collection.isPublic
                                ? Icons.public
                                : Icons.lock_outline,
                            size: 16,
                            color: AppTheme.mutedForeground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            collection.isPublic ? '公开' : '私密',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 箭头图标
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

