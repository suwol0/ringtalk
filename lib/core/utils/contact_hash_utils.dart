// 연락처 전화번호 SHA-256 해시 유틸리티
//
// 설계 원칙:
//   - 클라이언트: SHA-256(E.164 전화번호) → 서버로 전송
//   - 서버: 동일 방식으로 저장된 phoneHash 와 IN 절로 매칭
//   - 서버는 원본 전화번호를 받지 않음 → 프라이버시 보호
//
// ⚠️  SHA-256은 결정론적(같은 입력 = 같은 출력)이므로
//    이론적으로 레인보우 테이블 공격이 가능합니다.
//    MVP에서는 이 방식을 사용하고, 추후 HMAC-SHA256(서버 시크릿)으로 업그레이드.

import 'dart:convert';
import 'package:crypto/crypto.dart';

/// E.164 전화번호 → SHA-256 해시 (hex string)
///
/// 서버의 phoneHash 컬럼 저장 방식과 동일해야 함
String hashPhoneE164(String e164Phone) {
  final bytes = utf8.encode(e164Phone);
  final digest = sha256.convert(bytes);
  return digest.toString(); // 64자 hex string
}

/// 여러 E.164 번호를 일괄 해시
///
/// 반환: { e164: hash } 맵
Map<String, String> hashPhoneNumbers(List<String> e164Numbers) {
  return {
    for (final phone in e164Numbers) phone: hashPhoneE164(phone),
  };
}

/// 해시값 목록만 추출 (서버 API 전송용)
List<String> extractHashes(Map<String, String> phoneHashMap) {
  return phoneHashMap.values.toList();
}

/// 해시→E.164 역방향 맵 (서버 응답 매핑용)
///
/// 서버가 반환한 matched phoneHash 목록을 원래 E.164 로 되찾기 위해 사용
Map<String, String> buildReverseMap(Map<String, String> phoneHashMap) {
  return {for (final e in phoneHashMap.entries) e.value: e.key};
}
