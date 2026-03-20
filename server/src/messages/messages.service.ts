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

@Injectable()
export class MessagesService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * 메시지 저장 (message:send 이벤트)
   */
  async sendMessage(senderId: string, payload: SendMessagePayload) {
    const { roomId, clientMessageId, content, type = 'text', mediaUrl, replyToId } = payload;

    if (!content?.trim()) {
      throw new ForbiddenException({
        code: ErrorCode.VALIDATION_ERROR,
        message: '메시지 내용이 비어 있습니다.',
      });
    }

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
    const room = await this.prisma.chatRoom.findUnique({
      where: { id: roomId },
    });

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
        sender: {
          select: {
            id: true,
            displayName: true,
            profileImageUrl: true,
          },
        },
      },
    });
    if (existing) {
      return {
        message: this._formatMessage(existing),
        clientMessageId,
      };
    }

    const message = await this.prisma.message.create({
      data: {
        roomId,
        senderId,
        clientMessageId,
        type: type as any,
        content: content.trim(),
        mediaUrl: mediaUrl ?? null,
        replyToId: replyToId ?? null,
      },
      include: {
        sender: {
          select: {
            id: true,
            displayName: true,
            profileImageUrl: true,
          },
        },
      },
    });

    // ChatRoom updatedAt 갱신
    await this.prisma.chatRoom.update({
      where: { id: roomId },
      data: { updatedAt: new Date() },
    });

    return {
      message: this._formatMessage(message),
      clientMessageId,
    };
  }

  /**
   * 방의 메시지 목록 조회 (페이지네이션)
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

    const messages = await this.prisma.message.findMany({
      where: { roomId },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
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
      },
    });

    const hasMore = messages.length > limit;
    const items = hasMore ? messages.slice(0, limit) : messages;

    return {
      messages: items.map((m: (typeof items)[number]) => this._formatMessage(m)),
      nextCursor: hasMore ? items[items.length - 1].id : null,
    };
  }

  /**
   * 읽음 처리 (chat.read 이벤트)
   * - lastReadMessageId 기준: 해당 메시지까지만 읽음 처리 (없으면 전체)
   * - RoomParticipant.lastReadAt 갱신
   * - 내가 읽지 않은 메시지에 MessageReadReceipt upsert
   * - 읽힌 메시지들의 senderId 목록 반환 (발신자에게 알림 전송용)
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

    // lastReadMessageId 기준 메시지의 createdAt 조회
    let readUntil: Date = new Date();
    let resolvedLastReadMessageId = lastReadMessageId;

    if (lastReadMessageId) {
      const targetMessage = await this.prisma.message.findFirst({
        where: { id: lastReadMessageId, roomId },
        select: { id: true, createdAt: true },
      });
      if (targetMessage) {
        readUntil = targetMessage.createdAt;
        resolvedLastReadMessageId = targetMessage.id;
      }
    }

    const readAt = new Date();

    // lastReadAt 갱신
    await this.prisma.roomParticipant.update({
      where: { roomId_userId: { roomId, userId } },
      data: { lastReadAt: readUntil },
    });

    // 내가 보내지 않은 메시지 중 readUntil 이전이며 readReceipt 없는 것들 조회
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
        data: unreadMessages.map((m) => ({
          messageId: m.id,
          userId,
          readAt,
        })),
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
      mediaUrl: msg.mediaUrl,
      replyToId: msg.replyToId,
      isDeleted: msg.isDeleted,
      deletedFor: msg.deletedFor,
      createdAt: msg.createdAt,
      updatedAt: msg.updatedAt,
      status: 'sent',
      readBy: [] as { userId: string; readAt: string }[],
    };
  }
}
