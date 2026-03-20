// 전화번호 유틸리티

/**
 * 전화번호를 E.164 형식으로 정규화
 * 예: 01012345678 → +821012345678
 */
export function normalizePhoneNumber(phone: string, defaultCountryCode = '82'): string {
  const digits = phone.replace(/\D/g, '');

  if (phone.startsWith('+')) {
    return `+${digits}`;
  }

  if (digits.startsWith('0')) {
    return `+${defaultCountryCode}${digits.slice(1)}`;
  }

  return `+${defaultCountryCode}${digits}`;
}

/**
 * E.164 전화번호 유효성 검사
 */
export function isValidPhoneNumber(phone: string): boolean {
  return /^\+[1-9]\d{7,14}$/.test(phone);
}

/**
 * 전화번호 마스킹 (예: +82 010-****-5678)
 */
export function maskPhoneNumber(phone: string): string {
  const normalized = normalizePhoneNumber(phone);
  if (normalized.length < 8) return '***';
  const visible = normalized.slice(-4);
  return `${normalized.slice(0, 3)} ***-****-${visible}`;
}
