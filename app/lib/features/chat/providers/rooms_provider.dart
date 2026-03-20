import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/chat_model.dart';
import '../../../core/network/socket_provider.dart';
import '../../../core/storage/auth_storage.dart';
import '../data/rooms_repository.dart';

final roomsRepositoryProvider = Provider<RoomsRepository>((_) => RoomsRepository());

enum RoomsLoadStatus { idle, loading, done, error }

class RoomsState {
  final RoomsLoadStatus status;
  final List<ChatRoom> rooms;
  final String? errorMessage;

  const RoomsState({
    this.status = RoomsLoadStatus.idle,
    this.rooms = const [],
    this.errorMessage,
  });

  RoomsState copyWith({
    RoomsLoadStatus? status,
    List<ChatRoom>? rooms,
    Object? errorMessage = _undefined,
  }) =>
      RoomsState(
        status: status ?? this.status,
        rooms: rooms ?? this.rooms,
        errorMessage: identical(errorMessage, _undefined) ? this.errorMessage : errorMessage as String?,
      );
}

const _undefined = Object();

class RoomsNotifier extends StateNotifier<RoomsState> {
  final Ref _ref;
  void Function(dynamic)? _messageNewHandler;

  /// 소켓 연결 대기 콜백 (race condition 방지)
  VoidCallback? _onConnectRetry;

  RoomsNotifier(this._ref) : super(const RoomsState()) {
    _subscribeToSocket();
  }

  // ─── 소켓 구독 (채팅 목록 실시간 업데이트) ───────────────────

  void _subscribeToSocket() {
    final socketService = _ref.read(socketServiceProvider);
    final socket = socketService.socket;

    // 소켓 미연결 시 onConnect 콜백으로 재시도
    if (socket == null) {
      _onConnectRetry = () {
        if (!mounted) return;
        socketService.removeOnConnectCallback(_onConnectRetry!);
        _onConnectRetry = null;
        _subscribeToSocket();
      };
      socketService.addOnConnectCallback(_onConnectRetry!);
      return;
    }

    _messageNewHandler = (data) {
      if (data is! Map) return;
      final msgMap = data['message'] as Map<String, dynamic>?;
      if (msgMap == null) return;

      final msg = Message.fromJson(msgMap);

      AuthStorage.getUserId().then((myUserId) {
        if (!mounted) return;

        final idx = state.rooms.indexWhere((r) => r.id == msg.roomId);
        if (idx < 0) return;

        final room = state.rooms[idx];
        final isFromMe = myUserId != null && msg.senderId == myUserId;

        final updatedRoom = ChatRoom(
          id: room.id,
          type: room.type,
          name: room.name,
          profileImageUrl: room.profileImageUrl,
          participants: room.participants,
          lastMessage: msg,
          // 내가 보낸 메시지이거나 이미 0이면 unreadCount 유지
          unreadCount: isFromMe ? room.unreadCount : room.unreadCount + 1,
          createdAt: room.createdAt,
          updatedAt: DateTime.now(),
        );

        // 최신 메시지 순서로 정렬
        final updatedRooms = [
          updatedRoom,
          ...state.rooms.where((r) => r.id != msg.roomId),
        ];

        state = state.copyWith(rooms: updatedRooms);
      });
    };
    socket.on(WsEvents.messageNew, _messageNewHandler!);
  }

  // ─── 채팅 목록 조회 ──────────────────────────────────────────

  Future<void> fetchRooms() async {
    state = state.copyWith(status: RoomsLoadStatus.loading);
    try {
      final repo = _ref.read(roomsRepositoryProvider);
      final rooms = await repo.fetchRooms();
      if (!mounted) return;
      state = state.copyWith(status: RoomsLoadStatus.done, rooms: rooms);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(status: RoomsLoadStatus.error, errorMessage: e.toString());
    }
  }

  /// 채팅방 진입 시 unreadCount 즉시 0으로 초기화 (낙관적 업데이트)
  void markRoomAsRead(String roomId) {
    state = state.copyWith(
      rooms: state.rooms.map((r) {
        if (r.id != roomId) return r;
        return ChatRoom(
          id: r.id,
          type: r.type,
          name: r.name,
          profileImageUrl: r.profileImageUrl,
          participants: r.participants,
          lastMessage: r.lastMessage,
          unreadCount: 0,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        );
      }).toList(),
    );
  }

  /// 1:1 방 생성/조회 후 반환
  Future<ChatRoom?> getOrCreateDirectRoom(String participantId) async {
    try {
      final repo = _ref.read(roomsRepositoryProvider);
      final room = await repo.createDirectRoom(participantId);
      if (!mounted) return null;
      final exists = state.rooms.any((r) => r.id == room.id);
      if (!exists) {
        state = state.copyWith(rooms: [room, ...state.rooms]);
      }
      return room;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(status: RoomsLoadStatus.error, errorMessage: e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    final socketService = _ref.read(socketServiceProvider);
    if (_onConnectRetry != null) {
      socketService.removeOnConnectCallback(_onConnectRetry!);
      _onConnectRetry = null;
    }
    final socket = socketService.socket;
    if (socket != null && _messageNewHandler != null) {
      socket.off(WsEvents.messageNew, _messageNewHandler!);
    }
    super.dispose();
  }
}

final roomsProvider = StateNotifierProvider<RoomsNotifier, RoomsState>(
  (ref) => RoomsNotifier(ref),
);
