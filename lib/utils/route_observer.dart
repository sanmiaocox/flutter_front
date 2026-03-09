import 'package:flutter/material.dart';

/// 全局路由观察者
/// 
/// 用于监听页面的路由变化，配合 AutoRefreshMixin 使用
/// 
/// 使用方法：
/// 1. 在 MaterialApp 的 navigatorObservers 中注册
/// 2. 在需要自动刷新的页面中使用 AutoRefreshMixin
/// 
/// 示例：
/// ```dart
/// MaterialApp(
///   navigatorObservers: [routeObserver],
///   // ...
/// )
/// ```
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

