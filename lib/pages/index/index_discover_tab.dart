import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../models/api_response.dart';
import '../../services/api_service.dart';
import '../../models/tmdb_movie.dart';
import '../../models/movie_genre.dart';

/// 主页 - 发现电影 Tab 内容：支持筛选的电影列表
class IndexDiscoverTab extends StatefulWidget {
  const IndexDiscoverTab({
    super.key,
    this.onTapMovie,
  });

  final void Function(int movieId)? onTapMovie;

  @override
  State<IndexDiscoverTab> createState() => _IndexDiscoverTabState();
}

class _IndexDiscoverTabState extends State<IndexDiscoverTab> {
  final _scrollController = ScrollController();
  final _yearController = TextEditingController();
  
  List<TmdbMovie> _movies = [];
  List<MovieGenre> _genres = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingGenres = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  
  // 筛选条件
  String? _selectedGenreId;
  int? _selectedYear;
  String? _selectedRating;
  String _sortBy = 'popularity.desc';
  bool _showFilters = false;

  // 评分范围选项
  final List<Map<String, dynamic>> _ratingRanges = [
    {'label': '全部评分', 'min': null, 'max': null},
    {'label': '9分以上', 'min': 9.0, 'max': null},
    {'label': '8-9分', 'min': 8.0, 'max': 9.0},
    {'label': '7-8分', 'min': 7.0, 'max': 8.0},
    {'label': '6-7分', 'min': 6.0, 'max': 7.0},
    {'label': '6分以下', 'min': null, 'max': 6.0},
  ];

  // 排序选项
  final List<Map<String, String>> _sortOptions = [
    {'label': '人气降序', 'value': 'popularity.desc'},
    {'label': '评分降序', 'value': 'vote_average.desc'},
    {'label': '上映日期降序', 'value': 'release_date.desc'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadGenres();
    _loadMovies();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _yearController.dispose();
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

  /// 加载电影类型列表
  Future<void> _loadGenres() async {
    try {
      final response = await ApiService.getMovieGenres();
      
      if (!mounted) return;
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _genres = response.data!.genres;
          _isLoadingGenres = false;
        });
      } else {
        setState(() {
          _isLoadingGenres = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingGenres = false;
      });
    }
  }

  /// 加载电影列表
  Future<void> _loadMovies() async {
    // 解析年份输入
    int? year;
    if (_yearController.text.trim().isNotEmpty) {
      year = int.tryParse(_yearController.text.trim());
      if (year == null || year < 1900 || year > DateTime.now().year + 5) {
        setState(() {
          _errorMessage = '请输入有效的年份（1900-${DateTime.now().year + 5}）';
        });
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _selectedYear = year;
    });

    try {
      final response = await ApiService.discoverMovies(
        page: 1,
        pageSize: 20,
        sortBy: _sortBy,
        withGenres: _selectedGenreId,
        primaryReleaseYear: _selectedYear,
        voteAverageGte: _getMinRating(),
        voteAverageLte: _getMaxRating(),
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          _movies = response.data!.results;
          _totalPages = response.data!.totalPages;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 加载更多
  Future<void> _loadMore() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await ApiService.discoverMovies(
        page: _currentPage + 1,
        pageSize: 20,
        sortBy: _sortBy,
        withGenres: _selectedGenreId,
        primaryReleaseYear: _selectedYear,
        voteAverageGte: _getMinRating(),
        voteAverageLte: _getMaxRating(),
      );

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          _movies.addAll(response.data!.results);
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

  double? _getMinRating() {
    if (_selectedRating == null) return null;
    final range = _ratingRanges.firstWhere(
      (r) => r['label'] == _selectedRating,
      orElse: () => _ratingRanges[0],
    );
    return range['min'] as double?;
  }

  double? _getMaxRating() {
    if (_selectedRating == null) return null;
    final range = _ratingRanges.firstWhere(
      (r) => r['label'] == _selectedRating,
      orElse: () => _ratingRanges[0],
    );
    return range['max'] as double?;
  }

  /// 重置筛选条件
  void _resetFilters() {
    setState(() {
      _selectedGenreId = null;
      _selectedYear = null;
      _selectedRating = null;
      _sortBy = 'popularity.desc';
      _yearController.clear();
    });
    _loadMovies();
  }

  /// 检查是否有激活的筛选条件
  bool _hasActiveFilters() {
    return _selectedGenreId != null ||
           _yearController.text.trim().isNotEmpty ||
           _selectedRating != null ||
           _sortBy != 'popularity.desc';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 筛选按钮栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.lycheeWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _hasActiveFilters() ? '已应用筛选条件' : '发现精彩电影',
                  style: TextStyle(
                    color: AppTheme.capriBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_hasActiveFilters())
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('重置'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.softPeach,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              IconButton(
                icon: Icon(
                  _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: _hasActiveFilters() ? AppTheme.softPeach : AppTheme.capriBlue,
                ),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                tooltip: '筛选',
              ),
            ],
          ),
        ),
        
        // 筛选面板
        if (_showFilters) _buildFilterPanel(),
        
        // 内容区域
        Expanded(child: _buildBody()),
      ],
    );
  }

  /// 构建筛选面板
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lycheeWhite,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.muted.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 类型筛选
          _buildFilterRow(
            '类型',
            _isLoadingGenres
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : DropdownButton<String>(
                    value: _selectedGenreId,
                    hint: const Text('全部类型'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('全部类型')),
                      ..._genres.map((genre) => DropdownMenuItem<String>(
                            value: genre.id.toString(),
                            child: Text(genre.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGenreId = value;
                      });
                    },
                  ),
          ),
          const SizedBox(height: 12),
          
          // 年份筛选
          _buildFilterRow(
            '年份',
            TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '输入年份（如：2024）',
                hintStyle: TextStyle(
                  color: AppTheme.mutedForeground.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.muted),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.muted),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.capriBlue),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
                suffixIcon: _yearController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _yearController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          
          // 评分筛选
          _buildFilterRow(
            '评分',
            DropdownButton<String>(
              value: _selectedRating,
              hint: const Text('全部评分'),
              isExpanded: true,
              items: _ratingRanges.map((range) => DropdownMenuItem<String>(
                    value: range['label'],
                    child: Text(range['label']),
                  )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRating = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // 排序方式
          _buildFilterRow(
            '排序',
            DropdownButton<String>(
              value: _sortBy,
              isExpanded: true,
              items: _sortOptions.map((option) => DropdownMenuItem<String>(
                    value: option['value'],
                    child: Text(option['label']!),
                  )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortBy = value;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // 应用按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loadMovies,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.capriBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('应用筛选'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(String label, Widget child) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildBody() {
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
              onPressed: _loadMovies,
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

    if (_movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter,
              size: 64,
              color: AppTheme.mutedForeground,
            ),
            const SizedBox(height: 16),
            Text(
              '未找到符合条件的电影',
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
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: _movies.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _movies.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: AppTheme.capriBlue,
                ),
              ),
            );
          }

          final movie = _movies[index];
          return _buildMovieCard(movie);
        },
      ),
    );
  }

  Widget _buildMovieCard(TmdbMovie movie) {
    return GestureDetector(
      onTap: widget.onTapMovie != null 
          ? () => widget.onTapMovie!(movie.id)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.getPosterUrl() != null
                  ? Image.network(
                      movie.getPosterUrl(size: 'w342')!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppTheme.muted,
                        child: const Icon(Icons.movie, size: 48),
                      ),
                    )
                  : Container(
                      color: AppTheme.muted,
                      child: const Icon(Icons.movie, size: 48),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            movie.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
                movie.formattedRating,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

