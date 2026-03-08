import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';
import '../../../models/event.dart';
import '../../../models/collection.dart';
import '../../../widgets/related_movie_card.dart';
import '../movie_detail/movie_detail_page.dart';
import '../event_registration/event_registration_page.dart';

/// 活动详情页（二级，属主页）：展示活动完整信息、报名和收藏功能
class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, required this.eventId});

  final int eventId;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  Event? _event;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isFavorited = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadEventDetail();
  }

  /// 检查登录状态
  Future<void> _checkLoginStatus() async {
    final user = await StorageService.getUser();
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  /// 加载活动详情
  Future<void> _loadEventDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getEventDetail(widget.eventId);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _event = response.data;
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

  void _handleRegister() async {
    if (_event == null) return;

    // 跳转到报名页面
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventRegistrationPage(
          eventId: widget.eventId,
          isLoggedIn: _isLoggedIn,
        ),
      ),
    );

    // 如果报名成功，刷新活动详情
    if (result == true) {
      _loadEventDetail();
    }
  }

  /// 显示收藏夹选择对话框
  Future<void> _handleFavorite() async {
    if (_event == null) return;

    try {
      // 获取用户的活动收藏夹列表
      final response = await ApiService.getCollectionsByType('EVENT');
      
      if (!response.isSuccess || response.data == null || response.data!.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('您还没有创建活动收藏夹，请先创建收藏夹')),
        );
        return;
      }

      final collections = response.data!;
      
      if (!mounted) return;
      
      // 显示收藏夹选择对话框
      await showDialog(
        context: context,
        builder: (context) => _CollectionSelectionDialog(
          collections: collections,
          eventId: widget.eventId,
          onCollectionsSelected: (selectedCollections) async {
            await _addToCollections(selectedCollections);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载收藏夹失败: $e')),
      );
    }
  }

  /// 添加到多个收藏夹
  Future<void> _addToCollections(List<Collection> collections) async {
    if (collections.isEmpty) return;

    int successCount = 0;
    int failCount = 0;

    for (final collection in collections) {
      try {
        final response = await ApiService.addFavoriteItem(
          collectionId: collection.id,
          itemType: 'EVENT',
          itemId: widget.eventId,  // 使用 itemId 而不是 tmdbId
        );

        if (response.isSuccess) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }

    if (!mounted) return;

    if (successCount > 0) {
      setState(() {
        _isFavorited = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功添加到 $successCount 个收藏夹${failCount > 0 ? '，$failCount 个失败' : ''}'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('添加失败，请重试'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('活动详情'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.capriBlue),
        ),
      );
    }

    if (_errorMessage != null || _event == null) {
      return Scaffold(
        backgroundColor: AppTheme.lycheeWhite,
        appBar: AppBar(
          backgroundColor: AppTheme.capriBlue,
          foregroundColor: AppTheme.lycheeWhite,
          title: const Text('活动详情'),
        ),
        body: Center(
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
                _errorMessage ?? '未找到活动信息',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadEventDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.capriBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final event = _event!;

    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(event),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildEventInfo(event),
                    const SizedBox(height: 16),
                    _buildRegistrationNotice(event),
                    const SizedBox(height: 16),
                    _buildEventDescription(event),
                    const SizedBox(height: 100), // 为底部按钮留出空间
                  ],
                ),
              ),
            ],
          ),
          _buildBottomBar(event),
        ],
      ),
    );
  }

  Widget _buildAppBar(Event event) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppTheme.capriBlue,
      foregroundColor: AppTheme.lycheeWhite,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (event.fullImageUrl != null)
              Image.network(
                event.fullImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.muted,
                ),
              )
            else
              Container(
                color: AppTheme.muted,
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.softPeach,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      event.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black45,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventInfo(Event event) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 活动时间信息卡片
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.capriBlue.withOpacity(0.1),
                  AppTheme.softPeach.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildTimeInfoRow(
                  Icons.event,
                  '活动时间',
                  _formatDate(event.eventDate),
                  AppTheme.capriBlue,
                ),
                if (event.registrationDeadline != null) ...[
                  const SizedBox(height: 12),
                  _buildTimeInfoRow(
                    Icons.how_to_reg,
                    '报名截止',
                    _formatDate(event.registrationDeadline!),
                    AppTheme.softPeach,
                  ),
                ],
                if (event.endTime != null) ...[
                  const SizedBox(height: 12),
                  _buildTimeInfoRow(
                    Icons.event_busy,
                    '活动结束',
                    _formatDate(event.endTime!),
                    AppTheme.mutedForeground,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 地点信息
          _buildInfoRow(Icons.location_on, '活动地点', event.location, AppTheme.capriBlue),
          const SizedBox(height: 16),
          // 发布人信息
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.capriBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: AppTheme.capriBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '发布人',
                      style: TextStyle(
                        color: AppTheme.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.creatorId != null ? '用户${event.creatorId}' : '未知',
                      style: const TextStyle(
                        color: AppTheme.capriBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppTheme.muted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          // 报名人数统计
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lycheeWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.muted.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.softPeach.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people,
                    color: AppTheme.softPeach,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '报名人数',
                        style: TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${event.participants}',
                            style: const TextStyle(
                              color: AppTheme.capriBlue,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / ${event.maxParticipants}',
                            style: TextStyle(
                              color: AppTheme.mutedForeground,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (event.isFull)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.softPeach,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '已满员',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '还剩${event.maxParticipants - event.participants}名额',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (event.movieTmdbId != null) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: AppTheme.muted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            // 相关电影
            RelatedMovieCard(
              movieTmdbId: event.movieTmdbId!,
              movieTitle: event.movieTitle,
              moviePosterUrl: event.fullMoviePosterUrl,
            ),
          ],
        ],
      ),
    );
  }

  /// 构建时间信息行
  Widget _buildTimeInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.softPeach, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mutedForeground,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.capriBlue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationNotice(Event event) {
    // 如果没有报名须知，不显示此部分
    if (event.registrationNotice == null || event.registrationNotice!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.softPeach,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '报名须知',
                style: TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.registrationNotice!,
                    style: const TextStyle(
                      color: AppTheme.capriBlue,
                      fontSize: 14,
                      height: 1.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDescription(Event event) {
    // 如果没有描述，不显示此部分
    if (event.description == null || event.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: AppTheme.capriBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '活动详情',
                style: TextStyle(
                  color: AppTheme.capriBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  event.description!,
                  style: const TextStyle(
                    color: AppTheme.capriBlue,
                    fontSize: 14,
                    height: 1.8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Event event) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // 收藏按钮
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.lycheeWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.muted.withValues(alpha: 0.4),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _isFavorited ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorited ? AppTheme.softPeach : AppTheme.mutedForeground,
                    size: 28,
                  ),
                  onPressed: _handleFavorite,
                ),
              ),
              const SizedBox(width: 12),
              // 立即报名按钮
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: event.isFull
                        ? AppTheme.muted
                        : (event.isParticipant ? AppTheme.softPeach : AppTheme.capriBlue),
                    foregroundColor: event.isFull
                        ? AppTheme.mutedForeground
                        : AppTheme.lycheeWhite,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: event.isFull || event.isParticipant
                      ? null
                      : _handleRegister,
                  child: Text(
                    event.isFull
                        ? '名额已满'
                        : (event.isParticipant ? '已报名' : '立即报名'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 收藏夹选择对话框
class _CollectionSelectionDialog extends StatefulWidget {
  const _CollectionSelectionDialog({
    required this.collections,
    required this.eventId,
    required this.onCollectionsSelected,
  });

  final List<Collection> collections;
  final int eventId;
  final Future<void> Function(List<Collection>) onCollectionsSelected;

  @override
  State<_CollectionSelectionDialog> createState() => _CollectionSelectionDialogState();
}

class _CollectionSelectionDialogState extends State<_CollectionSelectionDialog> {
  final Set<int> _selectedCollectionIds = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('选择收藏夹'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '可以选择多个收藏夹',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.collections.length,
                itemBuilder: (context, index) {
                  final collection = widget.collections[index];
                  final isSelected = _selectedCollectionIds.contains(collection.id);

                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCollectionIds.add(collection.id);
                        } else {
                          _selectedCollectionIds.remove(collection.id);
                        }
                      });
                    },
                    title: Text(collection.name),
                    subtitle: collection.description != null
                        ? Text(
                            collection.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.capriBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.folder,
                        color: AppTheme.capriBlue,
                      ),
                    ),
                    activeColor: AppTheme.capriBlue,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isSubmitting || _selectedCollectionIds.isEmpty
              ? null
              : () async {
                  setState(() {
                    _isSubmitting = true;
                  });

                  final selectedCollections = widget.collections
                      .where((c) => _selectedCollectionIds.contains(c.id))
                      .toList();

                  await widget.onCollectionsSelected(selectedCollections);

                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.capriBlue,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('添加 (${_selectedCollectionIds.length})'),
        ),
      ],
    );
  }
}
