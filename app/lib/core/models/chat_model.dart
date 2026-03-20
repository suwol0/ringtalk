// 채팅 관련 Dart 모델

import 'user_model.dart';

enum RoomType { direct, group }

enum MessageType { text, image, video, file, audio, system }

enum MessageStatus { sending, sent, delivered, read, failed }

enum DeleteScope { none, me, all }

class ChatRoom {
  final String id;
  final RoomType type;
  final String? name;
  final String? profileImageUrl;
  final List<RoomParticipant> participants;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatRoom({
    required this.id,
    required this.type,
    this.name,
    this.profileImageUrl,
    required this.participants,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) => ChatRoom(
        id: json['id'] as String,
        type: RoomType.values.byName(json['type'] as String),
        name: json['name'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
        participants: (json['participants'] as List<dynamic>)
            .map((e) => RoomParticipant.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastMessage: json['lastMessage'] != null
            ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
            : null,
        unreadCount: json['unreadCount'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// 1:1 채팅방에서 상대방 프로필
  UserPublicProfile? otherUser(String myUserId) {
    final other = participants.where((p) => p.userId != myUserId).firstOrNull;
    return other?.user;
  }

  String displayName(String myUserId) {
    if (type == RoomType.group) return name ?? '그룹 채팅';
    return otherUser(myUserId)?.displayName ?? '알 수 없음';
  }
}

class RoomParticipant {
  final String userId;
  final String role;
  final DateTime joinedAt;
  final DateTime? lastReadAt;
  final bool isMuted;
  final UserPublicProfile user;

  const RoomParticipant({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.lastReadAt,
    required this.isMuted,
    required this.user,
  });

  factory RoomParticipant.fromJson(Map<String, dynamic> json) => RoomParticipant(
        userId: json['userId'] as String,
        role: json['role'] as String,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
        lastReadAt: json['lastReadAt'] != null
            ? DateTime.parse(json['lastReadAt'] as String)
            : null,
        isMuted: json['isMuted'] as bool? ?? false,
        user: UserPublicProfile.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class Message {
  final String id;
  final String roomId;
  final String senderId;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final MessageStatus status;
  final List<MessageReadReceipt> readBy;
  final String? replyToId;
  final bool isDeleted;
  final DeleteScope deletedFor;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 낙관적 업데이트용 임시 클라이언트 ID
  final String? clientTempId;

  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.type,
    required this.content,
    this.mediaUrl,
    required this.status,
    required this.readBy,
    this.replyToId,
    required this.isDeleted,
    required this.deletedFor,
    required this.createdAt,
    required this.updatedAt,
    this.clientTempId,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        roomId: json['roomId'] as String,
        senderId: json['senderId'] as String,
        type: MessageType.values.byName(json['type'] as String? ?? 'text'),
        content: json['content'] as String,
        mediaUrl: json['mediaUrl'] as String?,
        status: MessageStatus.values.byName(json['status'] as String? ?? 'sent'),
        readBy: (json['readBy'] as List<dynamic>? ?? [])
            .map((e) => MessageReadReceipt.fromJson(e as Map<String, dynamic>))
            .toList(),
        replyToId: json['replyToId'] as String?,
        isDeleted: json['isDeleted'] as bool? ?? false,
        deletedFor: DeleteScope.values.byName(json['deletedFor'] as String? ?? 'none'),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        clientTempId: json['clientTempId'] as String?,
      );

  Message copyWith({
    String? id,
    MessageStatus? status,
    List<MessageReadReceipt>? readBy,
    String? clientTempId,
  }) =>
      Message(
        id: id ?? this.id,
        roomId: roomId,
        senderId: senderId,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        status: status ?? this.status,
        readBy: readBy ?? this.readBy,
        replyToId: replyToId,
        isDeleted: isDeleted,
        deletedFor: deletedFor,
        createdAt: createdAt,
        updatedAt: updatedAt,
        clientTempId: clientTempId ?? this.clientTempId,
      );
}

class MessageReadReceipt {
  final String userId;
  final DateTime readAt;

  const MessageReadReceipt({required this.userId, required this.readAt});

  factory MessageReadReceipt.fromJson(Map<String, dynamic> json) =>
      MessageReadReceipt(
        userId: json['userId'] as String,
        readAt: DateTime.parse(json['readAt'] as String),
      );
}

class SendMessageRequest {
  final String roomId;
  final MessageType type;
  final String content;
  final String? mediaUrl;
  final String? replyToId;
  final String clientTempId;

  const SendMessageRequest({
    required this.roomId,
    required this.type,
    required this.content,
    this.mediaUrl,
    this.replyToId,
    required this.clientTempId,
  });

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'type': type.name,
        'content': content,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (replyToId != null) 'replyToId': replyToId,
        'clientTempId': clientTempId,
      };
}

/// WebSocket 이벤트 페이로드
class WsMessageNew {
  final Message message;
  WsMessageNew({required this.message});
  factory WsMessageNew.fromJson(Map<String, dynamic> json) =>
      WsMessageNew(message: Message.fromJson(json['message'] as Map<String, dynamic>));
}

class WsMessageStatus {
  final String clientMessageId;
  final MessageStatus status;
  final String? messageId;

  WsMessageStatus({required this.clientMessageId, required this.status, this.messageId});

  factory WsMessageStatus.fromJson(Map<String, dynamic> json) => WsMessageStatus(
        clientMessageId: json['clientMessageId'] as String,
        status: MessageStatus.values.byName(json['status'] as String),
        messageId: json['messageId'] as String?,
      );
}

/// chat.read 이벤트 페이로드
class WsChatRead {
  final String roomId;
  final String userId;
  final DateTime readAt;

  WsChatRead({required this.roomId, required this.userId, required this.readAt});

  factory WsChatRead.fromJson(Map<String, dynamic> json) => WsChatRead(
        roomId: json['roomId'] as String,
        userId: json['userId'] as String,
        readAt: DateTime.parse(json['readAt'] as String),
      );
}

class WsUserTyping {
  final String roomId;
  final String userId;
  final bool isTyping;

  WsUserTyping({required this.roomId, required this.userId, required this.isTyping});

  factory WsUserTyping.fromJson(Map<String, dynamic> json) => WsUserTyping(
        roomId: json['roomId'] as String,
        userId: json['userId'] as String,
        isTyping: json['isTyping'] as bool? ?? false,
      );
}
