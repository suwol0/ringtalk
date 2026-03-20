// 날짜/시간 유틸리티

/**
 * 메시지 타임스탬프 포맷 (오전/오후 12:34)
 */
export function formatMessageTime(date: Date | string): string {
  const d = new Date(date);
  const hours = d.getHours();
  const minutes = d.getMinutes().toString().padStart(2, '0');
  const period = hours < 12 ? '오전' : '오후';
  const displayHours = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours;
  return `${period} ${displayHours}:${minutes}`;
}

/**
 * 채팅방 목록 날짜 포맷
 * 오늘이면 시간, 올해면 월/일, 그 외엔 연/월/일
 */
export function formatRoomListDate(date: Date | string): string {
  const d = new Date(date);
  const now = new Date();
  const isToday =
    d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate();
  const isThisYear = d.getFullYear() === now.getFullYear();

  if (isToday) return formatMessageTime(d);
  if (isThisYear) return `${d.getMonth() + 1}월 ${d.getDate()}일`;
  return `${d.getFullYear()}.${(d.getMonth() + 1).toString().padStart(2, '0')}.${d.getDate().toString().padStart(2, '0')}`;
}

/**
 * 날짜 구분선 포맷 (2024년 3월 5일 화요일)
 */
export function formatDateDivider(date: Date | string): string {
  const d = new Date(date);
  const days = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
  return `${d.getFullYear()}년 ${d.getMonth() + 1}월 ${d.getDate()}일 ${days[d.getDay()]}`;
}

/**
 * 마지막 접속 시간 표시 (방금 전, n분 전, n시간 전, ...)
 */
export function formatLastSeen(date: Date | string): string {
  const d = new Date(date);
  const diffMs = Date.now() - d.getTime();
  const diffSec = Math.floor(diffMs / 1000);

  if (diffSec < 60) return '방금 전';
  if (diffSec < 3600) return `${Math.floor(diffSec / 60)}분 전`;
  if (diffSec < 86400) return `${Math.floor(diffSec / 3600)}시간 전`;
  if (diffSec < 604800) return `${Math.floor(diffSec / 86400)}일 전`;
  return formatRoomListDate(d);
}

/**
 * 두 날짜가 같은 날인지 확인
 */
export function isSameDay(a: Date | string, b: Date | string): boolean {
  const da = new Date(a);
  const db = new Date(b);
  return (
    da.getFullYear() === db.getFullYear() &&
    da.getMonth() === db.getMonth() &&
    da.getDate() === db.getDate()
  );
}
