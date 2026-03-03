/// 收藏夹模型
class Collection {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final String type; // MOVIE/EVENT
  final bool isSystem;
  final bool isPublic;
  final String? coverImage;
  final int itemCount;
  final String createdAt;
  final String updatedAt;

  Collection({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.type,
    required this.isSystem,
    required this.isPublic,
    this.coverImage,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as int,
      userId: json['userId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String,
      isSystem: json['isSystem'] as bool,
      isPublic: json['isPublic'] as bool,
      coverImage: json['coverImage'] as String?,
      itemCount: json['itemCount'] as int,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'type': type,
      'isSystem': isSystem,
      'isPublic': isPublic,
      'coverImage': coverImage,
      'itemCount': itemCount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}




