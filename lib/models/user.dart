/// 用户信息模型
class User {
  final int id;
  final String userCode;  // 4位数字用户识别码
  final String username;
  final String phone;
  final String? avatar;
  final String createdAt;

  User({
    required this.id,
    required this.userCode,
    required this.username,
    required this.phone,
    this.avatar,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      userCode: json['userCode'] as String? ?? json['user_code'] as String? ?? '',
      username: json['username'] as String,
      phone: json['phone'] as String,
      avatar: json['avatar'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userCode': userCode,
      'username': username,
      'phone': phone,
      'avatar': avatar,
      'createdAt': createdAt,
    };
  }
}

