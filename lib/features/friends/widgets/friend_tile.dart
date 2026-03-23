import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/contact_model.dart';
import '../../../../core/theme/app_colors.dart';

/// 친구 목록 타일
class FriendTile extends StatelessWidget {
  const FriendTile({
    super.key,
    required this.contact,
    this.onProfileTap,
    this.onChatTap,
  });

  final RingTalkContact contact;
  final VoidCallback? onProfileTap;
  final VoidCallback? onChatTap;

  @override
  Widget build(BuildContext context) {
    final profile = contact.profile;
    final name = contact.displayName;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Material(
      color: AppColors.surfaceDefault,
      child: InkWell(
        onTap: onProfileTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // 프로필 아바타
              _Avatar(
                imageUrl: profile?.profileImageUrl,
                initial: initial,
              ),
              const SizedBox(width: 14),
              // 이름 + 상태 메시지
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile?.statusMessage != null &&
                        profile!.statusMessage!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.statusMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // 채팅하기 버튼
              TextButton(
                onPressed: onChatTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '채팅하기',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.imageUrl, required this.initial});

  final String? imageUrl;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
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
                fontSize: 20,
              ),
            )
          : null,
    );
  }
}
