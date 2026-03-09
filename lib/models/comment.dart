import '../config/api_config.dart';

/// 评论中的用户信息
class CommentUser {
  final int id;
  final String userCode;
  final String username;
  final String? avatar;

  CommentUser({
    required this.id,
    required this.userCode,
    required this.username,
    this.avatar,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
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

/// 评论模型
class Comment {
  final int id;
  final CommentUser user;
  final String content;
  final int likeCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.user,
    required this.content,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      user: CommentUser.fromJson(json['user'] as Map<String, dynamic>),
      content: json['content'] as String,
      likeCount: json['likeCount'] as int,
      isLiked: json['isLiked'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.toJson(),
      'content': content,
      'likeCount': likeCount,
      'isLiked': isLiked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并更新点赞状态
  Comment copyWith({
    int? likeCount,
    bool? isLiked,
  }) {
    return Comment(
      id: id,
      user: user,
      content: content,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// 点赞响应模型
class LikeResponse {
  final bool isLiked;
  final int likeCount;

  LikeResponse({
    required this.isLiked,
    required this.likeCount,
  });

  factory LikeResponse.fromJson(Map<String, dynamic> json) {
    return LikeResponse(
      isLiked: json['isLiked'] as bool,
      likeCount: json['likeCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isLiked': isLiked,
      'likeCount': likeCount,
    };
  }
}


