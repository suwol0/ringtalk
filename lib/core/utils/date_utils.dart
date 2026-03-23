// 날짜/시간 유틸리티 (TypeScript utils/date.ts의 Dart 버전)


/// 메시지 타임스탬프 포맷 (오전/오후 12:34)
String formatMessageTime(DateTime date) {
  final hour = date.hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = hour < 12 ? '오전' : '오후';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$period $displayHour:$minute';
}

/// 채팅방 목록 날짜 포맷
/// 오늘이면 시간, 올해면 월/일, 그 외엔 연/월/일
String formatRoomListDate(DateTime date) {
  final now = DateTime.now();
  final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
  final isThisYear = date.year == now.year;

  if (isToday) return formatMessageTime(date);
  if (isThisYear) return '${date.month}월 ${date.day}일';
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
}

/// 날짜 구분선 포맷 (2024년 3월 5일 화요일)
String formatDateDivider(DateTime date) {
  const days = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
  return '${date.year}년 ${date.month}월 ${date.day}일 ${days[date.weekday % 7]}';
}

/// 마지막 접속 시간 표시 (방금 전, n분 전, n시간 전, ...)
String formatLastSeen(DateTime date) {
  final diff = DateTime.now().difference(date);

  if (diff.inSeconds < 60) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return formatRoomListDate(date);
}

/// OTP 타이머 포맷 (03:00)
String formatOtpTimer(int seconds) {
  final m = (seconds ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// 두 날짜가 같은 날인지 확인
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
