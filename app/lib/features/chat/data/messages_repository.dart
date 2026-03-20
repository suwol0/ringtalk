// 메시지 API
//
// GET /chats/:id/messages — 메시지 목록 (cursor, limit)

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/network/api_client.dart';

class MessagesRepository {
  Future<({List<Message> messages, String? nextCursor})> fetchMessages(
    String roomId, {
    String? cursor,
    int limit = 50,
  }) async {
    try {
      final query = cursor != null ? '?cursor=$cursor&limit=$limit' : '?limit=$limit';
      final res = await apiClient.get('${ApiEndpoints.chatMessages(roomId)}$query');

      final data = res.data['data'] ?? res.data;
      final list = (data['messages'] as List<dynamic>?) ?? [];
      final nextCursor = data['nextCursor'] as String?;

      final messages = list
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();

      return (messages: messages, nextCursor: nextCursor);
    } catch (e) {
      debugPrint('[MessagesRepo] GET /chats/:id/messages 실패: $e');
      rethrow;
    }
  }
}
