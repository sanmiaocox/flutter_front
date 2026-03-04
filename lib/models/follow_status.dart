/// 关注状态模型
class FollowStatus {
  final bool isFollowing;
  final bool isFollower;
  final bool isFriend;

  FollowStatus({
    required this.isFollowing,
    required this.isFollower,
    required this.isFriend,
  });

  factory FollowStatus.fromJson(Map<String, dynamic> json) {
    return FollowStatus(
      isFollowing: json['isFollowing'] as bool,
      isFollower: json['isFollower'] as bool,
      isFriend: json['isFriend'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isFollowing': isFollowing,
      'isFollower': isFollower,
      'isFriend': isFriend,
    };
  }
}







