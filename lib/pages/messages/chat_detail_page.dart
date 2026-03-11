import 'package:flutter/material.dart';
import 'dart:async';
import '../../app_theme.dart';
import '../../config/api_config.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../profile/user_profile_page.dart';

/// 单条聊天消息模型（本地）
class _ChatMessage {
  final int id;
  final bool isMine;
  final String text;
  final DateTime time;
  final bool isRecalled;
  final int? serverMessageId;

  const _ChatMessage({
    required this.id,
    required this.isMine,
    required this.text,
    required this.time,
    this.isRecalled = false,
    this.serverMessageId,
  });
}

/// 与某位好友的聊天详情页
class ChatDetailPage extends StatefulWidget {
  final User friend;
  final int conversationId;

  const ChatDetailPage({
    super.key,
    required this.friend,
    this.conversationId = 0,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  int _idCounter = 0;
  bool _sending = false;
  int? _myUserId;
  Timer? _pollTimer;
  int _lastServerMessageId = 0;

  // 是否正在加载历史消息
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myUserId = await StorageService.getUserId();
    await _loadHistory();
    if (widget.conversationId != 0) {
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _pollNewMessages();
      });
    }
  }

  Future<void> _pollNewMessages() async {
    if (!mounted || widget.conversationId == 0) return;
    try {
      final resp = await ApiService.getConversationMessages(
        widget.conversationId,
        page: 0,
        size: 50,
      );
      if (resp.isSuccess && resp.data != null) {
        final content = resp.data!['content'] as List<dynamic>? ?? [];
        final newMsgs = <_ChatMessage>[];
        for (final item in content.reversed) {
          final map = item as Map<String, dynamic>;
          final serverId = map['id'] as int? ?? 0;
          if (serverId > _lastServerMessageId) {
            final senderId = (map['sender'] as Map<String, dynamic>?)?['id'] as int? ?? 0;
            final isRecalled = map['isRecalled'] as bool? ?? false;
            newMsgs.add(_ChatMessage(
              id: _idCounter++,
              isMine: senderId == _myUserId,
              text: isRecalled ? '消息已撤回' : (map['content'] as String? ?? ''),
              time: DateTime.parse(map['createdAt'] as String),
              isRecalled: isRecalled,
              serverMessageId: serverId,
            ));
            _lastServerMessageId = serverId;
          }
        }
        if (newMsgs.isNotEmpty && mounted) {
          setState(() => _messages.addAll(newMsgs));
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      }
    } catch (e) {
      debugPrint('轮询私信失败: $e');
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    if (widget.conversationId == 0) {
      // 新会话，直接显示空聊天界面，无需加载
      if (mounted) setState(() => _loadingHistory = false);
      return;
    }
    if (mounted) setState(() => _loadingHistory = true);
    try {
      final resp = await ApiService.getConversationMessages(
        widget.conversationId,
        page: 0,
        size: 30,
      );
      if (resp.isSuccess && resp.data != null) {
        final data = resp.data!;
        final content = data['content'] as List<dynamic>? ?? [];
        // 服务端返回最新在前，翻转为时间正序
        final msgs = content.reversed.map((item) {
          final map = item as Map<String, dynamic>;
          final sender = map['sender'] as Map<String, dynamic>;
          final senderId = sender['id'] as int;
          final isMine = senderId == _myUserId;
          final isRecalled = map['isRecalled'] as bool? ?? false;
          return _ChatMessage(
            id: _idCounter++,
            text: isRecalled ? '消息已撤回' : (map['content'] as String? ?? ''),
            isMine: isMine,
            time: DateTime.parse(map['createdAt'] as String),
            isRecalled: isRecalled,
            serverMessageId: map['id'] as int?,
          );
        }).toList();
        if (mounted) {
          setState(() {
            _messages.addAll(msgs);
            _loadingHistory = false;
            if (_messages.isNotEmpty) {
              _lastServerMessageId = _messages
                  .where((m) => m.serverMessageId != null)
                  .map((m) => m.serverMessageId!)
                  .fold(0, (a, b) => a > b ? a : b);
            }
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      } else {
        if (mounted) setState(() => _loadingHistory = false);
      }
    } catch (e) {
      debugPrint('加载消息历史失败: $e');
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _inputCtrl.clear();

    try {
      final resp = await ApiService.sendPrivateMessage(
        targetUserId: widget.friend.id,
        content: text,
      );
      if (resp.isSuccess && resp.data != null) {
        final map = resp.data!;
        if (mounted) {
          setState(() {
            _messages.add(_ChatMessage(
              id: _idCounter++,
              isMine: true,
              text: text,
              time: DateTime.parse(map['createdAt'] as String),
              serverMessageId: map['id'] as int?,
            ));
            _sending = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      } else {
        if (mounted) {
          setState(() => _sending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : '发送失败，请重试')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请重试')),
        );
      }
    }
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inDays == 0) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return '昨天';
    return '${t.month}/${t.day}';
  }

  bool _showTimestamp(int index) {
    if (index == 0) return true;
    final prev = _messages[index - 1];
    final curr = _messages[index];
    return curr.time.difference(prev.time).inMinutes.abs() >= 5;
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = widget.friend.avatar != null
        ? ApiConfig.getImageUrl(widget.friend.avatar!)
        : null;

    return Scaffold(
      backgroundColor: AppTheme.lycheeWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.capriBlue,
        foregroundColor: AppTheme.lycheeWhite,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _buildAvatar(avatarUrl, widget.friend.username, radius: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friend.username,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lycheeWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '#${widget.friend.userCode}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.lycheeWhite.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: _loadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.capriBlue),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 56, color: AppTheme.muted),
                            const SizedBox(height: 12),
                            Text(
                              '发送第一条消息，开始聊天吧！',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.mutedForeground),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return Column(
                            children: [
                              if (_showTimestamp(index))
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    _formatTime(msg.time),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.mutedForeground),
                                  ),
                                ),
                              _MessageBubble(
                                message: msg,
                                friendAvatarUrl: avatarUrl,
                                friendUsername: widget.friend.username,
                                friendId: widget.friend.id,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          // 输入框区域
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lycheeWhite,
        border: Border(
          top: BorderSide(color: AppTheme.muted, width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(fontSize: 15, color: AppTheme.capriBlue),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: '发送消息…',
                hintStyle: const TextStyle(
                    color: AppTheme.mutedForeground, fontSize: 14),
                filled: true,
                fillColor: AppTheme.lycheeWhite,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                      color: AppTheme.capriBlue, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                      color: AppTheme.capriBlue, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: AppTheme.capriBlue,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _sendMessage,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, String name, {double radius = 20}) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url),
        backgroundColor: AppTheme.muted,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.muted,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppTheme.capriBlue,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}

/// 单条气泡
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final String? friendAvatarUrl;
  final String friendUsername;
  final int friendId;

  const _MessageBubble({
    required this.message,
    required this.friendAvatarUrl,
    required this.friendUsername,
    required this.friendId,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...
            [
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserProfilePage(userId: friendId),
                  ),
                ),
                child: _buildAvatar(),
              ),
              const SizedBox(width: 8),
            ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine
                    ? AppTheme.capriBlue
                    : AppTheme.lycheeWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 15,
                  color: isMine ? Colors.white : AppTheme.capriBlue,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (friendAvatarUrl != null && friendAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(friendAvatarUrl!),
        backgroundColor: AppTheme.muted,
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.muted,
      child: Text(
        friendUsername.isNotEmpty ? friendUsername[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.capriBlue,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

