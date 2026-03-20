import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/contact_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../chat/providers/rooms_provider.dart';
import '../providers/friends_provider.dart';
import '../widgets/empty_friends_view.dart';
import '../widgets/friends_error_view.dart';
import '../widgets/friends_list_content.dart';
import '../widgets/friends_loading_skeleton.dart';
import '../widgets/sync_status_banner.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(friendsProvider.notifier).fetchFriends(),
    );
  }

  void _onProfileTap(RingTalkContact contact) {
    context.push('/friends/profile', extra: contact);
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
    context.push(
      '/chats/${room.id}',
      extra: {'displayName': contact.displayName},
    );
  }

  Future<void> _onRefresh() async {
    await ref.read(friendsProvider.notifier).fetchFriends();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      appBar: AppBar(
        title: const Text('친구'),
        actions: [
          _AppBarAction(
            icon: Icons.refresh_rounded,
            tooltip: '친구 목록 새로고침',
            isLoading: state.status == FriendsLoadStatus.loading,
            onPressed: () => ref.read(friendsProvider.notifier).fetchFriends(),
          ),
          _AppBarAction(
            icon: Icons.sync_rounded,
            tooltip: '연락처 동기화',
            isLoading: state.isSyncing,
            onPressed: () => ref.read(friendsProvider.notifier).syncContacts(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.contentMaxWidth),
          child: Column(
            children: [
              if (state.syncStatus != ContactSyncStatus.idle)
                SyncStatusBanner(state: state),
              Expanded(
                child: _buildBody(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FriendsState state) {
    if (state.status == FriendsLoadStatus.loading && state.friends.isEmpty) {
      return const FriendsLoadingSkeleton();
    }
    if (state.status == FriendsLoadStatus.error) {
      return FriendsErrorView(
        message: state.errorMessage ?? '친구 목록을 불러오지 못했어요',
        onRetry: () => ref.read(friendsProvider.notifier).fetchFriends(),
      );
    }
    if (state.friends.isEmpty) {
      return EmptyFriendsView(
        hasSynced: state.syncStatus == ContactSyncStatus.done,
        isSyncing: state.isSyncing,
        onSync: () => ref.read(friendsProvider.notifier).syncContacts(),
      );
    }
    return FriendsListContent(
      friends: state.friends,
      onProfileTap: _onProfileTap,
      onChatTap: (c) => _onChatTap(c),
      onRefresh: _onRefresh,
    );
  }
}

class _AppBarAction extends StatelessWidget {
  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.isLoading,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2.5,
              ),
            )
          : Icon(icon),
      tooltip: tooltip,
      onPressed: isLoading ? null : onPressed,
    );
  }
}
