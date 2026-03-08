/// 电影类型模型
class MovieGenre {
  final int id;
  final String name;

  MovieGenre({
    required this.id,
    required this.name,
  });

  factory MovieGenre.fromJson(Map<String, dynamic> json) {
    return MovieGenre(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

/// 电影类型列表响应
class MovieGenreListResponse {
  final List<MovieGenre> genres;

  MovieGenreListResponse({
    required this.genres,
  });

  factory MovieGenreListResponse.fromJson(Map<String, dynamic> json) {
    final genresList = json['genres'] as List<dynamic>;
    return MovieGenreListResponse(
      genres: genresList
          .map((item) => MovieGenre.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

