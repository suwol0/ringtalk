// 연락처 관련 Dart 모델
//
// 처리 파이프라인:
//   기기 연락처 (LocalContact)
//     → E.164 정규화 (phone_utils.dart)
//     → SHA-256 해시 (contact_hash_utils.dart)
//     → ProcessedContact
//     → 서버 매칭 API
//     → RingTalkContact

import 'user_model.dart';

// ─── 기기에서 가져온 원본 연락처 ───────────────────────────────────────────────
class LocalContact {
  final String id;
  final String displayName;

  /// 기기에서 가져온 날것의 전화번호 목록 (포맷 미정)
  final List<String> rawPhoneNumbers;

  const LocalContact({
    required this.id,
    required this.displayName,
    required this.rawPhoneNumbers,
  });

  @override
  String toString() => 'LocalContact($displayName, $rawPhoneNumbers)';
}

// ─── 정규화 + 해시 처리 완료된 연락처 ─────────────────────────────────────────
class ProcessedContact {
  final String displayName;

  /// E.164 형식으로 정규화된 전화번호 (+821012345678 등)
  final String e164Number;

  /// SHA-256(e164Number) — 서버 API로 전송하는 값
  final String phoneHash;

  const ProcessedContact({
    required this.displayName,
    required this.e164Number,
    required this.phoneHash,
  });

  @override
  String toString() => 'ProcessedContact($displayName, $e164Number)';
}

// ─── 서버 매칭 후 최종 결과 ───────────────────────────────────────────────────
class RingTalkContact {
  final ProcessedContact local;

  /// 링톡에 가입된 유저 프로필 (미가입이면 null)
  final UserPublicProfile? profile;

  const RingTalkContact({required this.local, this.profile});

  bool get isOnRingTalk => profile != null;

  String get displayName => local.displayName;

  /// 서버 GET /users/me/friends 응답으로부터 생성
  /// (연락처 동기화 없이 서버에 저장된 친구만 표시할 때 사용)
  factory RingTalkContact.fromServerFriend(Map<String, dynamic> json) {
    final profile = UserPublicProfile.fromJson(json);
    final displayName =
        json['displayName'] as String? ?? profile.displayName;
    final dummy = ProcessedContact(
      displayName: displayName,
      e164Number: '',
      phoneHash: profile.phoneHash ?? '',
    );
    return RingTalkContact(local: dummy, profile: profile);
  }
}

// ─── 연락처 동기화 상태 ──────────────────────────────────────────────────────
enum ContactSyncStatus {
  idle,
  requestingPermission,
  fetchingContacts,
  processing,      // 정규화 + 해시
  syncing,         // 서버 API 호출
  done,
  permissionDenied,
  permissionPermanentlyDenied, // 설정으로 이동 필요
  unsupported,     // 웹 등 미지원 플랫폼
  error,
}

class ContactSyncResult {
  final ContactSyncStatus status;
  final List<RingTalkContact> contacts;

  /// 총 연락처 수
  final int totalContacts;

  /// 링톡에 가입된 수
  final int matchedCount;

  /// 에러 메시지
  final String? errorMessage;

  const ContactSyncResult({
    required this.status,
    this.contacts = const [],
    this.totalContacts = 0,
    this.matchedCount = 0,
    this.errorMessage,
  });

  factory ContactSyncResult.idle() =>
      const ContactSyncResult(status: ContactSyncStatus.idle);

  factory ContactSyncResult.error(String message) => ContactSyncResult(
        status: ContactSyncStatus.error,
        errorMessage: message,
      );
}
