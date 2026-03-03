/// 看过记录模型
class WatchedMovie {
  final int id;
  final int userId;
  final int movieId;
  final String watchedAt;
  final double? rating;
  final String? note;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic>? movieInfo;

  WatchedMovie({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.watchedAt,
    this.rating,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    this.movieInfo,
  });

  factory WatchedMovie.fromJson(Map<String, dynamic> json) {
    return WatchedMovie(
      id: json['id'] as int,
      userId: json['userId'] as int,
      movieId: json['movieId'] as int,
      watchedAt: json['watchedAt'] as String,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      note: json['note'] as String?,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      movieInfo: json['movieInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'movieId': movieId,
      'watchedAt': watchedAt,
      'rating': rating,
      'note': note,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'movieInfo': movieInfo,
    };
  }
}




