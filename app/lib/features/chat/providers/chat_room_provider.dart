import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/network/socket_provider.dart';
import '../../../core/storage/auth_storage.dart';
import '../data/messages_repository.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((_) => MessagesRepository());

/// 채팅방 메시지 상태 (실시간 업데이트 포함)
class ChatRoomState {
  final List<Message> messages;
  final bool isLoading;
  final String? errorMessage;

  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  ChatRoomState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? errorMessage,
  }) =>
      ChatRoomState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final Ref _ref;
  final String roomId;
  void Function(dynamic)? _messageNewHandler;
  void Function(dynamic)? _messageStatusHandler;
  void Function(dynamic)? _chatReadHandler;

  ChatRoomNotifier(this._ref, this.roomId) : super(const ChatRoomState()) {
    loadMessages();
    _subscribeToNewMessages();
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(messagesRepositoryProvider);
      final result = await repo.fetchMessages(roomId);
      state = state.copyWith(messages: result.messages, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void _subscribeToNewMessages() {
    final socket = _ref.read(socketServiceProvider).socket;
    if (socket == null) return;

    socket.emit(WsEvents.roomJoin, {'roomId': roomId});

    // 채팅방 진입 시 읽음 처리
    socket.emit(WsEvents.chatRead, {'roomId': roomId});

    _messageNewHandler = (data) {
      if (data is! Map) return;
      final msgMap = data['message'] as Map<String, dynamic>?;
      if (msgMap == null || (msgMap['roomId'] as String?) != roomId) return;

      final msg = Message.fromJson(msgMap);
      final clientMessageId = data['clientMessageId'] as String?;

      AuthStorage.getUserId().then((myUserId) {
        // 발신자가 나이고 clientMessageId가 있으면 → 낙관적 업데이트 메시지 교체
        final isFromMe = myUserId != null && msg.senderId == myUserId;
        if (isFromMe && clientMessageId != null) {
          final idx = state.messages.indexWhere((m) => m.clientTempId == clientMessageId);
          if (idx >= 0) {
            state = state.copyWith(
              messages: state.messages
                  .asMap()
                  .entries
                  .map((e) => e.key == idx ? msg : e.value)
                  .toList()
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
            );
            return;
          }
        }

        // 중복 방지: 이미 동일 id가 있으면 스킵
        if (state.messages.any((m) => m.id == msg.id)) return;

        state = state.copyWith(
          messages: [...state.messages, msg]..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        );

        // delivered 상태 전송: 상대방 메시지 수신 시 서버에 알림
        if (!isFromMe) {
          socket.emit(WsEvents.messageDelivered, {
            'messageId': msg.id,
            'roomId': roomId,
          });
        }
      });
    };
    socket.on(WsEvents.messageNew, _messageNewHandler!);

    _messageStatusHandler = (data) {
      if (data is! Map) return;
      final status = data['status'] as String?;
      final messageId = data['messageId'] as String?;
      if (status == 'delivered' && messageId != null) {
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id == messageId) {
              return m.copyWith(status: MessageStatus.delivered);
            }
            return m;
          }).toList(),
        );
      }
    };
    socket.on(WsEvents.messageStatus, _messageStatusHandler!);

    // chat.read: 상대방이 읽었을 때 → 내가 보낸 메시지를 read 상태로 업데이트
    _chatReadHandler = (data) {
      if (data is! Map) return;
      final payload = WsChatRead.fromJson(Map<String, dynamic>.from(data));
      if (payload.roomId != roomId) return;

      AuthStorage.getUserId().then((myUserId) {
        if (myUserId == null || payload.userId == myUserId) return;

        final receipt = MessageReadReceipt(
          userId: payload.userId,
          readAt: payload.readAt,
        );

        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.senderId != myUserId) return m;
            // readAt 이전에 생성된 내 메시지 → read 처리
            if (!m.createdAt.isBefore(payload.readAt)) return m;
            // 이미 해당 userId의 읽음이 있으면 스킵
            if (m.readBy.any((r) => r.userId == payload.userId)) return m;

            return m.copyWith(
              status: MessageStatus.read,
              readBy: [...m.readBy, receipt],
            );
          }).toList(),
        );
      });
    };
    socket.on(WsEvents.chatRead, _chatReadHandler!);
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final clientMessageId = const Uuid().v4();
    final optimistic = Message(
      id: clientMessageId,
      roomId: roomId,
      senderId: '', // will be set by myUserId
      type: MessageType.text,
      content: content.trim(),
      status: MessageStatus.sending,
      readBy: [],
      isDeleted: false,
      deletedFor: DeleteScope.none,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      clientTempId: clientMessageId,
    );

    final myUserId = await AuthStorage.getUserId();
    if (myUserId != null) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          Message(
            id: clientMessageId,
            roomId: roomId,
            senderId: myUserId,
            type: MessageType.text,
            content: content.trim(),
            status: MessageStatus.sending,
            readBy: [],
            isDeleted: false,
            deletedFor: DeleteScope.none,
            createdAt: optimistic.createdAt,
            updatedAt: optimistic.updatedAt,
            clientTempId: clientMessageId,
          ),
        ],
      );
    }

    final socket = _ref.read(socketServiceProvider).socket;
    if (socket == null) {
      state = state.copyWith(errorMessage: 'Socket 연결이 없습니다.');
      return;
    }

    socket.emit(WsEvents.messageSend, {
      'roomId': roomId,
      'clientMessageId': clientMessageId,
      'content': content.trim(),
      'type': 'text',
    });

    void sentHandler(dynamic data) {
      if (data is Map && data['clientMessageId'] == clientMessageId) {
        socket.off(WsEvents.messageStatus, sentHandler);
        final messageId = data['messageId'] as String?;
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.clientTempId == clientMessageId) {
              return m.copyWith(
                id: messageId ?? m.id,
                status: MessageStatus.sent,
              );
            }
            return m;
          }).toList(),
        );
      }
    }
    socket.on(WsEvents.messageStatus, sentHandler);
  }

  @override
  void dispose() {
    final socket = _ref.read(socketServiceProvider).socket;
    if (socket != null) {
      if (_messageNewHandler != null) socket.off(WsEvents.messageNew, _messageNewHandler!);
      if (_messageStatusHandler != null) socket.off(WsEvents.messageStatus, _messageStatusHandler!);
      if (_chatReadHandler != null) socket.off(WsEvents.chatRead, _chatReadHandler!);
      socket.emit(WsEvents.roomLeave, {'roomId': roomId});
    }
    super.dispose();
  }
}

final chatRoomProvider = StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, String>((ref, roomId) {
  return ChatRoomNotifier(ref, roomId);
});
