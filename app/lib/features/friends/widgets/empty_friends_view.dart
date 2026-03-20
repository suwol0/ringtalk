import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 친구 목록 빈 상태 뷰
class EmptyFriendsView extends StatelessWidget {
  const EmptyFriendsView({
    super.key,
    required this.hasSynced,
    required this.isSyncing,
    required this.onSync,
  });

  final bool hasSynced;
  final bool isSyncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSynced
                  ? Icons.people_outline_rounded
                  : Icons.contacts_rounded,
              size: 64,
              color: AppColors.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              hasSynced ? '링톡을 사용 중인 친구가 없어요' : '연락처를 동기화해 보세요',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasSynced
                  ? '친구에게 링톡을 추천해 보세요!'
                  : '연락처에서 링톡을 사용하는\n친구를 자동으로 찾아드려요.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            if (!hasSynced)
              ElevatedButton.icon(
                onPressed: isSyncing ? null : onSync,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('연락처 동기화'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
