import 'tmdb_movie.dart';

/// TMDB搜索响应模型
class TmdbSearchResponse {
  final int page;
  final List<TmdbMovie> results;
  final int totalPages;
  final int totalResults;

  TmdbSearchResponse({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory TmdbSearchResponse.fromJson(Map<String, dynamic> json) {
    return TmdbSearchResponse(
      page: json['page'] as int? ?? 1,
      results: (json['results'] as List<dynamic>?)
              ?.map((item) => TmdbMovie.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalPages: json['total_pages'] as int? ?? 0,
      totalResults: json['total_results'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'results': results.map((movie) => movie.toJson()).toList(),
      'total_pages': totalPages,
      'total_results': totalResults,
    };
  }

  /// 是否有更多页
  bool get hasMorePages => page < totalPages;

  /// 是否为空结果
  bool get isEmpty => results.isEmpty;
}



