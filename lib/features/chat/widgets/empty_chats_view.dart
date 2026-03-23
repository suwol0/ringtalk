import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// 채팅 목록 빈 상태
class EmptyChatsView extends StatelessWidget {
  const EmptyChatsView({
    super.key,
    this.icon = Icons.chat_bubble_outline_rounded,
    this.title = '아직 채팅이 없어요',
    this.desc = '친구 탭에서 친구를 추가하고\n대화를 시작해 보세요!',
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
