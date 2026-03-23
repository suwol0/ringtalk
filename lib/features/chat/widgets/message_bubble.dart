import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // 서버에서 content 필드에 S3 URL이 직접 담김
    final url = message.content.isNotEmpty
        ? message.content
        : (message.mediaUrl ?? '');

    switch (message.type) {
      case MessageType.image:
        return _buildImageBubble(url);
      case MessageType.video:
        return _buildVideoBubble(url);
      case MessageType.file:
      case MessageType.audio:
        return _buildFileTile(context, url);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildImageBubble(String url) {
    if (url.isEmpty) {
      return _buildBrokenImage();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 220,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 220,
          height: 160,
          color: AppColors.surfaceSubtle,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildBrokenImage(),
      ),
    );
  }

  Widget _buildVideoBubble(String url) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.videocam_rounded, color: Colors.white38, size: 48),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
        ),
      ],
    );
  }

  Widget _buildFileTile(BuildContext context, String url) {
    final fileName = _fileNameFromUrl(url);
    final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : 'FILE';
    final isAudio = message.type == MessageType.audio;

    return GestureDetector(
      onTap: () => _openUrl(context, url),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: (isMine ? AppColors.primary : AppColors.surfaceSubtle)
              .withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (isMine ? AppColors.primary : AppColors.borderDefault)
                .withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isAudio ? Icons.audiotrack_rounded : Icons.insert_drive_file_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      color: isMine ? AppColors.bubbleMineText : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ext,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.download_rounded, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildBrokenImage() {
    return Container(
      width: 220,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: AppColors.textDisabled, size: 36),
          SizedBox(height: 4),
          Text('이미지를 불러올 수 없어요', style: TextStyle(color: AppColors.textDisabled, fontSize: 12)),
        ],
      ),
    );
  }

  static String _fileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final last = segments.last;
        // S3 key 형식: attachments/{userId}/{timestamp}-{uuid}.ext
        // 타임스탬프-uuid 부분 제거하고 확장자만 유지하거나 전체 표시
        return last;
      }
    } catch (_) {}
    return '첨부파일';
  }

  static Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파일을 열 수 없어요.')),
      );
    }
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
