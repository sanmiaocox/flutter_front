import '../config/api_config.dart';

/// 用户信息模型
class User {
  final int id;
  final String userCode;  // 4位数字用户识别码
  final String username;
  final String phone;
  final String? avatar;
  final String? bio;
  final String createdAt;

  User({
    required this.id,
    required this.userCode,
    required this.username,
    required this.phone,
    this.avatar,
    this.bio,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      userCode: json['userCode'] as String? ?? json['user_code'] as String? ?? '',
      username: json['username'] as String,
      phone: json['phone'] as String,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      createdAt: json['createdAt'] as String,
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
      'userCode': userCode,
      'username': username,
      'phone': phone,
      'avatar': avatar,
      'bio': bio,
      'createdAt': createdAt,
    };
  }
}

