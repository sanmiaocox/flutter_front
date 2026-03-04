import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import '../models/login_response.dart';
import '../models/collection.dart';
import '../models/favorite_item.dart';
import '../models/watched_movie.dart';
import '../models/user_stats.dart';
import '../models/tmdb_search_response.dart';
import '../models/event.dart';
import '../models/event_participant.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

/// API服务类
class ApiService {
  // 基础URL
  static String get baseUrl => ApiConfig.baseUrl;
  
  // API端点
  static String get _registerEndpoint => ApiConfig.registerEndpoint;
  static String get _loginEndpoint => ApiConfig.loginEndpoint;

  /// 用户注册
  /// 
  /// [username] 用户名（2-50个字符）
  /// [phone] 手机号（11位）
  /// [password] 密码（6-20个字符）
  static Future<ApiResponse<User>> register({
    required String username,
    required String phone,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$_registerEndpoint');
      
      debugPrint('注册请求: $url');
      debugPrint('请求体: username=$username, phone=$phone');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'phone': phone,
          'password': password,
        }),
      );

      debugPrint('注册响应状态码: ${response.statusCode}');
      debugPrint('注册响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<User>.fromJson(
        jsonResponse,
        (data) => User.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('注册请求失败: $e');
      return ApiResponse<User>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 用户登录
  /// 
  /// [phone] 手机号
  /// [password] 密码
  /// [timeout] 请求超时时间,默认10秒
  static Future<ApiResponse<LoginResponse>> login({
    required String phone,
    required String password,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final url = Uri.parse('$baseUrl$_loginEndpoint');
      
      debugPrint('登录请求: $url');
      debugPrint('请求体: phone=$phone');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      ).timeout(
        timeout,
        onTimeout: () {
          throw Exception('请求超时,请检查网络连接');
        },
      );

      debugPrint('登录响应状态码: ${response.statusCode}');
      debugPrint('登录响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      final apiResponse = ApiResponse<LoginResponse>.fromJson(
        jsonResponse,
        (data) => LoginResponse.fromJson(data as Map<String, dynamic>),
      );

      // 如果登录成功，保存Token和用户信息
      if (apiResponse.isSuccess && apiResponse.data != null) {
        await StorageService.saveToken(apiResponse.data!.token);
        await StorageService.saveUser(apiResponse.data!.user);
        debugPrint('Token和用户信息已保存');
      }

      return apiResponse;
    } catch (e) {
      debugPrint('登录请求失败: $e');
      return ApiResponse<LoginResponse>(
        code: -1,
        message: e.toString().contains('请求超时') ? '请求超时,请检查网络连接' : '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取带Token的请求头
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 退出登录
  static Future<void> logout() async {
    await StorageService.clearAll();
    debugPrint('已退出登录');
  }

  /// 获取当前用户信息
  static Future<ApiResponse<User>> getCurrentUserProfile() async {
    try {
      final url = Uri.parse('$baseUrl/api/users/profile');
      final headers = await getAuthHeaders();
      
      debugPrint('获取用户信息请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取用户信息响应状态码: ${response.statusCode}');
      debugPrint('获取用户信息响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      // 打印data中的bio字段
      if (jsonResponse['data'] != null) {
        final data = jsonResponse['data'] as Map<String, dynamic>;
        debugPrint('API返回的bio字段: ${data['bio']}');
      }
      
      final apiResponse = ApiResponse<User>.fromJson(
        jsonResponse,
        (data) => User.fromJson(data as Map<String, dynamic>),
      );

      // 如果获取成功，更新本地存储的用户信息
      if (apiResponse.isSuccess && apiResponse.data != null) {
        debugPrint('解析后的User对象bio: ${apiResponse.data!.bio}');
        await StorageService.saveUser(apiResponse.data!);
        debugPrint('用户信息已更新到本地存储');
      }

      return apiResponse;
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
      return ApiResponse<User>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 更新个人资料
  /// 
  /// [username] 用户名（可选）
  /// [avatar] 头像URL（可选）
  /// [bio] 个人简介（可选）
  static Future<ApiResponse<User>> updateProfile({
    String? username,
    String? avatar,
    String? bio,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/profile');
      final headers = await getAuthHeaders();
      
      final body = <String, dynamic>{};
      if (username != null) body['username'] = username;
      if (avatar != null) body['avatar'] = avatar;
      if (bio != null) body['bio'] = bio;

      debugPrint('更新个人资料请求: $url');
      debugPrint('请求体: $body');
      debugPrint('更新的bio值: $bio');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('更新个人资料响应状态码: ${response.statusCode}');
      debugPrint('更新个人资料响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      // 打印返回的bio字段
      if (jsonResponse['data'] != null) {
        final data = jsonResponse['data'] as Map<String, dynamic>;
        debugPrint('更新后API返回的bio字段: ${data['bio']}');
      }
      
      final apiResponse = ApiResponse<User>.fromJson(
        jsonResponse,
        (data) => User.fromJson(data as Map<String, dynamic>),
      );

      // 如果更新成功，保存到本地存储
      if (apiResponse.isSuccess && apiResponse.data != null) {
        debugPrint('更新后解析的User对象bio: ${apiResponse.data!.bio}');
        await StorageService.saveUser(apiResponse.data!);
        debugPrint('更新后的用户信息已保存');
      }

      return apiResponse;
    } catch (e) {
      debugPrint('更新个人资料失败: $e');
      return ApiResponse<User>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取指定用户信息
  static Future<ApiResponse<User>> getUserProfile(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/$userId');
      final headers = await getAuthHeaders();
      
      debugPrint('获取用户信息请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取用户信息响应状态码: ${response.statusCode}');
      debugPrint('获取用户信息响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<User>.fromJson(
        jsonResponse,
        (data) => User.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('获取用户信息失败: $e');
      return ApiResponse<User>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 关注用户
  static Future<ApiResponse<void>> followUser(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/$userId/follow');
      final headers = await getAuthHeaders();
      
      debugPrint('关注用户请求: $url');

      final response = await http.post(url, headers: headers);

      debugPrint('关注用户响应状态码: ${response.statusCode}');
      debugPrint('关注用户响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<void>.fromJson(jsonResponse, (data) => null);
    } catch (e) {
      debugPrint('关注用户失败: $e');
      return ApiResponse<void>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 取消关注用户
  static Future<ApiResponse<void>> unfollowUser(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/$userId/follow');
      final headers = await getAuthHeaders();
      
      debugPrint('取消关注用户请求: $url');

      final response = await http.delete(url, headers: headers);

      debugPrint('取消关注用户响应状态码: ${response.statusCode}');
      debugPrint('取消关注用户响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<void>.fromJson(jsonResponse, (data) => null);
    } catch (e) {
      debugPrint('取消关注用户失败: $e');
      return ApiResponse<void>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取关注列表（我关注的人）
  static Future<ApiResponse<Map<String, dynamic>>> getFollowingList(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/$userId/following?page=$page&size=$size');
      final headers = await getAuthHeaders();
      
      debugPrint('获取关注列表请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取关注列表响应状态码: ${response.statusCode}');
      debugPrint('获取关注列表响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('获取关注列表失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取粉丝列表（关注我的人）
  static Future<ApiResponse<Map<String, dynamic>>> getFollowersList(
    int userId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/$userId/followers?page=$page&size=$size');
      final headers = await getAuthHeaders();
      
      debugPrint('获取粉丝列表请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取粉丝列表响应状态码: ${response.statusCode}');
      debugPrint('获取粉丝列表响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('获取粉丝列表失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取好友列表（互相关注）
  static Future<ApiResponse<List<User>>> getFriendsList(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/$userId/friends');
      final headers = await getAuthHeaders();
      
      debugPrint('获取好友列表请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取好友列表响应状态码: ${response.statusCode}');
      debugPrint('获取好友列表响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<List<User>>.fromJson(
        jsonResponse,
        (data) {
          final list = data as List<dynamic>;
          return list.map((item) => User.fromJson(item as Map<String, dynamic>)).toList();
        },
      );
    } catch (e) {
      debugPrint('获取好友列表失败: $e');
      return ApiResponse<List<User>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取关注状态
  static Future<ApiResponse<Map<String, dynamic>>> getFollowStatus(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/$userId/follow/status');
      final headers = await getAuthHeaders();
      
      debugPrint('获取关注状态请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取关注状态响应状态码: ${response.statusCode}');
      debugPrint('获取关注状态响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('获取关注状态失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取用户统计信息
  static Future<ApiResponse<UserStats>> getUserStats(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/$userId/stats');
      final headers = await getAuthHeaders();
      
      debugPrint('获取用户统计信息请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取用户统计信息响应状态码: ${response.statusCode}');
      debugPrint('获取用户统计信息响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<UserStats>.fromJson(
        jsonResponse,
        (data) => UserStats.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('获取用户统计信息失败: $e');
      return ApiResponse<UserStats>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  // ==================== 收藏夹管理接口 ====================

  /// 上传图片
  /// 
  /// [imageFile] 图片文件
  static Future<ApiResponse<String>> uploadImage(File imageFile) async {
    try {
      final url = Uri.parse('$baseUrl/api/upload/image');
      
      debugPrint('上传图片请求: $url');
      debugPrint('图片文件路径: ${imageFile.path}');

      var request = http.MultipartRequest('POST', url);
      
      // 注意：根据后端API文档，图片上传接口不需要Token认证（公开接口）
      // 但如果需要认证，可以取消下面的注释
      // final token = await StorageService.getToken();
      // if (token != null) {
      //   request.headers['Authorization'] = 'Bearer $token';
      // }
      
      // 获取文件扩展名并确定MIME类型
      String? mimeType;
      final extension = imageFile.path.toLowerCase().split('.').last;
      
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // 默认使用jpeg
      }
      
      debugPrint('文件扩展名: $extension, MIME类型: $mimeType');
      
      // 添加文件，并指定contentType
      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: http_parser.MediaType.parse(mimeType),
      );
      
      request.files.add(multipartFile);
      
      debugPrint('准备发送请求，文件大小: ${multipartFile.length} bytes');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('上传图片响应状态码: ${response.statusCode}');
      debugPrint('上传图片响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // 根据后端实际响应格式：
        // {
        //   "code": 200,
        //   "message": "success",
        //   "data": {
        //     "filename": "abc123.jpg"
        //   }
        // }
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('data') && jsonResponse['data'] is Map<String, dynamic>) {
            final data = jsonResponse['data'] as Map<String, dynamic>;
            
            // 优先使用 filename（后端只返回文件名）
            if (data.containsKey('filename')) {
              final filename = data['filename'] as String;
              debugPrint('图片上传成功，文件名: $filename');
              
              return ApiResponse<String>(
                code: jsonResponse['code'] as int? ?? 200,
                message: jsonResponse['message'] as String? ?? 'success',
                data: filename,  // 返回文件名，前端会通过 ApiConfig.getImageUrl() 拼接完整URL
              );
            }
            // 兼容返回完整URL的格式
            else if (data.containsKey('url')) {
              final imageUrl = data['url'] as String;
              debugPrint('图片上传成功，URL: $imageUrl');
              
              return ApiResponse<String>(
                code: jsonResponse['code'] as int? ?? 200,
                message: jsonResponse['message'] as String? ?? 'success',
                data: imageUrl,
              );
            }
          } else if (jsonResponse.containsKey('url')) {
            // 兼容直接返回URL的格式
            final imageUrl = jsonResponse['url'] as String;
            debugPrint('图片上传成功，URL: $imageUrl');
            
            return ApiResponse<String>(
              code: 200,
              message: 'success',
              data: imageUrl,
            );
          } else if (jsonResponse.containsKey('filename')) {
            // 兼容直接返回filename的格式
            final filename = jsonResponse['filename'] as String;
            debugPrint('图片上传成功，文件名: $filename');
            
            return ApiResponse<String>(
              code: 200,
              message: 'success',
              data: filename,
            );
          }
        }
        
        throw Exception('未知的响应格式: $jsonResponse');
      } else {
        // 解析错误响应
        try {
          final jsonResponse = jsonDecode(response.body);
          return ApiResponse<String>(
            code: jsonResponse['code'] as int? ?? response.statusCode,
            message: jsonResponse['message'] as String? ?? '上传失败',
            data: null,
          );
        } catch (e) {
          return ApiResponse<String>(
            code: response.statusCode,
            message: '上传失败: ${response.body}',
            data: null,
          );
        }
      }
    } catch (e) {
      debugPrint('上传图片失败: $e');
      return ApiResponse<String>(
        code: -1,
        message: '上传失败: $e',
        data: null,
      );
    }
  }

  /// 创建收藏夹
  /// 
  /// [name] 收藏夹名称
  /// [type] 收藏夹类型 MOVIE/EVENT
  /// [description] 收藏夹描述(可选)
  /// [isPublic] 是否公开(可选,默认true)
  /// [coverImage] 封面图片URL(可选)
  static Future<ApiResponse<Collection>> createCollection({
    required String name,
    required String type,
    String? description,
    bool? isPublic,
    String? coverImage,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/collections');
      final headers = await getAuthHeaders();
      
      final body = <String, dynamic>{
        'name': name,
        'type': type,
      };
      if (description != null) body['description'] = description;
      if (isPublic != null) body['isPublic'] = isPublic;
      if (coverImage != null) body['coverImage'] = coverImage;

      debugPrint('创建收藏夹请求: $url');
      debugPrint('请求体: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('创建收藏夹响应状态码: ${response.statusCode}');
      debugPrint('创建收藏夹响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Collection>.fromJson(
        jsonResponse,
        (data) => Collection.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('创建收藏夹失败: $e');
      return ApiResponse<Collection>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取用户的所有收藏夹
  static Future<ApiResponse<List<Collection>>> getCollections() async {
    try {
      final url = Uri.parse('$baseUrl/api/collections');
      final headers = await getAuthHeaders();
      
      debugPrint('获取收藏夹列表请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取收藏夹列表响应状态码: ${response.statusCode}');
      debugPrint('获取收藏夹列表响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<List<Collection>>.fromJson(
        jsonResponse,
        (data) {
          final list = data as List<dynamic>;
          return list.map((item) => Collection.fromJson(item as Map<String, dynamic>)).toList();
        },
      );
    } catch (e) {
      debugPrint('获取收藏夹列表失败: $e');
      return ApiResponse<List<Collection>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取指定类型的收藏夹
  /// 
  /// [type] 收藏夹类型 MOVIE/EVENT
  static Future<ApiResponse<List<Collection>>> getCollectionsByType(String type) async {
    try {
      final url = Uri.parse('$baseUrl/api/collections/type/$type');
      final headers = await getAuthHeaders();
      
      debugPrint('获取指定类型收藏夹请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取指定类型收藏夹响应状态码: ${response.statusCode}');
      debugPrint('获取指定类型收藏夹响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<List<Collection>>.fromJson(
        jsonResponse,
        (data) {
          final list = data as List<dynamic>;
          return list.map((item) => Collection.fromJson(item as Map<String, dynamic>)).toList();
        },
      );
    } catch (e) {
      debugPrint('获取指定类型收藏夹失败: $e');
      return ApiResponse<List<Collection>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取收藏夹详情
  static Future<ApiResponse<Collection>> getCollectionDetail(int collectionId) async {
    try {
      final url = Uri.parse('$baseUrl/api/collections/$collectionId');
      final headers = await getAuthHeaders();
      
      debugPrint('获取收藏夹详情请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取收藏夹详情响应状态码: ${response.statusCode}');
      debugPrint('获取收藏夹详情响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Collection>.fromJson(
        jsonResponse,
        (data) => Collection.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('获取收藏夹详情失败: $e');
      return ApiResponse<Collection>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 更新收藏夹
  static Future<ApiResponse<Collection>> updateCollection({
    required int collectionId,
    String? name,
    String? description,
    bool? isPublic,
    String? coverImage,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/collections/$collectionId');
      final headers = await getAuthHeaders();
      
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (isPublic != null) body['isPublic'] = isPublic;
      if (coverImage != null) body['coverImage'] = coverImage;

      debugPrint('更新收藏夹请求: $url');
      debugPrint('请求体: $body');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('更新收藏夹响应状态码: ${response.statusCode}');
      debugPrint('更新收藏夹响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Collection>.fromJson(
        jsonResponse,
        (data) => Collection.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('更新收藏夹失败: $e');
      return ApiResponse<Collection>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 删除收藏夹
  static Future<ApiResponse<void>> deleteCollection(int collectionId) async {
    try {
      final url = Uri.parse('$baseUrl/api/collections/$collectionId');
      final headers = await getAuthHeaders();
      
      debugPrint('删除收藏夹请求: $url');

      final response = await http.delete(url, headers: headers);

      debugPrint('删除收藏夹响应状态码: ${response.statusCode}');
      debugPrint('删除收藏夹响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<void>.fromJson(jsonResponse, (data) => null);
    } catch (e) {
      debugPrint('删除收藏夹失败: $e');
      return ApiResponse<void>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  // ==================== 收藏项管理接口 ====================

  /// 添加收藏项
  /// 
  /// [collectionId] 收藏夹ID
  /// [itemType] 收藏项类型 MOVIE/EVENT
  /// [tmdbId] TMDB电影ID（MOVIE类型时使用）
  /// [itemId] 活动ID（EVENT类型时使用）
  /// [note] 用户备注(可选)
  static Future<ApiResponse<FavoriteItem>> addFavoriteItem({
    required int collectionId,
    required String itemType,
    int? tmdbId,
    int? itemId,
    String? note,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/favorites');
      final headers = await getAuthHeaders();
      
      final body = <String, dynamic>{
        'collectionId': collectionId,
        'itemType': itemType,
      };
      
      // 根据类型使用不同的ID字段
      if (itemType == 'MOVIE' && tmdbId != null) {
        body['tmdbId'] = tmdbId;
      } else if (itemType == 'EVENT' && itemId != null) {
        body['itemId'] = itemId;
      }
      
      if (note != null) body['note'] = note;

      debugPrint('添加收藏项请求: $url');
      debugPrint('请求体: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('添加收藏项响应状态码: ${response.statusCode}');
      debugPrint('添加收藏项响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<FavoriteItem>.fromJson(
        jsonResponse,
        (data) => FavoriteItem.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('添加收藏项失败: $e');
      return ApiResponse<FavoriteItem>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取收藏夹中的所有收藏项
  static Future<ApiResponse<List<FavoriteItem>>> getFavoriteItems(int collectionId) async {
    try {
      final url = Uri.parse('$baseUrl/api/favorites/collection/$collectionId');
      final headers = await getAuthHeaders();
      
      debugPrint('获取收藏项列表请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取收藏项列表响应状态码: ${response.statusCode}');
      debugPrint('获取收藏项列表响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<List<FavoriteItem>>.fromJson(
        jsonResponse,
        (data) {
          final list = data as List<dynamic>;
          return list.map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>)).toList();
        },
      );
    } catch (e) {
      debugPrint('获取收藏项列表失败: $e');
      return ApiResponse<List<FavoriteItem>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取收藏夹中指定类型的收藏项
  static Future<ApiResponse<List<FavoriteItem>>> getFavoriteItemsByType({
    required int collectionId,
    required String itemType,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/favorites/collection/$collectionId/type/$itemType');
      final headers = await getAuthHeaders();
      
      debugPrint('获取指定类型收藏项请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取指定类型收藏项响应状态码: ${response.statusCode}');
      debugPrint('获取指定类型收藏项响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<List<FavoriteItem>>.fromJson(
        jsonResponse,
        (data) {
          final list = data as List<dynamic>;
          return list.map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>)).toList();
        },
      );
    } catch (e) {
      debugPrint('获取指定类型收藏项失败: $e');
      return ApiResponse<List<FavoriteItem>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 移除收藏项
  static Future<ApiResponse<void>> removeFavoriteItem({
    required int collectionId,
    required String itemType,
    required int itemId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/favorites/collection/$collectionId/item/$itemType/$itemId');
      final headers = await getAuthHeaders();
      
      debugPrint('移除收藏项请求: $url');

      final response = await http.delete(url, headers: headers);

      debugPrint('移除收藏项响应状态码: ${response.statusCode}');
      debugPrint('移除收藏项响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<void>.fromJson(jsonResponse, (data) => null);
    } catch (e) {
      debugPrint('移除收藏项失败: $e');
      return ApiResponse<void>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 检查用户是否收藏了某个项目
  static Future<ApiResponse<Map<String, dynamic>>> checkFavoriteStatus({
    required String itemType,
    required int itemId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/favorites/check/$itemType/$itemId');
      final headers = await getAuthHeaders();
      
      debugPrint('检查收藏状态请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('检查收藏状态响应状态码: ${response.statusCode}');
      debugPrint('检查收藏状态响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('检查收藏状态失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  // ==================== 看过记录接口 ====================

  /// 标记电影为看过
  /// 
  /// [tmdbId] TMDB电影ID
  /// [rating] 用户评分(可选,0.0-10.0)
  /// [note] 观影笔记(可选)
  static Future<ApiResponse<WatchedMovie>> markAsWatched({
    required int tmdbId,
    double? rating,
    String? note,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/watched');
      final headers = await getAuthHeaders();
      
      final body = <String, dynamic>{
        'tmdbId': tmdbId,
      };
      if (rating != null) body['rating'] = rating;
      if (note != null) body['note'] = note;

      debugPrint('标记看过请求: $url');
      debugPrint('请求体: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('标记看过响应状态码: ${response.statusCode}');
      debugPrint('标记看过响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<WatchedMovie>.fromJson(
        jsonResponse,
        (data) => WatchedMovie.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('标记看过失败: $e');
      return ApiResponse<WatchedMovie>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 取消看过标记
  static Future<ApiResponse<void>> unmarkAsWatched(int movieId) async {
    try {
      final url = Uri.parse('$baseUrl/api/watched/$movieId');
      final headers = await getAuthHeaders();
      
      debugPrint('取消看过标记请求: $url');

      final response = await http.delete(url, headers: headers);

      debugPrint('取消看过标记响应状态码: ${response.statusCode}');
      debugPrint('取消看过标记响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<void>.fromJson(jsonResponse, (data) => null);
    } catch (e) {
      debugPrint('取消看过标记失败: $e');
      return ApiResponse<void>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 更新看过记录
  static Future<ApiResponse<WatchedMovie>> updateWatchedMovie({
    required int movieId,
    double? rating,
    String? note,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/watched/$movieId');
      final headers = await getAuthHeaders();
      
      final body = <String, dynamic>{};
      if (rating != null) body['rating'] = rating;
      if (note != null) body['note'] = note;

      debugPrint('更新看过记录请求: $url');
      debugPrint('请求体: $body');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('更新看过记录响应状态码: ${response.statusCode}');
      debugPrint('更新看过记录响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<WatchedMovie>.fromJson(
        jsonResponse,
        (data) => WatchedMovie.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('更新看过记录失败: $e');
      return ApiResponse<WatchedMovie>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取用户看过的所有电影
  static Future<ApiResponse<List<WatchedMovie>>> getWatchedMovies() async {
    try {
      final url = Uri.parse('$baseUrl/api/watched');
      final headers = await getAuthHeaders();
      
      debugPrint('获取看过列表请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取看过列表响应状态码: ${response.statusCode}');
      debugPrint('获取看过列表响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<List<WatchedMovie>>.fromJson(
        jsonResponse,
        (data) {
          final list = data as List<dynamic>;
          return list.map((item) => WatchedMovie.fromJson(item as Map<String, dynamic>)).toList();
        },
      );
    } catch (e) {
      debugPrint('获取看过列表失败: $e');
      return ApiResponse<List<WatchedMovie>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 检查用户是否看过某部电影
  static Future<ApiResponse<Map<String, dynamic>>> checkWatchedStatus(int movieId) async {
    try {
      final url = Uri.parse('$baseUrl/api/watched/check/$movieId');
      final headers = await getAuthHeaders();
      
      debugPrint('检查看过状态请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('检查看过状态响应状态码: ${response.statusCode}');
      debugPrint('检查看过状态响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('检查看过状态失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取用户看过的电影数量
  static Future<ApiResponse<int>> getWatchedMoviesCount() async {
    try {
      final url = Uri.parse('$baseUrl/api/watched/count');
      final headers = await getAuthHeaders();
      
      debugPrint('获取看过数量请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取看过数量响应状态码: ${response.statusCode}');
      debugPrint('获取看过数量响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<int>.fromJson(
        jsonResponse,
        (data) {
          if (data is Map<String, dynamic> && data.containsKey('count')) {
            return data['count'] as int;
          }
          return 0;
        },
      );
    } catch (e) {
      debugPrint('获取看过数量失败: $e');
      return ApiResponse<int>(
        code: -1,
        message: '网络请求失败: $e',
        data: 0,
      );
    }
  }

  // ==================== TMDB电影数据接口 ====================

  /// 搜索电影
  /// 
  /// [keyword] 搜索关键词
  /// [page] 页码（默认1）
  static Future<ApiResponse<TmdbSearchResponse>> searchMovies({
    required String keyword,
    int page = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/tmdb/search?keyword=${Uri.encodeComponent(keyword)}&page=$page');
      final headers = await getAuthHeaders();
      
      debugPrint('搜索电影请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('搜索电影响应状态码: ${response.statusCode}');
      debugPrint('搜索电影响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<TmdbSearchResponse>.fromJson(
        jsonResponse,
        (data) => TmdbSearchResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('搜索电影失败: $e');
      return ApiResponse<TmdbSearchResponse>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取热门电影
  /// 
  /// [page] 页码（默认1）
  static Future<ApiResponse<TmdbSearchResponse>> getPopularMovies({
    int page = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/tmdb/popular?page=$page');
      final headers = await getAuthHeaders();
      
      debugPrint('获取热门电影请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取热门电影响应状态码: ${response.statusCode}');
      debugPrint('获取热门电影响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<TmdbSearchResponse>.fromJson(
        jsonResponse,
        (data) => TmdbSearchResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('获取热门电影失败: $e');
      return ApiResponse<TmdbSearchResponse>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取正在上映的电影
  /// 
  /// [page] 页码（默认1）
  static Future<ApiResponse<TmdbSearchResponse>> getNowPlayingMovies({
    int page = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/tmdb/now-playing?page=$page');
      final headers = await getAuthHeaders();
      
      debugPrint('获取正在上映电影请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取正在上映电影响应状态码: ${response.statusCode}');
      debugPrint('获取正在上映电影响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<TmdbSearchResponse>.fromJson(
        jsonResponse,
        (data) => TmdbSearchResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('获取正在上映电影失败: $e');
      return ApiResponse<TmdbSearchResponse>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取即将上映的电影
  /// 
  /// [page] 页码（默认1）
  static Future<ApiResponse<TmdbSearchResponse>> getUpcomingMovies({
    int page = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/tmdb/upcoming?page=$page');
      final headers = await getAuthHeaders();
      
      debugPrint('获取即将上映电影请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取即将上映电影响应状态码: ${response.statusCode}');
      debugPrint('获取即将上映电影响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<TmdbSearchResponse>.fromJson(
        jsonResponse,
        (data) => TmdbSearchResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('获取即将上映电影失败: $e');
      return ApiResponse<TmdbSearchResponse>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取高分电影
  /// 
  /// [page] 页码（默认1）
  static Future<ApiResponse<TmdbSearchResponse>> getTopRatedMovies({
    int page = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/tmdb/top-rated?page=$page');
      final headers = await getAuthHeaders();
      
      debugPrint('获取高分电影请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取高分电影响应状态码: ${response.statusCode}');
      debugPrint('获取高分电影响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<TmdbSearchResponse>.fromJson(
        jsonResponse,
        (data) => TmdbSearchResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('获取高分电影失败: $e');
      return ApiResponse<TmdbSearchResponse>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取电影详情
  /// 
  /// [tmdbId] TMDB电影ID
  static Future<ApiResponse<Map<String, dynamic>>> getMovieDetail(int tmdbId) async {
    try {
      final url = Uri.parse('$baseUrl/api/tmdb/movie/$tmdbId');
      final headers = await getAuthHeaders();
      
      debugPrint('获取电影详情请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取电影详情响应状态码: ${response.statusCode}');
      debugPrint('获取电影详情响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('获取电影详情失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取电影演职人员
  /// 
  /// [tmdbId] TMDB电影ID
  static Future<ApiResponse<Map<String, dynamic>>> getMovieCredits(int tmdbId) async {
    try {
      final url = Uri.parse('$baseUrl/api/tmdb/movie/$tmdbId/credits');
      final headers = await getAuthHeaders();
      
      debugPrint('获取电影演职人员请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取电影演职人员响应状态码: ${response.statusCode}');
      debugPrint('获取电影演职人员响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('获取电影演职人员失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取电影图片
  /// 
  /// [tmdbId] TMDB电影ID
  static Future<ApiResponse<Map<String, dynamic>>> getMovieImages(int tmdbId) async {
    try {
      final url = Uri.parse('$baseUrl/api/tmdb/movie/$tmdbId/images');
      final headers = await getAuthHeaders();
      
      debugPrint('获取电影图片请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取电影图片响应状态码: ${response.statusCode}');
      debugPrint('获取电影图片响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('获取电影图片失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取推荐电影（根据指定电影推荐相似电影）
  /// 
  /// [tmdbId] TMDB电影ID
  /// [page] 页码（默认1）
  static Future<ApiResponse<TmdbSearchResponse>> getMovieRecommendations({
    required int tmdbId,
    int page = 1,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/tmdb/movie/$tmdbId/recommendations?page=$page');
      final headers = await getAuthHeaders();
      
      debugPrint('获取推荐电影请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取推荐电影响应状态码: ${response.statusCode}');
      debugPrint('获取推荐电影响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<TmdbSearchResponse>.fromJson(
        jsonResponse,
        (data) => TmdbSearchResponse.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('获取推荐电影失败: $e');
      return ApiResponse<TmdbSearchResponse>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  // ==================== 活动管理接口 ====================

  /// 创建活动
  /// 
  /// [title] 活动标题
  /// [imageUrl] 活动封面图片文件名
  /// [eventDate] 活动时间
  /// [location] 活动地点
  /// [maxParticipants] 最大参与人数
  /// [type] 活动类型
  /// [description] 活动描述
  /// [movieId] 关联的电影ID
  static Future<ApiResponse<Event>> createEvent({
    required String title,
    String? imageUrl,
    required DateTime eventDate,
    required String location,
    required int maxParticipants,
    required String type,
    String? description,
    required int movieId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/events');
      final headers = await getAuthHeaders();
      
      final body = <String, dynamic>{
        'title': title,
        'eventDate': eventDate.toIso8601String(),
        'location': location,
        'maxParticipants': maxParticipants,
        'type': type,
        'movieId': movieId,
      };
      if (imageUrl != null) body['imageUrl'] = imageUrl;
      if (description != null) body['description'] = description;

      debugPrint('创建活动请求: $url');
      debugPrint('请求体: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('创建活动响应状态码: ${response.statusCode}');
      debugPrint('创建活动响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Event>.fromJson(
        jsonResponse,
        (data) => Event.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('创建活动失败: $e');
      return ApiResponse<Event>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取活动列表（支持分页、筛选和搜索）
  /// 
  /// [page] 页码（默认0）
  /// [size] 每页数量（默认20）
  /// [type] 按类型筛选
  /// [movieId] 按电影ID筛选
  /// [keyword] 搜索关键词
  static Future<ApiResponse<Map<String, dynamic>>> getEvents({
    int page = 0,
    int size = 20,
    String? type,
    int? movieId,
    String? keyword,
  }) async {
    try {
      var url = '$baseUrl/api/events?page=$page&size=$size';
      if (type != null) url += '&type=${Uri.encodeComponent(type)}';
      if (movieId != null) url += '&movieId=$movieId';
      if (keyword != null) url += '&keyword=${Uri.encodeComponent(keyword)}';
      
      final uri = Uri.parse(url);
      final headers = await getAuthHeaders();
      
      debugPrint('获取活动列表请求: $uri');

      final response = await http.get(uri, headers: headers);

      debugPrint('获取活动列表响应状态码: ${response.statusCode}');
      debugPrint('获取活动列表响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('获取活动列表失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取活动详情
  /// 
  /// [eventId] 活动ID
  static Future<ApiResponse<Event>> getEventDetail(int eventId) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId');
      final headers = await getAuthHeaders();
      
      debugPrint('获取活动详情请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取活动详情响应状态码: ${response.statusCode}');
      debugPrint('获取活动详情响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Event>.fromJson(
        jsonResponse,
        (data) => Event.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('获取活动详情失败: $e');
      return ApiResponse<Event>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 更新活动（只能更新自己创建的活动）
  /// 
  /// [eventId] 活动ID
  /// [title] 活动标题
  /// [imageUrl] 活动封面图片文件名
  /// [eventDate] 活动时间
  /// [location] 活动地点
  /// [maxParticipants] 最大参与人数
  /// [type] 活动类型
  /// [description] 活动描述
  /// [movieId] 关联的电影ID
  static Future<ApiResponse<Event>> updateEvent({
    required int eventId,
    String? title,
    String? imageUrl,
    DateTime? eventDate,
    String? location,
    int? maxParticipants,
    String? type,
    String? description,
    int? movieId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId');
      final headers = await getAuthHeaders();
      
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (imageUrl != null) body['imageUrl'] = imageUrl;
      if (eventDate != null) body['eventDate'] = eventDate.toIso8601String();
      if (location != null) body['location'] = location;
      if (maxParticipants != null) body['maxParticipants'] = maxParticipants;
      if (type != null) body['type'] = type;
      if (description != null) body['description'] = description;
      if (movieId != null) body['movieId'] = movieId;

      debugPrint('更新活动请求: $url');
      debugPrint('请求体: $body');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('更新活动响应状态码: ${response.statusCode}');
      debugPrint('更新活动响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Event>.fromJson(
        jsonResponse,
        (data) => Event.fromJson(data as Map<String, dynamic>),
      );
    } catch (e) {
      debugPrint('更新活动失败: $e');
      return ApiResponse<Event>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 删除活动（只能删除自己创建的活动）
  /// 
  /// [eventId] 活动ID
  static Future<ApiResponse<void>> deleteEvent(int eventId) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId');
      final headers = await getAuthHeaders();
      
      debugPrint('删除活动请求: $url');

      final response = await http.delete(url, headers: headers);

      debugPrint('删除活动响应状态码: ${response.statusCode}');
      debugPrint('删除活动响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<void>.fromJson(jsonResponse, (data) => null);
    } catch (e) {
      debugPrint('删除活动失败: $e');
      return ApiResponse<void>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 参加活动
  /// 
  /// [eventId] 活动ID
  static Future<ApiResponse<Map<String, dynamic>>> joinEvent(int eventId) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId/join');
      final headers = await getAuthHeaders();
      
      debugPrint('参加活动请求: $url');

      final response = await http.post(url, headers: headers);

      debugPrint('参加活动响应状态码: ${response.statusCode}');
      debugPrint('参加活动响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('参加活动失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 取消参加活动
  /// 
  /// [eventId] 活动ID
  static Future<ApiResponse<Map<String, dynamic>>> cancelJoinEvent(int eventId) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId/join');
      final headers = await getAuthHeaders();
      
      debugPrint('取消参加活动请求: $url');

      final response = await http.delete(url, headers: headers);

      debugPrint('取消参加活动响应状态码: ${response.statusCode}');
      debugPrint('取消参加活动响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('取消参加活动失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取活动参与者列表
  /// 
  /// [eventId] 活动ID
  static Future<ApiResponse<List<EventParticipant>>> getEventParticipants(int eventId) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId/participants');
      final headers = await getAuthHeaders();
      
      debugPrint('获取活动参与者列表请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取活动参与者列表响应状态码: ${response.statusCode}');
      debugPrint('获取活动参与者列表响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<List<EventParticipant>>.fromJson(
        jsonResponse,
        (data) {
          final list = data as List<dynamic>;
          return list.map((item) => EventParticipant.fromJson(item as Map<String, dynamic>)).toList();
        },
      );
    } catch (e) {
      debugPrint('获取活动参与者列表失败: $e');
      return ApiResponse<List<EventParticipant>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 检查当前用户是否已参加活动
  /// 
  /// [eventId] 活动ID
  static Future<ApiResponse<Map<String, dynamic>>> checkEventJoinStatus(int eventId) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/$eventId/joined');
      final headers = await getAuthHeaders();
      
      debugPrint('检查活动参加状态请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('检查活动参加状态响应状态码: ${response.statusCode}');
      debugPrint('检查活动参加状态响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('检查活动参加状态失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }

  /// 获取用户参加的活动列表
  /// 
  /// [userId] 用户ID
  /// [page] 页码（默认0）
  /// [size] 每页数量（默认20）
  static Future<ApiResponse<Map<String, dynamic>>> getUserJoinedEvents({
    required int userId,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/events/user/$userId/joined?page=$page&size=$size');
      final headers = await getAuthHeaders();
      
      debugPrint('获取用户参加的活动列表请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取用户参加的活动列表响应状态码: ${response.statusCode}');
      debugPrint('获取用户参加的活动列表响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('获取用户参加的活动列表失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }
}

