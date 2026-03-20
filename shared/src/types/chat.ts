// 채팅 관련 타입 정의

export type RoomType = 'direct' | 'group';
export type MessageType = 'text' | 'image' | 'video' | 'file' | 'audio' | 'system';
export type MessageStatus = 'sending' | 'sent' | 'delivered' | 'read' | 'failed';

export interface ChatRoom {
  id: string;
  type: RoomType;
  name?: string; // 그룹방만
  profileImageUrl?: string;
  participants: RoomParticipant[];
  lastMessage?: Message;
  unreadCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface RoomParticipant {
  userId: string;
  role: 'owner' | 'admin' | 'member';
  joinedAt: string;
  lastReadAt?: string;
  isMuted: boolean;
  user: import('./user').UserPublicProfile;
}

export interface Message {
  id: string;
  roomId: string;
  senderId: string;
  type: MessageType;
  content: string;
  mediaUrl?: string;
  status: MessageStatus;
  readBy: MessageReadReceipt[];
  replyTo?: string; // 답장 메시지 ID
  isDeleted: boolean;
  deletedFor: 'none' | 'me' | 'all';
  createdAt: string;
  updatedAt: string;
}

export interface MessageReadReceipt {
  userId: string;
  readAt: string;
}

export interface SendMessageDto {
  roomId: string;
  type: MessageType;
  content: string;
  mediaUrl?: string;
  replyTo?: string;
  clientTempId: string; // 낙관적 업데이트용 임시 ID
}

export interface CreateDirectRoomDto {
  participantId: string;
}

export interface CreateGroupRoomDto {
  name: string;
  participantIds: string[];
}

// WebSocket 이벤트 타입
export type WsEvent =
  | 'message:new'
  | 'message:status'
  | 'message:deleted'
  | 'room:updated'
  | 'user:typing'
  | 'user:presence'
  | 'user:read';

export interface WsPayload<T = unknown> {
  event: WsEvent;
  data: T;
}
