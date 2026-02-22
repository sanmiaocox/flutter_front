import 'package:flutter/material.dart';

/// 个人中心（底部导航最后一个）。
/// 后续可扩展：用户信息卡片、我的动态、我的影评、我的片单、我的观影团、设置等。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('个人中心'),
      ),
      body: const Center(
        child: Text('个人中心 - 待实现用户信息与功能列表'),
      ),
    );
  }
}
