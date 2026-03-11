import '../config/api_config.dart';

/// 活动参与者模型
class EventParticipant {
  final int id;
  final int userId;
  final String username;
  final String userCode;
  final String? avatar;
  final String? bio; // 用户个人简介
  final DateTime joinedAt;
  
  // 报名时填写的信息
  final String participantNickname;
  final String participantPhone;
  final String? participantWechat;
  final String? participantQq;

  EventParticipant({
    required this.id,
    required this.userId,
    required this.username,
    required this.userCode,
    this.avatar,
    this.bio,
    required this.joinedAt,
    required this.participantNickname,
    required this.participantPhone,
    this.participantWechat,
    this.participantQq,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: json['id'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String,
      userCode: json['userCode'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      participantNickname: json['participantNickname'] as String? ?? json['username'] as String,
      participantPhone: json['participantPhone'] as String? ?? '',
      participantWechat: json['participantWechat'] as String?,
      participantQq: json['participantQq'] as String?,
    );
  }

  /// 获取完整的头像URL
  String? get fullAvatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    return ApiConfig.getImageUrl(avatar!);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userCode': userCode,
      'avatar': avatar,
      'bio': bio,
      'joinedAt': joinedAt.toIso8601String(),
      'participantNickname': participantNickname,
      'participantPhone': participantPhone,
      'participantWechat': participantWechat,
      'participantQq': participantQq,
    };
  }
}



