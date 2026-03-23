import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/data/upload_repository.dart';
import '../../../../core/theme/app_colors.dart';

/// 파일 첨부 콜백 인자
class AttachmentFile {
  final Uint8List bytes;
  final String fileName;
  final String contentType;

  const AttachmentFile({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });
}

/// 채팅 입력창
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onAttachment,
    this.enabled = true,
    this.hintText = '메시지를 입력하세요',
  });

  final void Function(String text) onSend;

  /// 파일이 선택됐을 때 호출. null이면 첨부 버튼 숨김.
  final void Function(AttachmentFile file)? onAttachment;

  final bool enabled;
  final String hintText;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    if (text.length > AppConstants.maxMessageLength) return;

    widget.onSend(text);
    _controller.clear();
  }

  Future<void> _showAttachmentSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDefault,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _AttachOption(
                icon: Icons.image_rounded,
                label: '이미지 / 동영상',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              _AttachOption(
                icon: Icons.insert_drive_file_rounded,
                label: '파일',
                color: AppColors.info,
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? xfile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      final ext = xfile.name.contains('.') ? xfile.name.split('.').last : 'jpg';
      final contentType = UploadRepository.contentTypeFromExtension(ext);

      widget.onAttachment?.call(
        AttachmentFile(bytes: bytes, fileName: xfile.name, contentType: contentType),
      );
    } catch (e) {
      _showError('이미지를 불러오지 못했어요.');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'mp4', 'mov', 'pdf'],
        withData: true, // web 대응: 바이트로 직접 읽기
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final bytes = picked.bytes;
      if (bytes == null) return;

      final ext = picked.extension ?? 'bin';
      final contentType = UploadRepository.contentTypeFromExtension(ext);

      widget.onAttachment?.call(
        AttachmentFile(
          bytes: bytes,
          fileName: picked.name,
          contentType: contentType,
        ),
      );
    } catch (e) {
      _showError('파일을 불러오지 못했어요.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDefault,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 첨부 버튼
            if (widget.onAttachment != null)
              IconButton(
                onPressed: widget.enabled ? _showAttachmentSheet : null,
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: AppColors.textSecondary,
                tooltip: '파일 첨부',
                padding: const EdgeInsets.all(8),
              ),

            // 텍스트 입력
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 전송 버튼
            _SendButton(
              onPressed: _send,
              enabled: widget.enabled && _controller.text.trim().isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 첨부 옵션 아이템 ─────────────────────────────────────────────────────────
class _AttachOption extends StatelessWidget {
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      onTap: onTap,
    );
  }
}

// ─── 전송 버튼 ────────────────────────────────────────────────────────────────
class _SendButton extends StatelessWidget {
  const _SendButton({required this.onPressed, required this.enabled});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.primary : AppColors.textDisabled.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(24),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
