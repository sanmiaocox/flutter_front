import '../config/api_config.dart';

/// 活动模型
class Event {
  final int id;
  final int creatorId;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime eventDate;
  final String location;
  final int participants;
  final int maxParticipants;
  final String status;
  final String type;
  final int? movieId;
  final String? movieTitle;
  final String? moviePosterUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isCreator;
  final bool isParticipant;

  Event({
    required this.id,
    required this.creatorId,
    required this.title,
    this.description,
    this.imageUrl,
    required this.eventDate,
    required this.location,
    required this.participants,
    required this.maxParticipants,
    required this.status,
    required this.type,
    this.movieId,
    this.movieTitle,
    this.moviePosterUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isCreator = false,
    this.isParticipant = false,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      creatorId: json['creatorId'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      eventDate: DateTime.parse(json['eventDate'] as String),
      location: json['location'] as String,
      participants: json['participants'] as int,
      maxParticipants: json['maxParticipants'] as int,
      status: json['status'] as String,
      type: json['type'] as String,
      movieId: json['movieId'] as int?,
      movieTitle: json['movieTitle'] as String?,
      moviePosterUrl: json['moviePosterUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isCreator: json['isCreator'] as bool? ?? false,
      isParticipant: json['isParticipant'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'eventDate': eventDate.toIso8601String(),
      'location': location,
      'participants': participants,
      'maxParticipants': maxParticipants,
      'status': status,
      'type': type,
      'movieId': movieId,
      'movieTitle': movieTitle,
      'moviePosterUrl': moviePosterUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isCreator': isCreator,
      'isParticipant': isParticipant,
    };
  }

  /// 获取完整的图片URL
  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    return ApiConfig.getImageUrl(imageUrl!);
  }

  /// 获取完整的电影海报URL
  String? get fullMoviePosterUrl {
    if (moviePosterUrl == null || moviePosterUrl!.isEmpty) return null;
    return ApiConfig.getImageUrl(moviePosterUrl!);
  }

  /// 是否已满员
  bool get isFull => participants >= maxParticipants;

  /// 活动状态文本
  String get statusText {
    switch (status) {
      case 'UPCOMING':
        return '即将开始';
      case 'ONGOING':
        return '进行中';
      case 'ENDED':
        return '已结束';
      default:
        return status;
    }
  }

  /// 活动状态颜色
  int get statusColor {
    switch (status) {
      case 'UPCOMING':
        return 0xFF4CAF50; // 绿色
      case 'ONGOING':
        return 0xFF2196F3; // 蓝色
      case 'ENDED':
        return 0xFF9E9E9E; // 灰色
      default:
        return 0xFF9E9E9E;
    }
  }
}

