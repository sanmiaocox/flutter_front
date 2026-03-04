# 后端API响应格式规则文档

## 概述

本文档记录后端API的实际响应格式，用于前端正确解析后端返回的数据。

## 响应格式分类

后端API存在两种响应格式：

### 1. 标准 ApiResponse 格式

包含 `code`、`message`、`data` 字段的标准格式：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    // 实际数据
  }
}
```

### 2. 直接返回数据对象格式

不包含 `code`、`message` 字段，直接返回数据对象：

```json
{
  "id": 1,
  "name": "...",
  // 其他字段
}
```

或直接返回数组：

```json
[
  {
    "id": 1,
    "name": "..."
  }
]
```

## 各接口实际响应格式

### 收藏夹管理接口

| 接口 | 方法 | 端点 | 响应格式 |
|------|------|------|----------|
| 创建收藏夹 | POST | `/api/collections` | 标准 ApiResponse |
| 获取所有收藏夹 | GET | `/api/collections` | **直接返回数组** |
| 获取指定类型收藏夹 | GET | `/api/collections/type/{type}` | **直接返回数组** |
| 获取收藏夹详情 | GET | `/api/collections/{id}` | 标准 ApiResponse |
| 更新收藏夹 | PUT | `/api/collections/{id}` | 标准 ApiResponse |
| 删除收藏夹 | DELETE | `/api/collections/{id}` | 空响应体 |

**示例 - 获取所有收藏夹：**
```json
[
  {
    "id": 9,
    "userId": 1,
    "name": "我的收藏夹",
    "type": "MOVIE",
    "isSystem": false,
    "isPublic": true,
    "coverImage": "ba936a4e-c535-4d33-ba15-4aab1ae137a9.jpg",
    "itemCount": 0,
    "createdAt": "2026-03-04T22:32:16",
    "updatedAt": "2026-03-04T22:32:16"
  }
]
```

### 收藏项管理接口

| 接口 | 方法 | 端点 | 响应格式 |
|------|------|------|----------|
| 添加收藏项 | POST | `/api/favorites` | **直接返回对象** |
| 获取收藏项列表 | GET | `/api/favorites/collection/{id}` | **直接返回数组** |
| 获取指定类型收藏项 | GET | `/api/favorites/collection/{id}/type/{type}` | 标准 ApiResponse |
| 移除收藏项 | DELETE | `/api/favorites/collection/{id}/item/{type}/{itemId}` | 标准 ApiResponse |
| 检查收藏状态 | GET | `/api/favorites/check/{type}/{itemId}` | 标准 ApiResponse |

**示例 - 添加收藏项：**
```json
{
  "id": 2,
  "collectionId": 9,
  "itemType": "MOVIE",
  "itemId": 1,
  "note": null,
  "createdAt": "2026-03-04T23:56:13.317172",
  "itemDetail": {
    "posterUrl": "https://image.tmdb.org/t/p/w500/buWK1jAS0lrpzGQuqDWl3GHVJdt.jpg",
    "year": "2026",
    "rating": 6.733,
    "id": 1,
    "title": "庇护之地"
  }
}
```

### 看过记录接口

| 接口 | 方法 | 端点 | 响应格式 |
|------|------|------|----------|
| 标记看过 | POST | `/api/watched` | **直接返回对象** |
| 取消看过 | DELETE | `/api/watched/{movieId}` | 标准 ApiResponse |
| 更新看过记录 | PUT | `/api/watched/{movieId}` | 标准 ApiResponse |
| 获取看过列表 | GET | `/api/watched` | **直接返回数组** |
| 检查看过状态 | GET | `/api/watched/check/{movieId}` | 标准 ApiResponse |
| 获取看过数量 | GET | `/api/watched/count` | 标准 ApiResponse |

**示例 - 标记看过：**
```json
{
  "id": 2,
  "userId": 1,
  "movieId": 2,
  "watchedAt": "2026-03-05T00:13:00.7647762",
  "rating": null,
  "note": null,
  "createdAt": "2026-03-05T00:13:00.7662867",
  "updatedAt": "2026-03-05T00:13:00.7662867",
  "movieInfo": {
    "id": 2,
    "title": "镖人：风起大漠",
    "posterUrl": "https://image.tmdb.org/t/p/w500/AsWzPlQK2xJTIrzw6McT8Yvy6H2.jpg",
    "rating": 7.435,
    "year": "2026"
  }
}
```

**示例 - 获取看过列表：**
```json
[]
```
或
```json
[
  {
    "id": 1,
    "userId": 1,
    "movieId": 100,
    "watchedAt": "2026-03-01T10:00:00",
    "rating": 9.5,
    "note": "非常精彩的电影",
    "movieInfo": {
      "id": 100,
      "title": "盗梦空间",
      "posterUrl": "https://example.com/poster.jpg",
      "rating": 9.3,
      "year": "2010"
    }
  }
]
```

## 前端处理策略

### 1. 统一处理方法

对于可能返回两种格式的接口，前端使用以下策略：

```dart
final jsonResponse = jsonDecode(response.body);

