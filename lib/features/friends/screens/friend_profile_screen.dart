import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/contact_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../chat/providers/rooms_provider.dart';
import '../providers/friends_provider.dart';

/// 친구 프로필 화면
class FriendProfileScreen extends ConsumerStatefulWidget {
  const FriendProfileScreen({
    super.key,
    required this.contact,
  });

  final RingTalkContact contact;

  @override
  ConsumerState<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    final profile = contact.profile;
    final name = contact.displayName;
    final statusMessage = profile?.statusMessage;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final imageUrl = profile?.profileImageUrl;

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      appBar: AppBar(
        title: const Text('친구 프로필'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.contentMaxWidth),
          child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // 프로필 아바타
            _ProfileAvatar(
              imageUrl: imageUrl,
              initial: initial,
            ),
            const SizedBox(height: 20),
            // 이름
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
              textAlign: TextAlign.center,
            ),
            if (statusMessage != null && statusMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  statusMessage,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 40),
            // 채팅하기 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async => await _onChatTap(contact),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 22),
                  label: const Text('채팅하기'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 차단하기 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _onBlockTap(contact),
                  icon: const Icon(Icons.block_rounded, size: 20),
                  label: const Text('차단하기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.errorLight),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  Future<void> _onChatTap(RingTalkContact contact) async {
    final profile = contact.profile;
    if (profile == null) return;

    final room = await ref.read(roomsProvider.notifier).getOrCreateDirectRoom(profile.id);
    if (!mounted) return;
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채팅방을 열 수 없어요. 다시 시도해 주세요.')),
      );
      return;
    }
    if (!mounted) return;
    context.push(
      '/chats/${room.id}',
      extra: {'displayName': contact.displayName},
    );
  }

  Future<void> _onBlockTap(RingTalkContact contact) async {
    final profile = contact.profile;
    if (profile == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('친구 차단'),
        content: Text(
          '${contact.displayName}님을 차단하시겠어요?\n차단된 친구는 메시지를 보낼 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('차단하기'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(friendsRepositoryProvider).blockUser(profile.id);
      if (!mounted) return;
      context.pop();
      ref.read(friendsProvider.notifier).fetchFriends();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('차단 처리 중 오류가 발생했어요: $e')),
      );
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.imageUrl, required this.initial});

  final String? imageUrl;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 56,
        backgroundColor: AppColors.primaryHover,
        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImageProvider(imageUrl!)
            : null,
        child: imageUrl == null || imageUrl!.isEmpty
            ? Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 48,
                ),
              )
            : null,
      ),
    );
  }
}
