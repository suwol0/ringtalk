import 'package:flutter/material.dart';

import '../../../../core/models/chat_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../../core/utils/responsive.dart';

/// 메시지 말풍선 위젯
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTime = true,
    this.showStatus = false,
    this.onRetry,
  });

  final Message message;
  final bool isMine;
  final bool showTime;
  final bool showStatus;
  /// 전송 실패 시 재시도 콜백 (null이면 버튼 미표시)
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isFailed = message.status == MessageStatus.failed;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 전송 실패 재시도 버튼 (말풍선 왼쪽)
                if (isMine && isFailed && onRetry != null) ...[
                  GestureDetector(
                    onTap: onRetry,
                    child: Tooltip(
                      message: '탭하여 재전송',
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
                Container(
                  constraints: BoxConstraints(maxWidth: bubbleMaxWidth(context)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFailed
                        ? AppColors.error.withValues(alpha: 0.08)
                        : (isMine ? AppColors.bubbleMine : AppColors.bubbleOther),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                    border: isFailed
                        ? Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 1)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: _buildContent(context),
                ),
              ],
            ),
            if (showTime || showStatus) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  if (isMine && isFailed)
                    const Text(
                      '전송 실패',
                      style: TextStyle(fontSize: 11, color: AppColors.error),
                    )
                  else ...[
                    if (showTime)
                      Text(
                        date_utils.formatMessageTime(message.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    if (showStatus && isMine) ...[
                      if (showTime) const SizedBox(width: 4),
                      _StatusIcon(status: message.status),
                    ],
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (message.isDeleted) {
      return Text(
        '삭제된 메시지입니다',
        style: TextStyle(
          color: isMine ? AppColors.bubbleMineText.withValues(alpha: 0.7) : AppColors.bubbleOtherText.withValues(alpha: 0.6),
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    switch (message.type) {
      case MessageType.image:
      case MessageType.video:
      case MessageType.file:
      case MessageType.audio:
        return _buildMediaMessage(context);
      case MessageType.system:
        return _buildSystemMessage(context);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    return SelectableText(
      message.content,
      style: TextStyle(
        color: isMine ? AppColors.bubbleMineText : AppColors.bubbleOtherText,
        fontSize: 15,
        height: 1.35,
      ),
    );
  }

  Widget _buildMediaMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.mediaUrl != null && message.mediaUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              message.mediaUrl!,
              width: 200,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 200,
                height: 100,
                color: AppColors.surfaceSubtle,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: 6),
          SelectableText(
            message.content,
            style: TextStyle(
              color: isMine ? AppColors.bubbleMineText : AppColors.bubbleOtherText,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Text(
      message.content,
      style: const TextStyle(
        color: AppColors.bubbleSystemText,
        fontSize: 13,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    return Icon(
      switch (status) {
        MessageStatus.sending => Icons.schedule_rounded,
        MessageStatus.sent => Icons.done_rounded,
        MessageStatus.delivered => Icons.done_all_rounded,
        MessageStatus.read => Icons.done_all_rounded,
        MessageStatus.failed => Icons.error_outline_rounded,
      },
      size: 14,
      color: switch (status) {
        MessageStatus.sending => AppColors.textSecondary,
        MessageStatus.sent => AppColors.textSecondary,
        MessageStatus.delivered => AppColors.textSecondary,
        MessageStatus.read => AppColors.success,
        MessageStatus.failed => AppColors.error,
      },
    );
  }
}
