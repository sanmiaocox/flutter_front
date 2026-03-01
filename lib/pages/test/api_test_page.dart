import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../app_theme.dart';

/// API测试页面 - 用于测试所有后端接口
class ApiTestPage extends StatefulWidget {
  const ApiTestPage({super.key});

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  final _scrollController = ScrollController();
  String _testResult = '点击下方按钮测试API接口\n';
  bool _isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _testResult += '\n$message';
    });
    // 自动滚动到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearLog() {
    setState(() {
      _testResult = '日志已清空\n';
    });
  }

  Future<void> _testApi(String apiName, Future<void> Function() testFunction) async {
    setState(() {
      _isLoading = true;
    });
    
    _addLog('========== 测试 $apiName ==========');
    
    try {
      await testFunction();
      _addLog('✅ $apiName 测试完成');
    } catch (e) {
      _addLog('❌ $apiName 测试失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 测试用户统计信息
  Future<void> _testUserStats() async {
    final user = await StorageService.getUser();
    if (user == null) {
      _addLog('❌ 未登录,无法测试');
      return;
    }

    final response = await ApiService.getUserStats(user.id);
    if (response.isSuccess && response.data != null) {
      _addLog('关注数: ${response.data!.followingCount}');
      _addLog('粉丝数: ${response.data!.followerCount}');
      _addLog('好友数: ${response.data!.friendCount}');
    } else {
      _addLog('失败: ${response.message}');
    }
  }

  // 测试收藏夹管理
  Future<void> _testCollections() async {
    // 1. 获取所有收藏夹
    _addLog('1. 获取所有收藏夹...');
    var response = await ApiService.getCollections();
    if (response.isSuccess && response.data != null) {
      _addLog('收藏夹数量: ${response.data!.length}');
      for (var collection in response.data!) {
        _addLog('  - ${collection.name} (${collection.type}) [${collection.itemCount}项]');
      }
    } else {
      _addLog('失败: ${response.message}');
      return;
    }

    // 2. 创建新收藏夹
    _addLog('\n2. 创建新收藏夹...');
    final createResponse = await ApiService.createCollection(
      name: '测试收藏夹_${DateTime.now().millisecondsSinceEpoch}',
      type: 'MOVIE',
      description: '这是一个测试收藏夹',
      isPublic: true,
    );
    
    if (createResponse.isSuccess && createResponse.data != null) {
      final newCollection = createResponse.data!;
      _addLog('创建成功: ${newCollection.name} (ID: ${newCollection.id})');
      
      // 3. 更新收藏夹
      _addLog('\n3. 更新收藏夹...');
      final updateResponse = await ApiService.updateCollection(
        collectionId: newCollection.id,
        name: '${newCollection.name}_已更新',
        description: '更新后的描述',
      );
      
      if (updateResponse.isSuccess) {
        _addLog('更新成功: ${updateResponse.data!.name}');
      } else {
        _addLog('更新失败: ${updateResponse.message}');
      }
      
      // 4. 删除收藏夹
      _addLog('\n4. 删除收藏夹...');
      final deleteResponse = await ApiService.deleteCollection(newCollection.id);
      if (deleteResponse.isSuccess) {
        _addLog('删除成功');
      } else {
        _addLog('删除失败: ${deleteResponse.message}');
      }
    } else {
      _addLog('创建失败: ${createResponse.message}');
    }
  }

  // 测试收藏项管理
  Future<void> _testFavoriteItems() async {
    // 1. 获取电影类型的收藏夹
    _addLog('1. 获取电影收藏夹...');
    final collectionsResponse = await ApiService.getCollectionsByType('MOVIE');
    
    if (!collectionsResponse.isSuccess || collectionsResponse.data == null || collectionsResponse.data!.isEmpty) {
      _addLog('没有电影收藏夹');
      return;
    }
    
    final collection = collectionsResponse.data!.first;
    _addLog('使用收藏夹: ${collection.name} (ID: ${collection.id})');
    
    // 2. 添加收藏项
    _addLog('\n2. 添加收藏项...');
    final addResponse = await ApiService.addFavoriteItem(
      collectionId: collection.id,
      itemType: 'MOVIE',
      itemId: 100, // 测试电影ID
      note: '这是一部很棒的电影',
    );
    
    if (addResponse.isSuccess && addResponse.data != null) {
      _addLog('添加成功: 电影ID ${addResponse.data!.itemId}');
      
      // 3. 获取收藏项列表
      _addLog('\n3. 获取收藏项列表...');
      final itemsResponse = await ApiService.getFavoriteItems(collection.id);
      if (itemsResponse.isSuccess && itemsResponse.data != null) {
        _addLog('收藏项数量: ${itemsResponse.data!.length}');
      }
      
      // 4. 检查收藏状态
      _addLog('\n4. 检查收藏状态...');
      final checkResponse = await ApiService.checkFavoriteStatus(
        itemType: 'MOVIE',
        itemId: 100,
      );
      if (checkResponse.isSuccess && checkResponse.data != null) {
        _addLog('是否已收藏: ${checkResponse.data!['isFavorited']}');
      }
      
      // 5. 移除收藏项
      _addLog('\n5. 移除收藏项...');
      final removeResponse = await ApiService.removeFavoriteItem(
        collectionId: collection.id,
        itemType: 'MOVIE',
        itemId: 100,
      );
      if (removeResponse.isSuccess) {
        _addLog('移除成功');
      } else {
        _addLog('移除失败: ${removeResponse.message}');
      }
    } else {
      _addLog('添加失败: ${addResponse.message}');
    }
  }

  // 测试看过记录
  Future<void> _testWatchedMovies() async {
    const testMovieId = 200;
    
    // 1. 标记为看过
    _addLog('1. 标记电影为看过...');
    final markResponse = await ApiService.markAsWatched(
      movieId: testMovieId,
      rating: 9.5,
      note: '非常精彩的电影!',
    );
    
    if (markResponse.isSuccess && markResponse.data != null) {
      _addLog('标记成功: 电影ID $testMovieId, 评分 ${markResponse.data!.rating}');
      
      // 2. 检查看过状态
      _addLog('\n2. 检查看过状态...');
      final checkResponse = await ApiService.checkWatchedStatus(testMovieId);
      if (checkResponse.isSuccess && checkResponse.data != null) {
        _addLog('是否看过: ${checkResponse.data!['isWatched']}');
      }
      
      // 3. 更新看过记录
      _addLog('\n3. 更新看过记录...');
      final updateResponse = await ApiService.updateWatchedMovie(
        movieId: testMovieId,
        rating: 9.0,
        note: '更新后的笔记',
      );
      if (updateResponse.isSuccess) {
        _addLog('更新成功: 新评分 ${updateResponse.data!.rating}');
      }
      
      // 4. 获取看过列表
      _addLog('\n4. 获取看过列表...');
      final listResponse = await ApiService.getWatchedMovies();
      if (listResponse.isSuccess && listResponse.data != null) {
        _addLog('看过电影数量: ${listResponse.data!.length}');
      }
      
      // 5. 获取看过数量
      _addLog('\n5. 获取看过数量...');
      final countResponse = await ApiService.getWatchedCount();
      if (countResponse.isSuccess && countResponse.data != null) {
        _addLog('看过数量: ${countResponse.data!['count']}');
      }
      
      // 6. 取消看过标记
      _addLog('\n6. 取消看过标记...');
      final unmarkResponse = await ApiService.unmarkAsWatched(testMovieId);
      if (unmarkResponse.isSuccess) {
        _addLog('取消成功');
      } else {
        _addLog('取消失败: ${unmarkResponse.message}');
      }
    } else {
      _addLog('标记失败: ${markResponse.message}');
    }
  }

  // 测试关注功能
  Future<void> _testFollowSystem() async {
    const testUserId = 2; // 测试用户ID
    
    // 1. 关注用户
    _addLog('1. 关注用户...');
    final followResponse = await ApiService.followUser(testUserId);
    if (followResponse.isSuccess) {
      _addLog('关注成功');
    } else {
      _addLog('关注失败: ${followResponse.message}');
    }
    
    // 2. 获取关注状态
    _addLog('\n2. 获取关注状态...');
    final statusResponse = await ApiService.getFollowStatus(testUserId);
    if (statusResponse.isSuccess && statusResponse.data != null) {
      final status = statusResponse.data!;
      _addLog('我关注了对方: ${status['isFollowing']}');
      _addLog('对方关注了我: ${status['isFollower']}');
      _addLog('是否为好友: ${status['isFriend']}');
    }
    
    // 3. 获取关注列表
    _addLog('\n3. 获取关注列表...');
    final user = await StorageService.getUser();
    if (user != null) {
      final followingResponse = await ApiService.getFollowingList(user.id);
      if (followingResponse.isSuccess && followingResponse.data != null) {
        final content = followingResponse.data!['content'] as List;
        _addLog('关注数量: ${followingResponse.data!['totalElements']}');
      }
    }
    
    // 4. 取消关注
    _addLog('\n4. 取消关注...');
    final unfollowResponse = await ApiService.unfollowUser(testUserId);
    if (unfollowResponse.isSuccess) {
      _addLog('取消关注成功');
    } else {
      _addLog('取消关注失败: ${unfollowResponse.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API接口测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearLog,
            tooltip: '清空日志',
          ),
        ],
      ),
      body: Column(
        children: [
          // 测试结果显示区域
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: SelectableText(
                  _testResult,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          
          // 加载指示器
          if (_isLoading)
            const LinearProgressIndicator(),
          
          // 测试按钮区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '选择要测试的API:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTestButton(
                      '用户统计',
                      Icons.analytics,
                      () => _testApi('用户统计信息', _testUserStats),
                    ),
                    _buildTestButton(
                      '收藏夹管理',
                      Icons.folder,
                      () => _testApi('收藏夹管理', _testCollections),
                    ),
                    _buildTestButton(
                      '收藏项管理',
                      Icons.favorite,
                      () => _testApi('收藏项管理', _testFavoriteItems),
                    ),
                    _buildTestButton(
                      '看过记录',
                      Icons.visibility,
                      () => _testApi('看过记录', _testWatchedMovies),
                    ),
                    _buildTestButton(
                      '关注系统',
                      Icons.people,
                      () => _testApi('关注系统', _testFollowSystem),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

