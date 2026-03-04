import 'dart:io';

/// API配置类
class ApiConfig {
  // 开发环境配置
  // Android模拟器使用 10.0.2.2 代替 localhost
  // iOS模拟器和真机可以使用 localhost 或电脑的局域网IP
  static String get devBaseUrl {
    if (Platform.isAndroid) {
      // Android模拟器专用地址
      return 'http://10.0.2.2:7070';
    } else if (Platform.isIOS) {
      // iOS模拟器可以使用localhost
      return 'http://localhost:7070';
    } else {
      // 其他平台（Web、Desktop等）
      return 'http://localhost:7070';
    }
  }
  
  // 生产环境配置（部署时使用）
  static const String prodBaseUrl = 'https://your-production-api.com';
  
  // 当前使用的环境
  static const bool isProduction = false;
  
  // 获取当前环境的BaseUrl
  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;
  
  // 上传文件的URL前缀（用于拼接完整的图片URL）
  static String get uploadBaseUrl => baseUrl;
  
  // 根据文件名构建完整的图片URL
  static String getImageUrl(String filename) {
    if (filename.isEmpty) return '';
    
    // 如果已经是完整URL，直接返回
    if (filename.startsWith('http://') || filename.startsWith('https://')) {
      // 如果是localhost，需要替换为正确的地址
      if (filename.contains('localhost')) {
        return filename.replaceAll('http://localhost:7070', uploadBaseUrl);
      }
      return filename;
    }
    
    // 否则拼接完整URL
    return '$uploadBaseUrl/uploads/$filename';
  }
  
  // API端点
  static const String registerEndpoint = '/api/auth/register';
  static const String loginEndpoint = '/api/auth/login';
  
  // 超时配置
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  
  // Token配置
  static const String tokenPrefix = 'Bearer ';
  static const String authHeaderKey = 'Authorization';
}

