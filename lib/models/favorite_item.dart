/// 收藏项模型
class FavoriteItem {
  final int id;
  final int collectionId;
  final String itemType; // MOVIE/EVENT
  final int itemId;
  final String? note;
  final String createdAt;
  final Map<String, dynamic>? itemDetail;

  FavoriteItem({
    required this.id,
    required this.collectionId,
    required this.itemType,
    required this.itemId,
    this.note,
    required this.createdAt,
    this.itemDetail,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] as int,
      collectionId: json['collectionId'] as int,
      itemType: json['itemType'] as String,
      itemId: json['itemId'] as int,
      note: json['note'] as String?,
      createdAt: json['createdAt'] as String,
      itemDetail: json['itemDetail'] != null 
          ? Map<String, dynamic>.from(json['itemDetail'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collectionId': collectionId,
      'itemType': itemType,
      'itemId': itemId,
      'note': note,
      'createdAt': createdAt,
      'itemDetail': itemDetail,
    };
  }
}






