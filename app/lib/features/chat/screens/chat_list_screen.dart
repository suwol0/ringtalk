import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/chat_model.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../providers/rooms_provider.dart';
import '../widgets/chat_room_tile.dart';
import '../widgets/empty_chats_view.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  /// 데스크톱 2-패널 모드에서 채팅방 선택 시 호출됩니다.
  /// null이면 모바일 모드로 동작 (context.push 사용).
  final void Function(String roomId, String? displayName)? onRoomSelected;

  const ChatListScreen({super.key, this.onRoomSelected});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(roomsProvider.notifier).fetchRooms(),
    );
  }

  Future<void> _onRefresh() async {
    await ref.read(roomsProvider.notifier).fetchRooms();
  }

  void _onRoomTap(String roomId, String? displayName) {
    if (widget.onRoomSelected != null) {
      // 데스크톱 2-패널 모드
      widget.onRoomSelected!(roomId, displayName);
    } else {
      // 모바일: 라우터 push
      context.push(
        '/chats/$roomId',
        extra: displayName != null ? {'displayName': displayName} : null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomsProvider);
    final rooms = state.rooms;

    return Scaffold(
      backgroundColor: AppColors.bgTinted,
      appBar: AppBar(
        title: const Text('채팅'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: ResponsiveCenter(
        maxWidth: widget.onRoomSelected != null
            ? double.infinity // 2-패널 모드에서는 제한 없음
            : Responsive.chatRoomMaxWidth,
        child: _buildBody(context, state, rooms),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RoomsState state,
    List<ChatRoom> rooms,
  ) {
    if (state.status == RoomsLoadStatus.loading && rooms.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (state.status == RoomsLoadStatus.error && rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage ?? '채팅 목록을 불러오지 못했어요',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(roomsProvider.notifier).fetchRooms(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (rooms.isEmpty) {
      return const EmptyChatsView();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: FutureBuilder<String?>(
        future: AuthStorage.getUserId(),
        builder: (context, snapshot) {
          final myUserId = snapshot.data ?? '';
          if (myUserId.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return ListView.separated(
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const Divider(indent: 72, height: 0),
            itemBuilder: (context, i) {
              final room = rooms[i];
              return ChatRoomTile(
                room: room,
                myUserId: myUserId,
                onTap: () => _onRoomTap(room.id, room.displayName(myUserId)),
              );
            },
          );
        },
      ),
    );
  }
}
