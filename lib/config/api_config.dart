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