// 检查响应类型
if (jsonResponse is List) {
  // 直接返回数组
  final items = jsonResponse
      .map((item) => Model.fromJson(item as Map<String, dynamic>))
      .toList();
  return ApiResponse<List<Model>>(
    code: 200,
    message: 'success',
    data: items,
  );
} else if (jsonResponse is Map<String, dynamic>) {
  // 检查是否是ApiResponse格式
  if (jsonResponse.containsKey('code')) {
    // 标准ApiResponse格式
    return ApiResponse<Model>.fromJson(
      jsonResponse,
      (data) => Model.fromJson(data as Map<String, dynamic>),
    );
  } else {
    // 直接返回对象
    final model = Model.fromJson(jsonResponse);
    return ApiResponse<Model>(
      code: 200,
      message: 'success',
      data: model,
    );
  }
}
```

### 2. 已适配的接口

以下接口已经适配了两种响应格式：

- ✅ `getCollections()` - 获取所有收藏夹
- ✅ `getCollectionsByType()` - 获取指定类型收藏夹
- ✅ `addFavoriteItem()` - 添加收藏项
- ✅ `getFavoriteItems()` - 获取收藏项列表
- ✅ `markAsWatched()` - 标记看过
- ✅ `getWatchedMovies()` - 获取看过列表

## 注意事项

### 1. 空值处理

后端返回的数据中，某些字段可能为 `null`：

```json
{
  "rating": null,
  "note": null,
  "coverImage": null
}
```

前端模型需要将这些字段定义为可空类型：

```dart
class Model {
  final double? rating;
  final String? note;
  final String? coverImage;
}
```

### 2. 嵌套对象处理

对于嵌套的对象（如 `itemDetail`、`movieInfo`），使用 `Map<String, dynamic>` 存储，避免强制类型转换：

```dart
class FavoriteItem {
  final Map<String, dynamic>? itemDetail;
  
  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      itemDetail: json['itemDetail'] != null 
          ? Map<String, dynamic>.from(json['itemDetail'] as Map)
          : null,
    );
  }
}
```

### 3. 空响应体处理

某些删除接口返回空响应体，需要特殊处理：

```dart
if (response.statusCode == 200) {
  if (response.body.isEmpty) {
    return ApiResponse<void>(
      code: 200,
      message: '删除成功',
      data: null,
    );
  }
  // 尝试解析JSON...
}
```

## 建议

### 给后端团队的建议

为了统一API规范，建议后端：

1. **统一使用标准 ApiResponse 格式**
   ```json
   {
     "code": 200,
     "message": "success",
     "data": { /* 或 [] */ }
   }
   ```

2. **DELETE 操作返回标准格式**
   ```json
   {
     "code": 200,
     "message": "删除成功",
     "data": null
   }
   ```

3. **保持响应格式一致性**
   - 同类型的接口使用相同的响应格式
   - 避免混用直接返回对象和标准格式

### 前端开发规范

1. **新接口开发时先测试响应格式**
   - 使用 Postman 或类似工具测试接口
   - 查看实际返回的 JSON 格式
   - 根据实际格式编写解析代码

2. **添加详细的日志**
   ```dart
   debugPrint('响应状态码: ${response.statusCode}');
   debugPrint('响应内容: ${response.body}');
   ```

3. **使用 try-catch 捕获解析错误**
   ```dart
   try {
     final jsonResponse = jsonDecode(response.body);
     // 解析逻辑...
   } catch (e) {
     debugPrint('解析失败: $e');
     return ApiResponse<T>(
       code: -1,
       message: '数据解析失败: $e',
       data: null,
     );
   }
   ```

## 更新日志

### 2026-03-05
- ✅ 记录收藏夹管理接口的实际响应格式
- ✅ 记录收藏项管理接口的实际响应格式
- ✅ 记录看过记录接口的实际响应格式
- ✅ 修复 `addFavoriteItem()` 方法的响应解析
- ✅ 修复 `markAsWatched()` 方法的响应解析
- ✅ 添加前端处理策略和注意事项
- ✅ 提供给后端团队的建议

### 2026-03-04
- ✅ 修复 `getCollections()` 方法的响应解析
- ✅ 修复 `getCollectionsByType()` 方法的响应解析
- ✅ 修复 `getWatchedMovies()` 方法的响应解析
- ✅ 修复 `getFavoriteItems()` 方法的响应解析

