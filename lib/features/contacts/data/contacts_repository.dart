// 연락처 저장소
//
// 책임:
//   1. 플랫폼 권한 요청 (permission_handler)
//   2. 기기 연락처 가져오기 (flutter_contacts)
//   3. 전화번호 E.164 정규화 (phone_utils)
//   4. SHA-256 해시 변환 (contact_hash_utils)
//   5. 서버 매칭 API 호출 (/contacts/sync)
//   6. RingTalkContact 결과 반환

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../core/constants/app_constants.dart';
import '../../../core/models/contact_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/contact_hash_utils.dart';
import '../../../core/utils/phone_utils.dart';

class ContactsRepository {
  // ─── 1. 권한 요청 ───────────────────────────────────────────────────────────

  /// 연락처 권한 상태 반환
  Future<ph.PermissionStatus> getContactPermissionStatus() async {
    if (kIsWeb) return ph.PermissionStatus.denied; // 웹 미지원
    return ph.Permission.contacts.status;
  }

  /// 연락처 권한 요청
  ///
  /// 반환값:
  ///   - granted              → 바로 진행 가능
  ///   - denied               → 다시 요청 가능
  ///   - permanentlyDenied    → 설정 앱으로 안내 필요
  Future<ph.PermissionStatus> requestContactPermission() async {
    if (kIsWeb) return ph.PermissionStatus.denied;
    final status = await ph.Permission.contacts.request();
    return status;
  }

  /// 설정 앱 열기 (permanentlyDenied 대응)
  Future<void> openAppSettings() => ph.openAppSettings();

  // ─── 2. 연락처 가져오기 ─────────────────────────────────────────────────────

  /// 기기 연락처 전체 로드
  ///
  /// withProperties: true → 전화번호 등 상세 정보 포함
  Future<List<LocalContact>> fetchDeviceContacts() async {
    if (kIsWeb) return [];

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false, // 동기화에 사진 불필요
    );

    return contacts
        .map((c) => LocalContact(
              id: c.id,
              displayName: _resolveDisplayName(c),
              rawPhoneNumbers: c.phones.map((p) => p.number).toList(),
            ))
        .where((c) => c.rawPhoneNumbers.isNotEmpty)
        .toList();
  }

  String _resolveDisplayName(Contact c) {
    if (c.displayName.isNotEmpty) return c.displayName;
    final name = [c.name.first, c.name.last]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();
    return name.isNotEmpty ? name : '(이름 없음)';
  }

  // ─── 3 + 4. E.164 정규화 + SHA-256 해시 ────────────────────────────────────

  /// LocalContact 목록 → ProcessedContact 목록
  ///
  /// - 하나의 연락처에 여러 번호가 있으면 유효한 E.164 번호마다 항목 생성
  /// - 유효하지 않은 번호는 제외
  List<ProcessedContact> processContacts(List<LocalContact> raw) {
    final result = <ProcessedContact>[];

    for (final contact in raw) {
      final validNumbers = normalizeContactNumbers(contact.rawPhoneNumbers);

      for (final e164 in validNumbers) {
        result.add(ProcessedContact(
          displayName: contact.displayName,
          e164Number: e164,
          phoneHash: hashPhoneE164(e164),
        ));
      }
    }

    // 중복 해시 제거 (같은 번호를 가진 여러 연락처 항목)
    final seen = <String>{};
    return result.where((c) => seen.add(c.phoneHash)).toList();
  }

  // ─── 5. 서버 동기화 API ─────────────────────────────────────────────────────

  /// 처리된 연락처를 서버로 보내 링톡 가입자 매칭 + 친구 자동 등록
  ///
  /// POST /contacts/sync  { phoneHashes: [...] }
  /// 응답: { matched: number, friends: UserPublicProfile[] }
  ///
  /// 배치 크기: 100개씩 나눠서 전송 (서버 과부하 방지)
  /// 반환: (결과 목록, 실패한 배치 수)
  Future<({List<RingTalkContact> contacts, int failedBatches})> matchWithServer(
    List<ProcessedContact> processed,
  ) async {
    if (processed.isEmpty) {
      return (contacts: <RingTalkContact>[], failedBatches: 0);
    }

    const batchSize = 100;
    final matched = <String, UserPublicProfile>{};
    var failedBatches = 0;

    for (var i = 0; i < processed.length; i += batchSize) {
      final batch = processed.sublist(
        i,
        (i + batchSize).clamp(0, processed.length),
      );
      final hashes = batch.map((c) => c.phoneHash).toList();

      try {
        final res = await apiClient.post(
          ApiEndpoints.contactsSync,
          data: {'phoneHashes': hashes},
        );

        final friends = (res.data['data']?['friends'] as List<dynamic>?)
                ?.map((e) => UserPublicProfile.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];

        for (final user in friends) {
          if (user.phoneHash != null) {
            matched[user.phoneHash!] = user;
          }
        }
      } catch (e) {
        failedBatches++;
        debugPrint('[ContactsRepo] 배치 $i 동기화 실패: $e');
      }
    }

    final List<RingTalkContact> contacts = processed
        .map((contact) => RingTalkContact(
              local: contact,
              profile: matched[contact.phoneHash],
            ))
        .toList();

    return (contacts: contacts, failedBatches: failedBatches);
  }

  // ─── 전체 파이프라인 ─────────────────────────────────────────────────────────

  /// 권한 확인 → 연락처 가져오기 → 정규화 → 해시 → 서버 매칭
  ///
  /// [onProgress] : 진행 상태 콜백
  Future<ContactSyncResult> syncContacts({
    void Function(ContactSyncStatus)? onProgress,
  }) async {
    // 웹/미지원 플랫폼
    if (kIsWeb) {
      return const ContactSyncResult(status: ContactSyncStatus.unsupported);
    }

    // 1. 권한 확인
    onProgress?.call(ContactSyncStatus.requestingPermission);
    var status = await requestContactPermission();

    if (status == ph.PermissionStatus.permanentlyDenied) {
      return const ContactSyncResult(
        status: ContactSyncStatus.permissionPermanentlyDenied,
      );
    }
    if (!status.isGranted) {
      return const ContactSyncResult(status: ContactSyncStatus.permissionDenied);
    }

    // 2. 연락처 가져오기
    onProgress?.call(ContactSyncStatus.fetchingContacts);
    final rawContacts = await fetchDeviceContacts();

    // 3. 정규화 + 해시
    onProgress?.call(ContactSyncStatus.processing);
    final processed = processContacts(rawContacts);

    if (processed.isEmpty) {
      return ContactSyncResult(
        status: ContactSyncStatus.done,
        totalContacts: rawContacts.length,
      );
    }

    // 4. 서버 매칭
    onProgress?.call(ContactSyncStatus.syncing);
    final matchResult = await matchWithServer(processed);

    final matched = matchResult.contacts.where((c) => c.isOnRingTalk).length;

    if (matchResult.failedBatches > 0) {
      return ContactSyncResult(
        status: ContactSyncStatus.done,
        contacts: matchResult.contacts,
        totalContacts: processed.length,
        matchedCount: matched,
        errorMessage:
            '일부 배치 동기화 실패 (${matchResult.failedBatches}건). 결과는 부분 반영되었습니다.',
      );
    }

    return ContactSyncResult(
      status: ContactSyncStatus.done,
      contacts: matchResult.contacts,
      totalContacts: processed.length,
      matchedCount: matched,
    );
  }
}
