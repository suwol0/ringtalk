// 전화번호 유틸리티 (TypeScript utils/phone.ts의 Dart 버전 + 강화)
//
// E.164 형식: +[국가코드][지역코드없이][번호]
// 예시:
//   010-1234-5678  →  +821012345678
//   01012345678    →  +821012345678
//   +82 10-1234-5678 → +821012345678
//   02-1234-5678   →  +82212345678  (서울 지역번호)
//   010 1234 5678  →  +821012345678

/// 전화번호에서 숫자만 추출
String _digitsOnly(String phone) => phone.replaceAll(RegExp(r'\D'), '');

/// 한국 전화번호 E.164 변환 규칙
///
/// 한국 국가코드 +82
/// 국내 번호에서 앞의 0을 제거하고 +82 를 붙임
/// 예: 010-1234-5678 → digits=01012345678 → +821012345678
///     02-1234-5678  → digits=0212345678  → +82212345678
String? _toKoreanE164(String phone) {
  final digits = _digitsOnly(phone);
  if (digits.isEmpty) return null;

  // 이미 국제 형식 (+82...)
  if (phone.trimLeft().startsWith('+82')) {
    final international = digits; // 82로 시작
    if (international.startsWith('82') && international.length >= 10) {
      return '+$international';
    }
  }

  // 국내 번호: 0으로 시작
  if (digits.startsWith('0') && digits.length >= 9) {
    return '+82${digits.substring(1)}';
  }

  // 0 없이 국내 번호 (드문 케이스: 1012345678)
  if (digits.startsWith('1') && digits.length == 10) {
    return '+82$digits';
  }

  return null;
}

/// 전화번호를 E.164 형식으로 정규화
///
/// [phone]    : 입력 전화번호 (어떤 형식이든)
/// [countryCode] : 기본 국가코드 (앞에 + 없이, 기본 '82')
///
/// 반환값: E.164 형식 문자열, 변환 불가 시 null
String? normalizeToE164(String phone, {String defaultCountryCode = '82'}) {
  final trimmed = phone.trim();
  if (trimmed.isEmpty) return null;

  // 이미 + 로 시작하는 국제 번호
  if (trimmed.startsWith('+')) {
    final digits = _digitsOnly(trimmed);
    // 최소 7자리 ~ 최대 15자리 (E.164 규격)
    if (digits.length >= 7 && digits.length <= 15) {
      return '+$digits';
    }
    return null;
  }

  // 국가코드 82 (한국) 기본 처리
  if (defaultCountryCode == '82') {
    return _toKoreanE164(trimmed);
  }

  // 다른 국가: 숫자만 추출 후 국가코드 붙이기
  final digits = _digitsOnly(trimmed);
  if (digits.isEmpty) return null;

  final withCountry = digits.startsWith('0')
      ? '+$defaultCountryCode${digits.substring(1)}'
      : '+$defaultCountryCode$digits';

  final resultDigits = _digitsOnly(withCountry);
  if (resultDigits.length >= 7 && resultDigits.length <= 15) {
    return '+$resultDigits';
  }
  return null;
}

/// E.164 형식 유효성 검사
bool isValidE164(String phone) {
  return RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(phone);
}

/// 화면 표시용 전화번호 정규화 (기존 호환성 유지)
String normalizePhoneNumber(String phone, {String defaultCountryCode = '82'}) {
  return normalizeToE164(phone, defaultCountryCode: defaultCountryCode) ?? phone;
}

/// E.164 유효성 검사 (기존 호환성 유지)
bool isValidPhoneNumber(String phone) => isValidE164(phone);

/// 전화번호 마스킹 (예: +82 ***-****-5678)
String maskPhoneNumber(String phone) {
  final normalized = normalizePhoneNumber(phone);
  if (normalized.length < 8) return '***';
  final visible = normalized.substring(normalized.length - 4);
  return '${normalized.substring(0, 3)} ***-****-$visible';
}

/// 연락처 배치 정규화
///
/// 하나의 연락처에 여러 번호가 있을 때 유효한 E.164 번호만 추출
List<String> normalizeContactNumbers(
  List<String> rawNumbers, {
  String defaultCountryCode = '82',
}) {
  final result = <String>{};

  for (final raw in rawNumbers) {
    final e164 = normalizeToE164(raw, defaultCountryCode: defaultCountryCode);
    if (e164 != null && isValidE164(e164)) {
      result.add(e164);
    }
  }

  return result.toList();
}
