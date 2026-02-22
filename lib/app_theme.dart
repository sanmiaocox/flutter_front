import 'package:flutter/material.dart';

/// 电影交流社区系统主题色（见 README）
class AppTheme {
  /// 卡布里蓝
  static const Color capriBlue = Color(0xFF015697);

  /// 柔和桃
  static const Color softPeach = Color(0xFFFEBF9C);

  /// 荔枝白
  static const Color lycheeWhite = Color(0xFFFEFFEF);

  /// 灰色文字（Figma muted-foreground）
  static const Color mutedForeground = Color(0xFF5F7689);

  /// 浅蓝/边框（Figma muted）
  static const Color muted = Color(0xFFA0C3D9);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: capriBlue,
        primary: capriBlue,
        secondary: softPeach,
        surface: lycheeWhite,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: lycheeWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: capriBlue,
        foregroundColor: lycheeWhite,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: capriBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
