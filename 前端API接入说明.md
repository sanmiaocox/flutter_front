# 前端API接入说明

## 概述

本文档说明前端如何使用已接入的后端API接口。所有接口都已在 `lib/services/api_service.dart` 中实现。

## 已接入的API接口

### 1. 用户认证接口

#### 注册
```dart
final response = await ApiService.register(
  username: '用户名',
  phone: '13800138000',
  password: '123456',
);
```

#### 登录
```dart
final response = await ApiService.login(
  phone: '13800138000',
  password: '123456',
  timeout: Duration(seconds: 10), // 可选,默认10秒
);
```

### 2. 用户信息接口

#### 获取当前用户信息
```dart
final response = await ApiService.getCurrentUserProfile();
if (response.isSuccess && response.data != null) {
  User user = response.data!;
  print('用户名: ${user.username}');
  print('个人简介: ${user.bio}');
}
```

#### 更新个人资料
```dart
final response = await ApiService.updateProfile(
  username: '新用户名',
  avatar: 'https://example.com/avatar.jpg',
  bio: '这是我的新个人简介',
);
```

#### 获取指定用户信息
```dart
final response = await ApiService.getUserProfile(userId);
```

### 3. 关注系统接口

#### 关注用户
```dart
final response = await ApiService.followUser(userId);
```

#### 取消关注
```dart
final response = await ApiService.unfollowUser(userId);
```

#### 获取关注列表
```dart
final response = await ApiService.getFollowingList(
  userId,
  page: 0,
  size: 20,
);
```

#### 获取粉丝列表
```dart
final response = await ApiService.getFollowersList(
  userId,
  page: 0,
  size: 20,
);
```

#### 获取好友列表
```dart
final response = await ApiService.getFriendsList(userId);
```

#### 获取关注状态
```dart
final response = await ApiService.getFollowStatus(userId);
if (response.isSuccess && response.data != null) {
  FollowStatus status = response.data!;
  print('我关注了对方: ${status.isFollowing}');
  print('对方关注了我: ${status.isFollower}');
  print('是否为好友: ${status.isFriend}');
}
```

#### 获取用户统计信息
```dart
final response = await ApiService.getUserStats(userId);
if (response.isSuccess && response.data != null) {
  UserStats stats = response.data!;
  print('关注数: ${stats.followingCount}');
  print('粉丝数: ${stats.followerCount}');
  print('好友数: ${stats.friendCount}');
}
```

### 4. 收藏夹管理接口

#### 创建收藏夹
```dart
final response = await ApiService.createCollection(
  name: '我的科幻片单',
  type: 'MOVIE', // MOVIE 或 EVENT
  description: '收藏的科幻电影',
  isPublic: true,
  coverImage: 'https://example.com/cover.jpg',
);
```

#### 获取所有收藏夹
```dart
final response = await ApiService.getCollections();
if (response.isSuccess && response.data != null) {
  List<Collection> collections = response.data!;
  for (var collection in collections) {
    print('${collection.name}: ${collection.itemCount}项');
  }
}
```

#### 获取指定类型的收藏夹
```dart
final response = await ApiService.getCollectionsByType('MOVIE');
```

#### 获取收藏夹详情
```dart
final response = await ApiService.getCollectionDetail(collectionId);
```

#### 更新收藏夹
```dart
final response = await ApiService.updateCollection(
  collectionId: collectionId,
  name: '更新后的名称',
  description: '更新后的描述',
  isPublic: false,
);
```

#### 删除收藏夹
```dart
final response = await ApiService.deleteCollection(collectionId);
```

### 5. 收藏项管理接口

#### 添加收藏项
```dart
final response = await ApiService.addFavoriteItem(
  collectionId: collectionId,
  itemType: 'MOVIE', // MOVIE 或 EVENT
  itemId: 100,
  note: '非常喜欢这部电影',
);
```

#### 获取收藏夹中的所有收藏项
```dart
final response = await ApiService.getFavoriteItems(collectionId);
```

#### 获取收藏夹中指定类型的收藏项
```dart
final response = await ApiService.getFavoriteItemsByType(
  collectionId: collectionId,
  itemType: 'MOVIE',
);
```

