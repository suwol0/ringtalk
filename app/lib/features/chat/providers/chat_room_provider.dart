import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/network/socket_provider.dart';
import '../../../core/storage/auth_storage.dart';
import '../data/messages_repository.dart';
import 'rooms_provider.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((_) => MessagesRepository());

/// 전송 실패 타임아웃
const _sendTimeoutDuration = Duration(seconds: 10);

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

  /// clientTempId → 전송 타임아웃 타이머
  final Map<String, Timer> _sendTimers = {};

  /// 소켓 연결 대기 콜백 (race condition 방지)
  VoidCallback? _onConnectRetry;

  ChatRoomNotifier(this._ref, this.roomId) : super(const ChatRoomState()) {
    loadMessages();
    _subscribeToSocket();
  }

  // ─── 메시지 로드 ─────────────────────────────────────────────

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = _ref.read(messagesRepositoryProvider);
      final result = await repo.fetchMessages(roomId);
      if (!mounted) return;
      state = state.copyWith(messages: result.messages, isLoading: false);

      _emitMarkRead();
      _ref.read(roomsProvider.notifier).markRoomAsRead(roomId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // ─── 읽음 처리 ───────────────────────────────────────────────

  void _emitMarkRead() {
    final socket = _ref.read(socketServiceProvider).socket;
    if (socket == null) return;
    final lastMessage = state.messages.isNotEmpty ? state.messages.last : null;
    socket.emit(WsEvents.chatRead, {
      'roomId': roomId,
      if (lastMessage != null) 'lastReadMessageId': lastMessage.id,
    });
  }

  void markRead() => _emitMarkRead();

  // ─── 소켓 이벤트 구독 ────────────────────────────────────────

  void _subscribeToSocket() {
    final socketService = _ref.read(socketServiceProvider);
    final socket = socketService.socket;

    // 소켓이 아직 연결되지 않았으면 onConnect 콜백으로 재시도
    if (socket == null || !socketService.isConnected) {
      _onConnectRetry = () {
        if (!mounted) return;
        socketService.removeOnConnectCallback(_onConnectRetry!);
        _onConnectRetry = null;
        _subscribeToSocket();
      };
      socketService.addOnConnectCallback(_onConnectRetry!);
      return;
    }

    socket.emit(WsEvents.roomJoin, {'roomId': roomId});

    // message:new
    _messageNewHandler = (data) {
      if (data is! Map) return;
      final msgMap = data['message'] as Map<String, dynamic>?;
      if (msgMap == null || (msgMap['roomId'] as String?) != roomId) return;

      final msg = Message.fromJson(msgMap);
      final clientMessageId = data['clientMessageId'] as String?;

      AuthStorage.getUserId().then((myUserId) {
        if (!mounted) return;
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

        if (state.messages.any((m) => m.id == msg.id)) return;

        state = state.copyWith(
          messages: [...state.messages, msg]
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
        );

        if (!isFromMe) {
          // 클로저에 캡처된 오래된 socket 대신 현재 소켓 사용 (재연결 대비)
          _ref.read(socketServiceProvider).socket?.emit(
            WsEvents.messageDelivered,
            {'messageId': msg.id, 'roomId': roomId},
          );
          _emitMarkRead();
        }
      });
    };
    socket.on(WsEvents.messageNew, _messageNewHandler!);

    // message:status
    _messageStatusHandler = (data) {
      if (data is! Map) return;
      final status = data['status'] as String?;
      final messageId = data['messageId'] as String?;
      final clientMessageId = data['clientMessageId'] as String?;

      if (status == 'sent' && clientMessageId != null) {
        _cancelSendTimer(clientMessageId);
        if (!mounted) return;
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.clientTempId == clientMessageId) {
              return m.copyWith(id: messageId ?? m.id, status: MessageStatus.sent);
            }
            return m;
          }).toList(),
        );
      }

      if (status == 'delivered' && messageId != null) {
        if (!mounted) return;
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id == messageId && m.status != MessageStatus.read) {
              return m.copyWith(status: MessageStatus.delivered);
            }
            return m;
          }).toList(),
        );
      }
    };
    socket.on(WsEvents.messageStatus, _messageStatusHandler!);

    // chat.read: 상대방이 읽었을 때 → 내 메시지 read 처리
    _chatReadHandler = (data) {
      if (data is! Map) return;
      final payload = WsChatRead.fromJson(Map<String, dynamic>.from(data));
      if (payload.roomId != roomId) return;

      AuthStorage.getUserId().then((myUserId) {
        if (!mounted) return;
        if (myUserId == null || payload.userId == myUserId) return;

        final receipt = MessageReadReceipt(userId: payload.userId, readAt: payload.readAt);

        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.senderId != myUserId) return m;
            if (m.createdAt.isAfter(payload.readAt)) return m;
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

  // ─── 메시지 전송 ─────────────────────────────────────────────

  Future<void> sendMessage(String content, {String type = 'text'}) async {
    final trimmed = type == 'text' ? content.trim() : content;
    if (trimmed.isEmpty) return;

    final clientMessageId = const Uuid().v4();
    final now = DateTime.now();
    final myUserId = await AuthStorage.getUserId();
    if (!mounted) return;

    final msgType = type == 'image'
        ? MessageType.image
        : type == 'file'
            ? MessageType.file
            : MessageType.text;

    if (myUserId != null) {
      state = state.copyWith(
        messages: [
          ...state.messages,
          Message(
            id: clientMessageId,
            roomId: roomId,
            senderId: myUserId,
            type: msgType,
            content: trimmed,
            status: MessageStatus.sending,
            readBy: [],
            isDeleted: false,
            deletedFor: DeleteScope.none,
            createdAt: now,
            updatedAt: now,
            clientTempId: clientMessageId,
          ),
        ],
      );
    }

    final socket = _ref.read(socketServiceProvider).socket;
    if (socket == null) {
      _markAsFailed(clientMessageId);
      return;
    }

    socket.emit(WsEvents.messageSend, {
      'roomId': roomId,
      'clientMessageId': clientMessageId,
      'content': trimmed,
      'type': type,
    });

    _startSendTimer(clientMessageId, trimmed);
  }

  Future<void> retryMessage(String clientTempId) async {
    final msg = state.messages.firstWhere(
      (m) => m.clientTempId == clientTempId,
      orElse: () => throw StateError('메시지를 찾을 수 없습니다.'),
    );

    if (!mounted) return;
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.clientTempId != clientTempId) return m;
        return m.copyWith(status: MessageStatus.sending);
      }).toList(),
    );

    final socket = _ref.read(socketServiceProvider).socket;
    if (socket == null) {
      _markAsFailed(clientTempId);
      return;
    }

    socket.emit(WsEvents.messageSend, {
      'roomId': roomId,
      'clientMessageId': clientTempId,
      'content': msg.content,
      'type': 'text',
    });

    _startSendTimer(clientTempId, msg.content);
  }

  // ─── 타이머 헬퍼 ─────────────────────────────────────────────

  void _startSendTimer(String clientTempId, String content) {
    _cancelSendTimer(clientTempId);
    _sendTimers[clientTempId] = Timer(_sendTimeoutDuration, () => _markAsFailed(clientTempId));
  }

  void _cancelSendTimer(String clientTempId) {
    _sendTimers.remove(clientTempId)?.cancel();
  }

  void _markAsFailed(String clientTempId) {
    _cancelSendTimer(clientTempId);
    if (!mounted) return;
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.clientTempId == clientTempId) {
          return m.copyWith(status: MessageStatus.failed);
        }
        return m;
      }).toList(),
    );
  }

  // ─── dispose ─────────────────────────────────────────────────

  @override
  void dispose() {
    for (final timer in _sendTimers.values) {
      timer.cancel();
    }
    _sendTimers.clear();

    final socketService = _ref.read(socketServiceProvider);
    if (_onConnectRetry != null) {
      socketService.removeOnConnectCallback(_onConnectRetry!);
      _onConnectRetry = null;
    }

    final socket = socketService.socket;
    if (socket != null) {
      if (_messageNewHandler != null) socket.off(WsEvents.messageNew, _messageNewHandler!);
      if (_messageStatusHandler != null) socket.off(WsEvents.messageStatus, _messageStatusHandler!);
      if (_chatReadHandler != null) socket.off(WsEvents.chatRead, _chatReadHandler!);
      socket.emit(WsEvents.roomLeave, {'roomId': roomId});
    }
    super.dispose();
  }
}

final chatRoomProvider = StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, String>(
  (ref, roomId) => ChatRoomNotifier(ref, roomId),
);
