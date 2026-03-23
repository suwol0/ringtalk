import 'package:flutter/material.dart';

import '../../../../core/models/contact_model.dart';
import '../../../../core/theme/app_colors.dart';
import 'friend_tile.dart';

/// 친구 목록 본문 (헤더 + 리스트)
class FriendsListContent extends StatelessWidget {
  const FriendsListContent({
    super.key,
    required this.friends,
    this.onProfileTap,
    this.onChatTap,
    this.onRefresh,
  });

  final List<RingTalkContact> friends;
  final void Function(RingTalkContact)? onProfileTap;
  final void Function(RingTalkContact)? onChatTap;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async => await Future<void>.value(),
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // 친구 수 헤더
          SliverToBoxAdapter(
            child: _FriendsCountHeader(count: friends.length),
          ),
          // 친구 리스트
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final contact = friends[index];
                return Column(
                  children: [
                    FriendTile(
                      contact: contact,
                      onProfileTap: onProfileTap != null
                          ? () => onProfileTap!(contact)
                          : null,
                      onChatTap: onChatTap != null
                          ? () => onChatTap!(contact)
                          : null,
                    ),
                    if (index < friends.length - 1)
                      const Divider(
                        height: 0,
                        indent: 72,
                        color: AppColors.borderSubtle,
                      ),
                  ],
                );
              },
              childCount: friends.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _FriendsCountHeader extends StatelessWidget {
  const _FriendsCountHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: AppColors.bgDefault,
      child: Text(
        '친구 $count명',
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
