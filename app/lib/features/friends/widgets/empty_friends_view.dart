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
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySurface,
              ),
              child: Icon(
                hasSynced
                    ? Icons.people_outline_rounded
                    : Icons.contacts_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasSynced ? '링톡을 사용 중인 친구가 없어요' : '연락처를 동기화해 보세요',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              hasSynced
                  ? '친구에게 링톡을 추천해 보세요!'
                  : '연락처에서 링톡을 사용하는\n친구를 자동으로 찾아드려요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!hasSynced)
              ElevatedButton.icon(
                onPressed: isSyncing ? null : onSync,
                icon: isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.sync_rounded),
                label: Text(isSyncing ? '동기화 중...' : '연락처 동기화'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
