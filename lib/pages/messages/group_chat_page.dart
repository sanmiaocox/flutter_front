import 'package:flutter/material.dart';
import 'dart:async';
import '../../app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../profile/user_profile_page.dart';

/// 单条群聊消息模型
class _GroupMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String text;
  final DateTime time;
  final bool isRecalled;
  final bool isMine;

  const _GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.text,
    required this.time,
    this.isRecalled = false,
    required this.isMine,
  });
}

/// 活动群聊页面
class GroupChatPage extends StatefulWidget {
  final int groupId;
  final String groupName;
  final String? groupAvatar;
  final String eventTitle;
  final bool isOwner;
  final int? eventId;

  const GroupChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupAvatar,
    required this.eventTitle,
    this.isOwner = false,
    this.eventId,
  });

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_GroupMessage> _messages = [];
  bool _loadingHistory = true;
  bool _sending = false;
  int? _myUserId;
  int _memberCount = 0;
  Timer? _pollTimer;
  int _lastMessageId = 0; // 已知最新消息ID，用于增量拉取

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myUserId = await StorageService.getUserId();
    await Future.wait([_loadHistory(), _loadGroupDetail()]);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGroupDetail() async {
    try {
      final resp = await ApiService.getGroupDetail(widget.groupId);
      if (resp.isSuccess && resp.data != null && mounted) {
        setState(() {
          _memberCount = resp.data!['memberCount'] as int? ?? 0;
        });
      }
    } catch (e) {
      debugPrint('加载群聊详情失败: $e');
    }
  }

  Future<void> _loadHistory() async {
    if (mounted) setState(() => _loadingHistory = true);
    try {
      final resp = await ApiService.getGroupMessages(widget.groupId, page: 0, size: 50);
      if (resp.isSuccess && resp.data != null) {
        final content = resp.data!['content'] as List<dynamic>? ?? [];
        // 服务端最新在前，翻转为时间正序
        final msgs = content.reversed.map((item) {
          final map = item as Map<String, dynamic>;
          final sender = map['sender'] as Map<String, dynamic>;
          final senderId = sender['id'] as int;
          final isRecalled = map['isRecalled'] as bool? ?? false;
          final avatar = sender['avatar'] as String?;
          return _GroupMessage(
            id: map['id'] as int,
            senderId: senderId,
            senderName: sender['username'] as String? ?? '用户',
            senderAvatar: avatar != null ? ApiConfig.getImageUrl(avatar) : null,
            text: isRecalled ? '消息已撤回' : (map['content'] as String? ?? ''),
            time: DateTime.parse(map['createdAt'] as String),
            isRecalled: isRecalled,
            isMine: senderId == _myUserId,
          );
        }).toList();
        if (mounted) {
          setState(() {
            _messages.addAll(msgs);
            _loadingHistory = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      } else {
        if (mounted) setState(() => _loadingHistory = false);
      }
    } catch (e) {
      debugPrint('加载群消息失败: $e');
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
      final resp = await ApiService.sendGroupMessage(
        groupId: widget.groupId,
        content: text,
      );
      if (resp.isSuccess && resp.data != null) {
        final map = resp.data!;
        final sender = map['sender'] as Map<String, dynamic>;
        final avatar = sender['avatar'] as String?;
        if (mounted) {
          setState(() {
            _messages.add(_GroupMessage(
              id: map['id'] as int? ?? DateTime.now().millisecondsSinceEpoch,
              senderId: _myUserId ?? 0,
              senderName: sender['username'] as String? ?? '我',
              senderAvatar: avatar != null ? ApiConfig.getImageUrl(avatar) : null,
              text: text,
              time: DateTime.parse(map['createdAt'] as String),
              isMine: true,
            ));
            _sending = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      } else {
        if (mounted) {
          setState(() => _sending = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resp.message.isNotEmpty ? resp.message : '发送失败')),
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
            _buildGroupAvatar(),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lycheeWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_memberCount > 0)
                    Text(
                      '$_memberCount 位成员',
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
          // 活动名称提示条
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.capriBlue.withAlpha(20),
            child: Row(
              children: [
                const Icon(Icons.event_rounded,
                    size: 14, color: AppTheme.mutedForeground),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.eventTitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.mutedForeground),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // 消息列表
          Expanded(
            child: _loadingHistory
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.capriBlue),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined,
                                size: 56, color: AppTheme.muted),
                            const SizedBox(height: 12),
                            const Text(
                              '群里还没有消息，快来发第一条吧！',
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
                            horizontal: 12, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return Column(
                            children: [
                              if (_showTimestamp(index))
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(
                                    _formatTime(msg.time),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.mutedForeground),
                                  ),
                                ),
                              _GroupMessageBubble(message: msg, myUserId: _myUserId ?? 0),
                            ],
                          );
                        },
                      ),
          ),
          // 输入框
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildGroupAvatar() {
    if (widget.groupAvatar != null && widget.groupAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(
            ApiConfig.getImageUrl(widget.groupAvatar!)),
        backgroundColor: AppTheme.muted,
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.muted,
      child: const Icon(Icons.group_rounded,
          size: 18, color: AppTheme.capriBlue),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.lycheeWhite,
        border: Border(
            top: BorderSide(color: AppTheme.muted, width: 1)),
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
              style: const TextStyle(
                  fontSize: 15, color: AppTheme.capriBlue),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: '发消息…',
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
                  borderSide:
                      const BorderSide(color: AppTheme.capriBlue, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _sending ? AppTheme.muted : AppTheme.capriBlue,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _sending ? null : _sendMessage,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 群聊消息气泡
class _GroupMessageBubble extends StatelessWidget {
  final _GroupMessage message;
  final int myUserId;

  const _GroupMessageBubble({required this.message, required this.myUserId});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfilePage(userId: message.senderId),
                ),
              ),
              child: _buildAvatar(),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
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
                    border: isMine
                        ? null
                        : Border.all(color: AppTheme.muted, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMine
                          ? Colors.white
                          : AppTheme.capriBlue,
                      height: 1.4,
                      fontStyle: message.isRecalled
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (message.senderAvatar != null && message.senderAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(message.senderAvatar!),
        backgroundColor: AppTheme.muted,
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.muted,
      child: Text(
        message.senderName.isNotEmpty
            ? message.senderName[0].toUpperCase()
            : '?',
        style: const TextStyle(
            color: AppTheme.capriBlue,
            fontWeight: FontWeight.bold,
            fontSize: 12),
      ),
    );
  }
}

