// 친구 목록 저장소
//
// ─── 사용하는 API ─────────────────────────────────────────────────────────────
//
// GET /users/me/friends
//   - 인증: JWT (Authorization: Bearer <accessToken>)
//   - 헤더: X-Device-Id (선택)
//   - 응답: 200 OK
//     [
//       {
//         "id": "uuid",
//         "displayName": "별명 또는 원래 이름",
//         "profileImageUrl": "https://...",
//         "statusMessage": "상태 메시지",
//         "phoneHash": "sha256...",
//         "alias": "내가 설정한 별명",
//         "friendedAt": "2025-03-10T00:00:00.000Z"
//       }
//     ]
//
// ─── 참고 ─────────────────────────────────────────────────────────────────────
// - 친구 목록은 연락처 동기화(POST /contacts/sync)로도 갱신됨
// - 서버 친구 = status: 'accepted' 인 Friend 관계
// - displayName은 alias ?? friend.displayName (별명 우선)
//

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/contact_model.dart';
import '../../../core/network/api_client.dart';

class FriendsRepository {
  /// 서버에서 수락된 친구 목록 조회
  ///
  /// API: GET /users/me/friends
  /// 반환: RingTalkContact[] (서버 응답을 RingTalkContact로 변환)
  Future<List<RingTalkContact>> fetchFriends() async {
    try {
      final res = await apiClient.get(ApiEndpoints.friends);

      // 응답 형식: { data: [...] } 또는 직접 배열
      final list = res.data is List
          ? res.data as List<dynamic>
          : (res.data['data'] ?? res.data) as List<dynamic>?;

      if (list == null || list.isEmpty) return [];

      return list
          .map((e) => RingTalkContact.fromServerFriend(
                e as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      debugPrint('[FriendsRepo] GET /friends 실패: $e');
      rethrow;
    }
  }

  /// 친구 차단
  /// API: POST /users/:id/block
  Future<void> blockUser(String userId) async {
    await apiClient.post(ApiEndpoints.blockUser(userId));
  }
}
