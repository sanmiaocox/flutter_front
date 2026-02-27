/// 用户信息模型
class User {
  final int id;
  final String username;
  final String phone;
  final String? avatar;
  final String createdAt;

  User({
    required this.id,
    required this.username,
    required this.phone,
    this.avatar,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      phone: json['phone'] as String,
      avatar: json['avatar'] as String?,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'phone': phone,
      'avatar': avatar,
      'createdAt': createdAt,
    };
  }
}

