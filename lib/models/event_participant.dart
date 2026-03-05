/// 活动参与者模型
class EventParticipant {
  final int id;
  final int userId;
  final String username;
  final String userCode;
  final String? avatar;
  final DateTime joinedAt;

  EventParticipant({
    required this.id,
    required this.userId,
    required this.username,
    required this.userCode,
    this.avatar,
    required this.joinedAt,
  });

  factory EventParticipant.fromJson(Map<String, dynamic> json) {
    return EventParticipant(
      id: json['id'] as int,
      userId: json['userId'] as int,
      username: json['username'] as String,
      userCode: json['userCode'] as String,
      avatar: json['avatar'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userCode': userCode,
      'avatar': avatar,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}



