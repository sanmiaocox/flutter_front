import '../config/api_config.dart';

/// 动态中的用户信息
class FeedUser {
  final int id;
  final String userCode;
  final String username;
  final String? avatar;

  FeedUser({
    required this.id,
    required this.userCode,
    required this.username,
    this.avatar,
  });

  factory FeedUser.fromJson(Map<String, dynamic> json) {
    return FeedUser(
      id: json['id'] as int,
      userCode: json['userCode'] as String,
      username: json['username'] as String,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCode': userCode,
      'username': username,
      'avatar': avatar,
    };
  }

  /// 获取完整的头像URL
  String? get fullAvatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    return ApiConfig.getImageUrl(avatar!);
  }
}

/// 动态中的电影信息
class FeedMovie {
  final int id;
  final int tmdbId;
  final String title;
  final String? posterUrl;
  final double rating;

  FeedMovie({
    required this.id,
    required this.tmdbId,
    required this.title,
    this.posterUrl,
    required this.rating,
  });

  factory FeedMovie.fromJson(Map<String, dynamic> json) {
    return FeedMovie(
      id: json['id'] as int,
      tmdbId: json['tmdbId'] as int,
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String?,
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tmdbId': tmdbId,
      'title': title,
      'posterUrl': posterUrl,
      'rating': rating,
    };
  }
}

/// 动态中的活动信息
class FeedEvent {
  final int id;
  final String title;
  final String? imageUrl;
  final String? location;
  final DateTime? eventDate;

  FeedEvent({
    required this.id,
    required this.title,
    this.imageUrl,
    this.location,
    this.eventDate,
  });

  factory FeedEvent.fromJson(Map<String, dynamic> json) {
    return FeedEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      location: json['location'] as String?,
      eventDate: json['eventDate'] != null 
          ? DateTime.parse(json['eventDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'location': location,
      'eventDate': eventDate?.toIso8601String(),
    };
  }

  /// 获取完整的图片URL
  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    return ApiConfig.getImageUrl(imageUrl!);
  }
}

/// 动态模型
class Feed {
  final int id;
  final FeedUser user;
  final FeedMovie? movie;
  final FeedEvent? event;
  final String content;
  final List<String> images;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  Feed({
    required this.id,
    required this.user,
    this.movie,
    this.event,
    required this.content,
    required this.images,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      id: json['id'] as int,
      user: FeedUser.fromJson(json['user'] as Map<String, dynamic>),
      movie: json['movie'] != null
          ? FeedMovie.fromJson(json['movie'] as Map<String, dynamic>)
          : null,
      event: json['event'] != null
          ? FeedEvent.fromJson(json['event'] as Map<String, dynamic>)
          : null,
      content: json['content'] as String,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      likeCount: json['likeCount'] as int,
      commentCount: json['commentCount'] as int,
      isLiked: json['isLiked'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'movie': movie?.toJson(),
      'event': event?.toJson(),
      'content': content,
      'images': images,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 获取完整的图片URL列表
  List<String> get fullImageUrls {
    return images.map((img) => ApiConfig.getImageUrl(img)).toList();
  }

  /// 复制并更新点赞状态
  Feed copyWith({
    int? likeCount,
    bool? isLiked,
    int? commentCount,
  }) {
    return Feed(
      id: id,
      user: user,
      movie: movie,
      event: event,
      content: content,
      images: images,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}


