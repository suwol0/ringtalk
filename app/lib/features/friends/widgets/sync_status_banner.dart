import 'package:flutter/material.dart';

import '../../../core/models/contact_model.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/friends_provider.dart';

/// 연락처 동기화 상태 배너
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key, required this.state});

  final FriendsState state;

  Color get _bgColor {
    switch (state.syncStatus) {
      case ContactSyncStatus.done:
        return AppColors.success.withValues(alpha: 0.12);
      case ContactSyncStatus.permissionDenied:
      case ContactSyncStatus.permissionPermanentlyDenied:
      case ContactSyncStatus.error:
        return AppColors.error.withValues(alpha: 0.1);
      default:
        return AppColors.primarySurface;
    }
  }

  Color get _textColor {
    switch (state.syncStatus) {
      case ContactSyncStatus.done:
        return AppColors.success;
      case ContactSyncStatus.permissionDenied:
      case ContactSyncStatus.permissionPermanentlyDenied:
      case ContactSyncStatus.error:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (state.isSyncing) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              state.syncStatusLabel,
              style: TextStyle(
                fontSize: 13,
                color: _textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
