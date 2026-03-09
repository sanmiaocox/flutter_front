import 'package:flutter/material.dart';

/// 自动刷新 Mixin
/// 
/// 使用方法：
/// 1. 在 State 类中混入此 Mixin 和 RouteAware
/// 2. 实现 onRefresh() 方法
/// 3. 在 didChangeDependencies 中调用 subscribe()
/// 4. 在 dispose 中调用 unsubscribe()
/// 
/// 示例：
/// ```dart
/// class _MyPageState extends State<MyPage> 
///     with AutoRefreshMixin, RouteAware {
///   
///   @override
///   void didChangeDependencies() {
///     super.didChangeDependencies();
///     subscribe(routeObserver);
///   }
///   
///   @override
///   void dispose() {
///     unsubscribe(routeObserver);
///     super.dispose();
///   }
///   
///   @override
///   Future<void> onRefresh() async {
///     // 实现刷新逻辑
///   }
/// }
/// ```
mixin AutoRefreshMixin<T extends StatefulWidget> on State<T>, RouteAware {
  /// 是否是首次加载
  bool _isFirstLoad = true;

  /// 是否启用调试日志
  bool get enableDebugLog => false;

  /// 刷新数据的方法，子类必须实现
  Future<void> onRefresh();

  /// 订阅路由变化
  void subscribe(RouteObserver<PageRoute> routeObserver) {
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
      _log('订阅路由观察者');
    }
  }

  /// 取消订阅
  void unsubscribe(RouteObserver<PageRoute> routeObserver) {
    routeObserver.unsubscribe(this);
    _log('取消订阅路由观察者');
  }

  /// 打印日志
  void _log(String message) {
    if (enableDebugLog) {
      debugPrint('[AutoRefresh] ${T.toString()}: $message');
    }
  }

  @override
  void didPopNext() {
    // 从子页面返回时调用
    _log('从子页面返回，开始刷新');
    if (!_isFirstLoad) {
      onRefresh();
    }
  }

  @override
  void didPush() {
    // 页面首次进入时调用
    _log('页面首次进入');
    _isFirstLoad = false;
  }

  @override
  void didPushNext() {
    // 跳转到子页面时调用
    _log('跳转到子页面');
  }

  @override
  void didPop() {
    // 页面被弹出时调用
    _log('页面被弹出');
  }
}

