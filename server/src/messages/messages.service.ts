import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';
import { ErrorCode } from '@ringtalk/shared-server';

export interface SendMessagePayload {
  roomId: string;
  clientMessageId: string;
  type?: 'text' | 'image' | 'video' | 'file' | 'audio' | 'system';
  content: string;
  mediaUrl?: string;
  replyToId?: string;
}

const ALLOWED_MESSAGE_TYPES = ['text', 'image', 'video', 'file', 'audio', 'system'] as const;
type AllowedMessageType = (typeof ALLOWED_MESSAGE_TYPES)[number];

@Injectable()
export class MessagesService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * 메시지 저장 (message:send 이벤트)
   * - message.create + chatRoom.updatedAt 갱신을 트랜잭션으로 묶어 원자성 보장
   */
  async sendMessage(senderId: string, payload: SendMessagePayload) {
    const { roomId, clientMessageId, content, type = 'text', mediaUrl, replyToId } = payload;

    if (!content?.trim()) {
      throw new ForbiddenException({
        code: ErrorCode.VALIDATION_ERROR,
        message: '메시지 내용이 비어 있습니다.',
      });
    }

    // MessageType 화이트리스트 검증
    const safeType: AllowedMessageType = (ALLOWED_MESSAGE_TYPES as readonly string[]).includes(type)
      ? (type as AllowedMessageType)
      : 'text';

    // 텍스트 타입만 공백 제거 — URL(image/video/file)은 trim하면 안 됨
    const safeContent = safeType === 'text' ? content.trim() : content;

    // 참여자 확인
    const participation = await this.prisma.roomParticipant.findFirst({
      where: { roomId, userId: senderId, leftAt: null },
    });
    if (!participation) {
      throw new ForbiddenException({
        code: ErrorCode.NOT_ROOM_MEMBER,
        message: '채팅방에 참여하고 있지 않습니다.',
      });
    }

    // 방 존재 확인
    const room = await this.prisma.chatRoom.findUnique({ where: { id: roomId } });
    if (!room) {
      throw new ForbiddenException({
        code: ErrorCode.ROOM_NOT_FOUND,
        message: '채팅방을 찾을 수 없습니다.',
      });
    }

    // 멱등성: 동일 clientMessageId로 재전송 시 기존 메시지 반환
    const existing = await this.prisma.message.findFirst({
      where: { roomId, senderId, clientMessageId },
      include: {
        sender: { select: { id: true, displayName: true, profileImageUrl: true } },
        readReceipts: { select: { userId: true, readAt: true } },
      },
    });
    if (existing) {
      return { message: this._formatMessage(existing), clientMessageId };
    }

    // 메시지 생성 + 방 updatedAt 갱신을 하나의 트랜잭션으로
    const message = await this.prisma.$transaction(async (tx) => {
      const msg = await tx.message.create({
        data: {
          roomId,
          senderId,
          clientMessageId,
          type: safeType,
          content: safeContent,
          mediaUrl: mediaUrl ?? null,
          replyToId: replyToId ?? null,
        },
        include: {
          sender: { select: { id: true, displayName: true, profileImageUrl: true } },
          readReceipts: { select: { userId: true, readAt: true } },
        },
      });
      await tx.chatRoom.update({
        where: { id: roomId },
        data: { updatedAt: new Date() },
      });
      return msg;
    });

    return { message: this._formatMessage(message), clientMessageId };
  }

  /**
   * 방의 메시지 목록 조회 (페이지네이션)
   * - readReceipts 포함으로 클라이언트에서 readBy 바로 사용 가능
   */
  async getMessages(roomId: string, userId: string, cursor?: string, limit = 50) {
    const participation = await this.prisma.roomParticipant.findFirst({
      where: { roomId, userId, leftAt: null },
    });
    if (!participation) {
      throw new ForbiddenException({
        code: ErrorCode.NOT_ROOM_MEMBER,
        message: '채팅방에 참여하고 있지 않습니다.',
      });
    }

    const safeLimit = Math.min(Number.isFinite(limit) && limit > 0 ? limit : 50, 100);

    const messages = await this.prisma.message.findMany({
      where: { roomId },
      orderBy: { createdAt: 'desc' },
      take: safeLimit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      select: {
        id: true,
        roomId: true,
        senderId: true,
        type: true,
        content: true,
        mediaUrl: true,
        replyToId: true,
        isDeleted: true,
        deletedFor: true,
        createdAt: true,
        updatedAt: true,
        readReceipts: { select: { userId: true, readAt: true } },
      },
    });

    const hasMore = messages.length > safeLimit;
    const items = hasMore ? messages.slice(0, safeLimit) : messages;

    return {
      messages: items.map((m) => this._formatMessage(m)),
      nextCursor: hasMore ? items[items.length - 1].id : null,
    };
  }

  /**
   * 읽음 처리 (chat.read 이벤트)
   * - lastReadMessageId 기준: 해당 메시지까지만 읽음 처리
   * - 잘못된 lastReadMessageId → 해당 값 무시하고 현재 시각 기준으로 처리
   */
  async markRead(
    roomId: string,
    userId: string,
    lastReadMessageId?: string,
  ): Promise<{ readAt: Date; senderIds: string[]; lastReadMessageId?: string }> {
    const participation = await this.prisma.roomParticipant.findFirst({
      where: { roomId, userId, leftAt: null },
    });
    if (!participation) {
      throw new ForbiddenException({
        code: ErrorCode.NOT_ROOM_MEMBER,
        message: '채팅방에 참여하고 있지 않습니다.',
      });
    }

    let readUntil: Date = new Date();
    let resolvedLastReadMessageId: string | undefined = undefined;

    if (lastReadMessageId) {
      const targetMessage = await this.prisma.message.findFirst({
        where: { id: lastReadMessageId, roomId },
        select: { id: true, createdAt: true },
      });

      if (targetMessage) {
        readUntil = targetMessage.createdAt;
        resolvedLastReadMessageId = targetMessage.id;
      }
      // 잘못된 ID: readUntil은 new Date()로 유지되고 resolvedId는 undefined
      // → 이 경우 "방 전체" 읽음으로 처리
    }

    const readAt = new Date();

    await this.prisma.roomParticipant.update({
      where: { roomId_userId: { roomId, userId } },
      data: { lastReadAt: readUntil },
    });

    // 내가 보내지 않은 메시지 중 readUntil 이전이며 readReceipt 없는 것들
    const unreadMessages = await this.prisma.message.findMany({
      where: {
        roomId,
        senderId: { not: userId },
        createdAt: { lte: readUntil },
        readReceipts: { none: { userId } },
      },
      select: { id: true, senderId: true },
    });

    if (unreadMessages.length > 0) {
      await this.prisma.messageReadReceipt.createMany({
        data: unreadMessages.map((m) => ({ messageId: m.id, userId, readAt })),
        skipDuplicates: true,
      });
    }

    const senderIds = [...new Set(unreadMessages.map((m) => m.senderId))];
    return { readAt, senderIds, lastReadMessageId: resolvedLastReadMessageId };
  }

  private _formatMessage(msg: any) {
    return {
      id: msg.id,
      roomId: msg.roomId,
      senderId: msg.senderId,
      type: msg.type,
      content: msg.content,
      mediaUrl: msg.mediaUrl ?? null,
      replyToId: msg.replyToId ?? null,
      isDeleted: msg.isDeleted ?? false,
      deletedFor: msg.deletedFor ?? 'none',
      createdAt: msg.createdAt,
      updatedAt: msg.updatedAt,
      status: 'sent',
      readBy: (msg.readReceipts ?? []).map((r: any) => ({
        userId: r.userId,
        readAt: r.readAt,
      })),
    };
  }
}
