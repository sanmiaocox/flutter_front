/// 用户统计信息模型
class UserStats {
  final int followingCount;
  final int followerCount;
  final int friendCount;

  UserStats({
    required this.followingCount,
    required this.followerCount,
    required this.friendCount,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      followingCount: json['followingCount'] as int,
      followerCount: json['followerCount'] as int,
      friendCount: json['friendCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followingCount': followingCount,
      'followerCount': followerCount,
      'friendCount': friendCount,
    };
  }
}