#### 移除收藏项
```dart
final response = await ApiService.removeFavoriteItem(
  collectionId: collectionId,
  itemType: 'MOVIE',
  itemId: 100,
);
```

#### 检查是否收藏
```dart
final response = await ApiService.checkFavoriteStatus(
  itemType: 'MOVIE',
  itemId: 100,
);
if (response.isSuccess && response.data != null) {
  bool isFavorited = response.data!['isFavorited'];
  print('是否已收藏: $isFavorited');
}
```

### 6. 看过记录接口

#### 标记电影为看过
```dart
final response = await ApiService.markAsWatched(
  movieId: 100,
  rating: 9.5,
  note: '非常精彩的电影!',
);
```

#### 取消看过标记
```dart
final response = await ApiService.unmarkAsWatched(movieId);
```

#### 更新看过记录
```dart
final response = await ApiService.updateWatchedMovie(
  movieId: movieId,
  rating: 9.0,
  note: '更新后的笔记',
);
```

#### 获取看过的所有电影
```dart
final response = await ApiService.getWatchedMovies();
if (response.isSuccess && response.data != null) {
  List<WatchedMovie> movies = response.data!;
  for (var movie in movies) {
    print('电影ID: ${movie.movieId}, 评分: ${movie.rating}');
  }
}
```

#### 检查是否看过
```dart
final response = await ApiService.checkWatchedStatus(movieId);
if (response.isSuccess && response.data != null) {
  bool isWatched = response.data!['isWatched'];
  print('是否看过: $isWatched');
}
```

#### 获取看过数量
```dart
final response = await ApiService.getWatchedCount();
if (response.isSuccess && response.data != null) {
  int count = response.data!['count'];
  print('看过电影数量: $count');
}
```

## 数据模型

### User (用户)
```dart
class User {
  final int id;
  final String userCode;  // 4位数字用户识别码
  final String username;
  final String phone;
  final String? avatar;
  final String? bio;
  final String createdAt;
}
```

### Collection (收藏夹)
```dart
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
}
```

### FavoriteItem (收藏项)
```dart
class FavoriteItem {
  final int id;
  final int collectionId;
  final String itemType; // MOVIE/EVENT
  final int itemId;
  final String? note;
  final String createdAt;
  final Map<String, dynamic>? itemDetail;
}
```

### WatchedMovie (看过记录)
```dart
class WatchedMovie {
  final int id;
  final int userId;
  final int movieId;
  final String watchedAt;
  final double? rating;
  final String? note;
  final String createdAt;
  final String updatedAt;
  final Map<String, dynamic>? movieInfo;
}
```

### FollowStatus (关注状态)
```dart
class FollowStatus {
  final bool isFollowing; // 我是否关注了对方
  final bool isFollower;  // 对方是否关注了我
  final bool isFriend;    // 是否为好友(互相关注)
}
```

### UserStats (用户统计)
```dart
class UserStats {
  final int followingCount; // 关注数
  final int followerCount;  // 粉丝数
  final int friendCount;    // 好友数
}
```

## 错误处理

所有API调用都返回 `ApiResponse<T>` 对象:

```dart
final response = await ApiService.someMethod();

if (response.isSuccess) {
  // 成功
  if (response.data != null) {
    // 使用 response.data
  }
} else {
  // 失败
  print('错误: ${response.message}');
  print('错误码: ${response.code}');
}
```

## API测试

在应用中进入 **个人中心 → 设置 → API接口测试** 可以测试所有已接入的API接口。

## 注意事项

1. **Token认证**: 除了登录和注册接口外,所有接口都需要Token认证
2. **超时设置**: 登录接口默认超时时间为10秒,可以自定义
3. **错误处理**: 始终检查 `response.isSuccess` 和 `response.data != null`
4. **数据刷新**: 修改数据后记得刷新相关页面的数据
5. **系统收藏夹**: 用户注册时会自动创建默认的电影和活动收藏夹,不能删除

## 待实现的接口

以下接口后端尚未实现,前端暂时无法使用:

- 动态相关接口 (发布/获取/删除动态)
- 评论相关接口
- 点赞相关接口
- 活动相关接口
- 电影相关接口

这些接口将在后端完成后陆续接入。

