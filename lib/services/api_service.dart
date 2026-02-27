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
}

