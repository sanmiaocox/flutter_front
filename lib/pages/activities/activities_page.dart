import 'package:flutter/material.dart';

/// 已参加观影团的活动（底部导航第二个）。
/// 后续可扩展：Tab「我发起的」「我参与的」，列表项与状态标签等。
class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('已参加活动'),
      ),
      body: const Center(
        child: Text('已参加观影团的活动 - 待实现我发起的/我参与的'),
      ),
    );
  }
}
