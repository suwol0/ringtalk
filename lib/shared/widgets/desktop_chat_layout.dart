import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_room_screen.dart';

/// 데스크톱 전용 채팅 2-패널 레이아웃
///
/// - 왼쪽: 채팅 목록 (고정 너비 [Responsive.chatSidePanelWidth])
/// - 오른쪽: 선택된 채팅방 또는 빈 상태
///
/// 모바일에서는 사용되지 않으며, [ChatListScreen]이 직접 라우터 push를 사용합니다.
final desktopSelectedRoomProvider = StateProvider<_SelectedRoom?>((ref) => null);

class _SelectedRoom {
  final String roomId;
  final String? displayName;
  const _SelectedRoom({required this.roomId, this.displayName});
}

class DesktopChatLayout extends ConsumerWidget {
  const DesktopChatLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(desktopSelectedRoomProvider);

    return Row(
      children: [
        // 왼쪽 채팅 목록 패널
        SizedBox(
          width: Responsive.chatSidePanelWidth,
          child: ChatListScreen(
            onRoomSelected: (roomId, displayName) {
              ref.read(desktopSelectedRoomProvider.notifier).state =
                  _SelectedRoom(roomId: roomId, displayName: displayName);
            },
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        // 오른쪽 채팅방 패널
        Expanded(
          child: selected == null
              ? const _EmptyRoomPanel()
              : ChatRoomScreen(
                  key: ValueKey(selected.roomId),
                  roomId: selected.roomId,
                  displayName: selected.displayName,
                ),
        ),
      ],
    );
  }
}

class _EmptyRoomPanel extends StatelessWidget {
  const _EmptyRoomPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgDefault,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 72,
              color: AppColors.textDisabled.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              '대화를 선택해 주세요',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '왼쪽에서 채팅방을 선택하면\n여기에 대화가 표시됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
