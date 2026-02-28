import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import '../models/login_response.dart';
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
  static Future<ApiResponse<LoginResponse>> login({
    required String phone,
    required String password,
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
        message: '网络请求失败: $e',
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
  static Future<ApiResponse<Map<String, dynamic>>> getUserStats(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/api/users/$userId/stats');
      final headers = await getAuthHeaders();
      
      debugPrint('获取用户统计信息请求: $url');

      final response = await http.get(url, headers: headers);

      debugPrint('获取用户统计信息响应状态码: ${response.statusCode}');
      debugPrint('获取用户统计信息响应内容: ${response.body}');

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      
      return ApiResponse<Map<String, dynamic>>.fromJson(
        jsonResponse,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('获取用户统计信息失败: $e');
      return ApiResponse<Map<String, dynamic>>(
        code: -1,
        message: '网络请求失败: $e',
        data: null,
      );
    }
  }
}

