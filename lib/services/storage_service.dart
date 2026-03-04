import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/user.dart';

/// 本地存储服务
class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_info';

  // 获取存储文件路径
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _getFile(String key) async {
    final path = await _localPath;
    return File('$path/$key.json');
  }

  /// 保存Token
  static Future<void> saveToken(String token) async {
    try {
      final file = await _getFile(_tokenKey);
      await file.writeAsString(token);
      debugPrint('Token已保存');
    } catch (e) {
      debugPrint('保存Token失败: $e');
    }
  }

  /// 获取Token
  static Future<String?> getToken() async {
    try {
      final file = await _getFile(_tokenKey);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      debugPrint('读取Token失败: $e');
      return null;
    }
  }

  /// 保存用户信息
  static Future<void> saveUser(User user) async {
    try {
      final file = await _getFile(_userKey);
      final jsonString = jsonEncode(user.toJson());
      await file.writeAsString(jsonString);
      debugPrint('用户信息已保存');
    } catch (e) {
      debugPrint('保存用户信息失败: $e');
    }
  }

  /// 获取用户信息
  static Future<User?> getUser() async {
    try {
      final file = await _getFile(_userKey);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return User.fromJson(json);
      }
      return null;
    } catch (e) {
      debugPrint('读取用户信息失败: $e');
      return null;
    }
  }

  /// 清除所有数据（退出登录）
  static Future<void> clearAll() async {
    try {
      final tokenFile = await _getFile(_tokenKey);
      final userFile = await _getFile(_userKey);
      
      if (await tokenFile.exists()) {
        await tokenFile.delete();
      }
      if (await userFile.exists()) {
        await userFile.delete();
      }
      
      debugPrint('已清除所有本地数据');
    } catch (e) {
      debugPrint('清除数据失败: $e');
    }
  }

  /// 检查是否已登录
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}





