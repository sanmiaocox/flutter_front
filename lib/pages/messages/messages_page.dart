import 'package:flutter/material.dart';

/// 消息界面（底部导航第三个）。
/// 后续可扩展：通知列表（点赞、评论、关注、系统通知等），按时间倒序。
class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
      ),
      body: const Center(
        child: Text('消息 - 待实现通知列表'),
      ),
    );
  }
}
