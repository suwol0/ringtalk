import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat_model.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../providers/chat_room_provider.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/date_divider.dart';
import '../widgets/message_bubble.dart';

/// 채팅방 화면 — 메시지 목록 + 전송
class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.roomId,
    this.displayName,
  });

  final String roomId;
  final String? displayName;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  String? _myUserId;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AuthStorage.getUserId().then((id) => setState(() => _myUserId = id));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String content) {
    ref.read(chatRoomProvider(widget.roomId).notifier).sendMessage(content);
  }

  void _retry(String clientTempId) {
    ref.read(chatRoomProvider(widget.roomId).notifier).retryMessage(clientTempId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomProvider(widget.roomId));
    final myUserId = _myUserId ?? '';

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDefault,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          widget.displayName ?? '채팅',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.chatRoomMaxWidth),
          child: Column(
            children: [
              Expanded(
                child: _buildBody(state, myUserId),
              ),
              ChatInputBar(
                onSend: _send,
                enabled: _myUserId != null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ChatRoomState state, String myUserId) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state.errorMessage != null && state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                state.errorMessage!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(chatRoomProvider(widget.roomId).notifier).loadMessages(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('다시 시도'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (state.messages.isEmpty) {
      return _buildEmptyState();
    }

    final items = _buildMessageList(state.messages, myUserId);
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      itemBuilder: (context, i) => items[items.length - 1 - i],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: AppColors.textDisabled.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '메시지를 입력해서 대화를 시작해보세요',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMessageList(List<Message> messages, String myUserId) {
    final widgets = <Widget>[];
    DateTime? lastDate;

    for (final msg in messages) {
      final msgDate = DateTime(msg.createdAt.year, msg.createdAt.month, msg.createdAt.day);
      if (lastDate != msgDate) {
        widgets.add(DateDivider(date: msg.createdAt));
        lastDate = msgDate;
      }
      widgets.add(
        MessageBubble(
          message: msg,
          isMine: msg.senderId == myUserId,
          showTime: true,
          showStatus: msg.senderId == myUserId,
          onRetry: msg.status == MessageStatus.failed && msg.clientTempId != null
              ? () => _retry(msg.clientTempId!)
              : null,
        ),
      );
    }
    return widgets;
  }
}
