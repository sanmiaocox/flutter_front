# 编辑资料页面Navigator错误修复

## 问题描述

用户点击"保存"按钮后，虽然数据成功更新到后端，但界面出现以下错误：

```
Failed assertion: line 5574 pos 12: '!_debugLocked': is not true.
```

界面卡在编辑资料页面，无法返回，点击左上角返回按钮也无响应。

## 错误原因分析

### 根本原因
在 `_saveProfile` 方法中，连续调用了两次 `Navigator.pop()`：

1. **第一次pop**: 关闭加载对话框
2. **第二次pop**: 返回到个人中心页面

这两次调用使用的是**同一个context**，当第一次pop的动画还在执行时，第二次pop就被调用了，导致Navigator处于锁定状态（`_debugLocked = true`），从而抛出异常。

### 为什么会锁定？
Flutter的Navigator在执行pop操作时会：
1. 设置 `_debugLocked = true`（锁定状态）
2. 执行退出动画
3. 完成后设置 `_debugLocked = false`（解锁）

如果在锁定期间再次调用pop，就会触发断言失败。

## 修复方案

### 方案1: 使用rootNavigator（最终采用）

**关键改动**:
```dart
// 关闭对话框时使用rootNavigator
Navigator.of(context, rootNavigator: true).pop();

// 返回上一页时使用普通Navigator
Navigator.of(context).pop({'success': true, 'message': '资料更新成功'});
```

**原理**:
- `rootNavigator: true` 会使用应用的根Navigator来关闭对话框
- 普通的 `Navigator.of(context)` 使用当前页面的Navigator来返回
- 两者操作的是不同的Navigator实例，不会互相冲突

### 方案2: 传递结果到上一页显示提示

**改进**:
- 编辑页面只负责返回结果：`{'success': true, 'message': '资料更新成功'}`
- 个人中心页面接收结果后显示SnackBar
- 避免在已经pop的页面上显示提示

## 完整的代码流程

### EditProfilePage (_saveProfile方法)

```dart
void _saveProfile() async {
  // 1. 验证输入
  if (name.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(...);
    return;
  }

  // 2. 显示加载对话框
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // 3. 调用API更新资料
    final response = await ApiService.updateProfile(...);

    if (!mounted) return;

    // 4. 关闭加载对话框（使用rootNavigator）
    Navigator.of(context, rootNavigator: true).pop();

    // 5. 根据结果处理
    if (response.isSuccess) {
      // 成功：返回上一页并传递结果
      Navigator.of(context).pop({'success': true, 'message': '资料更新成功'});
    } else {
      // 失败：显示错误提示，留在当前页面
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  } catch (e) {
    // 6. 异常处理
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

### ProfilePage (_onEditProfile方法)

```dart
void _onEditProfile() async {
  // 1. 跳转到编辑页面并等待结果
  final result = await Navigator.of(context).push<Map<String, dynamic>>(
    MaterialPageRoute(
      builder: (_) => EditProfilePage(
        userName: _userName,
        userBio: _userBio,
        avatarUrl: _avatarUrl,
      ),
    ),
  );

  // 2. 如果更新成功
  if (result != null && result['success'] == true && mounted) {
    // 刷新用户信息
    await _refreshData();
    
    // 显示成功提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '资料更新成功'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
```

## 用户体验流程

### 成功场景
```
用户点击"保存"
  ↓
显示加载圆圈
  ↓
调用后端API
  ↓
后端返回成功
  ↓
关闭加载圆圈
  ↓
自动返回个人中心页面
  ↓
刷新显示最新数据
  ↓
底部显示"资料更新成功"提示（2秒）
```

### 失败场景
```
用户点击"保存"
  ↓
显示加载圆圈
  ↓
调用后端API
  ↓
后端返回失败
  ↓
关闭加载圆圈
  ↓
留在编辑页面
  ↓
底部显示"更新失败: 错误信息"提示
  ↓
用户可以修改后重试或点击返回按钮
```

## 关键技术点

### 1. rootNavigator的使用
```dart
// 普通Navigator - 操作当前路由栈
Navigator.of(context).pop();

// 根Navigator - 操作应用级路由栈（包括对话框）
Navigator.of(context, rootNavigator: true).pop();
```

### 2. 页面间传递数据
```dart
// 返回时传递数据
Navigator.of(context).pop({'success': true, 'message': '成功'});

// 接收返回的数据
final result = await Navigator.of(context).push<Map<String, dynamic>>(...);
if (result != null && result['success'] == true) {
  // 处理成功情况
}
```

### 3. mounted检查
```dart
if (!mounted) return;  // 在每个异步操作后检查
```

防止在widget已经销毁后继续执行操作。

## 测试清单

- [x] 点击保存按钮，数据成功更新
- [x] 加载对话框正常显示和关闭
- [x] 更新成功后自动返回个人中心
- [x] 返回后显示"资料更新成功"提示
- [x] 个人中心自动刷新显示最新数据
- [x] 更新失败时留在编辑页面
- [x] 更新失败时显示错误提示
- [x] 点击左上角返回按钮可以正常返回
- [x] 不会出现Navigator锁定错误

## 其他Navigator错误的通用解决方案

### 问题：连续pop导致锁定
**解决方案**:
1. 使用 `rootNavigator: true` 区分不同的Navigator
2. 使用 `await Future.delayed()` 添加延迟
3. 使用 `SchedulerBinding.instance.addPostFrameCallback()` 延迟到下一帧

### 问题：在已销毁的widget上操作
**解决方案**:
```dart
if (!mounted) return;  // 始终检查mounted状态
```

### 问题：对话框无法关闭
**解决方案**:
```dart
// 使用rootNavigator关闭对话框
Navigator.of(context, rootNavigator: true).pop();
```

## 总结

这次修复的核心是：
1. ✅ 使用 `rootNavigator: true` 关闭对话框
2. ✅ 通过返回值传递结果到上一页
3. ✅ 在上一页显示成功提示并刷新数据
4. ✅ 失败时留在当前页面显示错误

这样既解决了Navigator锁定问题，又提供了良好的用户体验。

---

**修复完成时间**: 2026-03-01  
**状态**: ✅ 已修复并测试通过  
**影响文件**: 
- `lib/pages/profile/edit_profile_page.dart`
- `lib/pages/profile/profile_page.dart`




