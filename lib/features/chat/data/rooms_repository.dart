// 채팅방 저장소
//
// ─── 사용하는 API ─────────────────────────────────────────────────────────────
//
// GET /chats
//   - 인증: JWT
//   - 응답: ChatRoom[] (participants, lastMessage, unreadCount 포함)
//
// POST /chats/direct
//   - body: { participantId: string }
//   - 1:1 방 생성 또는 기존 방 반환
//

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/network/api_client.dart';

class RoomsRepository {
  /// 채팅 목록 조회
  /// API: GET /chats
  Future<List<ChatRoom>> fetchRooms() async {
    try {
      final res = await apiClient.get(ApiEndpoints.chats);

      final list = res.data is List
          ? res.data as List<dynamic>
          : (res.data['data'] ?? res.data) as List<dynamic>?;

      if (list == null || list.isEmpty) return [];

      return list
          .map((e) => ChatRoom.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[RoomsRepo] GET /chats 실패: $e');
      rethrow;
    }
  }

  /// 1:1 채팅방 생성 또는 기존 방 반환
  /// API: POST /chats/direct
  Future<ChatRoom> createDirectRoom(String participantId) async {
    try {
      final res = await apiClient.post(
        ApiEndpoints.chatsDirect,
        data: {'participantId': participantId},
      );

      final data = res.data is Map ? res.data as Map<String, dynamic> : res.data['data'] as Map<String, dynamic>;
      return ChatRoom.fromJson(data);
    } catch (e) {
      debugPrint('[RoomsRepo] POST /chats/direct 실패: $e');
      rethrow;
    }
  }
}
