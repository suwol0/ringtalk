import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;

/// 메시지 목록 날짜 구분선
class DateDivider extends StatelessWidget {
  const DateDivider({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bubbleSystem,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            date_utils.formatDateDivider(date),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.bubbleSystemText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
