import 'package:flutter/material.dart';
import '../../../app_theme.dart';
import '../../../services/api_service.dart';
import '../../../models/tmdb_movie.dart';
import '../movie_detail/movie_detail_page.dart';

/// 搜索页（二级，属主页）：搜索电影
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  
  List<TmdbMovie> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  String _lastKeyword = '';
  
  // 每页显示数量
  static const int _pageSize = 15;
  
  // 筛选功能保留但不使用的变量
  // final _yearController = TextEditingController();
  // List<MovieGenre> _genres = [];
  // bool _isLoadingGenres = true;
  // String? _selectedGenreId;
  // int? _selectedYear;
  // String? _selectedRating;
  // String _sortBy = 'popularity.desc';
  // bool _showFilters = false;
  // final List<Map<String, dynamic>> _ratingRanges = [...];
  // final List<Map<String, String>> _sortOptions = [...];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _currentPage < _totalPages) {
        _loadMore();
      }
    }
  }

  // 筛选功能保留但不使用
  // /// 加载电影类型列表
  // Future<void> _loadGenres() async {
  //   try {
  //     final response = await ApiService.getMovieGenres();
  //     
  //     if (!mounted) return;
  //     
  //     if (response.isSuccess && response.data != null) {
  //       setState(() {
  //         _genres = response.data!.genres;
  //         _isLoadingGenres = false;
  //       });
  //     } else {
  //       setState(() {
  //         _isLoadingGenres = false;
  //       });
  //     }
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _isLoadingGenres = false;
  //     });
  //   }
  // }

  /// 搜索或筛选电影
  Future<void> _search() async {
    final keyword = _controller.text.trim();
    
    if (keyword.isEmpty) {
      setState(() {
        _errorMessage = '请输入搜索关键词';
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _currentPage = 1;
      _lastKeyword = keyword;
    });

    try {
      // 使用搜索接口
      final response = await ApiService.searchMovies(
        keyword: keyword,
        page: 1,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          _searchResults = response.data!.results;
          _totalPages = response.data!.totalPages;
          _isSearching = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '搜索失败: $e';
        _isSearching = false;
      });
    }
  }

  /// 加载更多
  Future<void> _loadMore() async {
    if (_lastKeyword.isEmpty) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      // 使用搜索接口
      final response = await ApiService.searchMovies(
        keyword: _lastKeyword,
        page: _currentPage + 1,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          _searchResults.addAll(response.data!.results);
          _currentPage++;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // 筛选功能保留但不使用
  // double? _getMinRating() {
  //   if (_selectedRating == null) return null;
  //   final range = _ratingRanges.firstWhere(
  //     (r) => r['label'] == _selectedRating,
  //     orElse: () => _ratingRanges[0],
  //   );
  //   return range['min'] as double?;
  // }

  // double? _getMaxRating() {
  //   if (_selectedRating == null) return null;
  //   final range = _ratingRanges.firstWhere(
  //     (r) => r['label'] == _selectedRating,
  //     orElse: () => _ratingRanges[0],
  //   );
  //   return range['max'] as double?;
  // }

  // 筛选功能保留但不使用
  // /// 重置筛选条件
  // void _resetFilters() {
  //   setState(() {
  //     _selectedGenreId = null;
  //     _selectedYear = null;
  //     _selectedRating = null;
  //     _sortBy = 'popularity.desc';
  //     _yearController.clear();
  //   });
  //   if (_lastKeyword.isEmpty) {
  //     _search();
  //   }
  // }

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
                fontSize: 15,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              isDense: true,
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _searchResults.clear();
                          _lastKeyword = '';
                        });
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _search(),
            onChanged: (_) => setState(() {}),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _controller.text.isEmpty ? null : _search,
            child: const Text(
              '搜索',
              style: TextStyle(color: AppTheme.lycheeWhite),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // 筛选功能保留但不使用
  // /// 检查是否有激活的筛选条件
  // bool _hasActiveFilters() {
  //   return _selectedGenreId != null ||
  //          _yearController.text.trim().isNotEmpty ||
  //          _selectedRating != null ||
  //          _sortBy != 'popularity.desc';
  // }

  // /// 构建筛选面板
  // Widget _buildFilterPanel() { ... }
  
  // Widget _buildFilterRow(String label, Widget child) { ... }

  Widget _buildBody() {
    if (_isSearching) {
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
              onPressed: _search,
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

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppTheme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              _lastKeyword.isEmpty
                  ? '输入关键词搜索电影'
                  : '未找到相关电影',
              style: TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 6,
      radius: const Radius.circular(3),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _searchResults.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: AppTheme.capriBlue,
                ),
              ),
            );
          }

          final movie = _searchResults[index];
          return _buildMovieItem(movie);
        },
      ),
    );
  }

  Widget _buildMovieItem(TmdbMovie movie) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailPage(movieId: movie.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.capriBlue.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.getPosterUrl() != null
                  ? Image.network(
                      movie.getPosterUrl(size: 'w185')!,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 120,
                        color: AppTheme.muted,
                        child: const Icon(Icons.movie),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 120,
                      color: AppTheme.muted,
                      child: const Icon(Icons.movie),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.capriBlue,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (movie.originalTitle != movie.title) ...[
                    const SizedBox(height: 4),
                    Text(
                      movie.originalTitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.formattedRating,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (movie.year != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          movie.year!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (movie.overview != null && movie.overview!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      movie.overview!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.mutedForeground,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
