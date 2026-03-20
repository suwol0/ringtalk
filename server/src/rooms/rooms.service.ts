import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';
import { CreateDirectRoomDto } from './dto/create-direct-room.dto';
import { ErrorCode } from '@ringtalk/shared-server';

@Injectable()
export class RoomsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * 내가 참여한 채팅방 목록 (마지막 메시지 기준 내림차순)
   */
  async getRooms(userId: string) {
    const participations = await this.prisma.roomParticipant.findMany({
      where: { userId, leftAt: null },
      include: {
        room: {
          include: {
            participants: {
              where: { leftAt: null },
              include: {
                user: {
                  select: {
                    id: true,
                    displayName: true,
                    profileImageUrl: true,
                    statusMessage: true,
                  },
                },
              },
            },
            messages: {
              orderBy: { createdAt: 'desc' },
              take: 1,
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
            },
          },
        },
      },
      orderBy: { room: { updatedAt: 'desc' } },
    });

    return participations.map((p: (typeof participations)[number]) => {
      const room = p.room;
      const lastMessage = room.messages[0] ?? null;
      const lastReadAt = p.lastReadAt;

      // unreadCount: lastReadAt 이후 메시지 수 (근사: 마지막 메시지가 안 읽었으면 1+)
      const unreadCount =
        lastReadAt && lastMessage
          ? lastMessage.createdAt <= lastReadAt
            ? 0
            : 1 // 정확한 개수는 별도 쿼리 필요, 목록에서는 1+ 표시
          : lastMessage
            ? 1
            : 0;

      return {
        id: room.id,
        type: room.type,
        name: room.name,
        profileImageUrl: room.profileImageUrl,
        participants: room.participants.map((rp: (typeof room.participants)[number]) => ({
          userId: rp.userId,
          role: rp.role,
          joinedAt: rp.joinedAt,
          lastReadAt: rp.lastReadAt,
          isMuted: rp.isMuted,
          user: {
            id: rp.user.id,
            displayName: rp.user.displayName,
            profileImageUrl: rp.user.profileImageUrl,
            statusMessage: rp.user.statusMessage,
            presence: 'offline' as const,
            lastSeenAt: null as string | null,
          },
        })),
        lastMessage: lastMessage
          ? {
              ...lastMessage,
              status: 'sent' as const,
              readBy: [] as { userId: string; readAt: string }[],
            }
          : undefined,
        unreadCount,
        createdAt: room.createdAt,
        updatedAt: room.updatedAt,
      };
    });
  }

  /**
   * 1:1 채팅방 생성 또는 기존 방 반환 (participants 유니크)
   */
  async createDirectRoom(userId: string, dto: CreateDirectRoomDto) {
    const { participantId } = dto;
    if (participantId === userId) {
      throw new ForbiddenException({
        code: ErrorCode.FORBIDDEN,
        message: '자기 자신과의 채팅방은 생성할 수 없습니다.',
      });
    }

    // 친구 관계 확인
    const friendship = await this.prisma.friend.findFirst({
      where: {
        userId,
        friendId: participantId,
        status: 'accepted',
      },
    });
    if (!friendship) {
      throw new ForbiddenException({
        code: ErrorCode.FORBIDDEN,
        message: '친구가 아닌 사용자와는 채팅할 수 없습니다.',
      });
    }

    // 기존 1:1 방 찾기: type=direct이고 participant가 정확히 2명(userId, participantId)인 방
    const directRooms = await this.prisma.chatRoom.findMany({
      where: {
        type: 'direct',
        participants: {
          some: { userId },
        },
      },
      include: {
        participants: {
          where: { leftAt: null },
          include: {
            user: {
              select: {
                id: true,
                displayName: true,
                profileImageUrl: true,
                statusMessage: true,
              },
            },
          },
        },
      },
    });

    const room = directRooms.find(
      (r: (typeof directRooms)[number]) =>
        r.participants.length === 2 &&
        r.participants.some((p: (typeof r.participants)[number]) => p.userId === participantId),
    );

    if (room) {
      return this._formatRoom(room, userId);
    }

    // 새 방 생성
    const created = await this.prisma.chatRoom.create({
      data: {
        type: 'direct',
        createdById: userId,
        participants: {
          create: [
            { userId, role: 'owner' },
            { userId: participantId, role: 'member' },
          ],
        },
      },
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                displayName: true,
                profileImageUrl: true,
                statusMessage: true,
              },
            },
          },
        },
      },
    });

    return this._formatRoom(created, userId);
  }

  private _formatRoom(room: any, _userId: string) {
    return {
      id: room.id,
      type: room.type,
      name: room.name,
      profileImageUrl: room.profileImageUrl,
      participants: room.participants.map((rp: any) => ({
        userId: rp.userId,
        role: rp.role,
        joinedAt: rp.joinedAt,
        lastReadAt: rp.lastReadAt,
        isMuted: rp.isMuted,
        user: {
          id: rp.user.id,
          displayName: rp.user.displayName,
          profileImageUrl: rp.user.profileImageUrl,
          statusMessage: rp.user.statusMessage,
          presence: 'offline' as const,
          lastSeenAt: null as string | null,
        },
      })),
      lastMessage: undefined,
      unreadCount: 0,
      createdAt: room.createdAt,
      updatedAt: room.updatedAt,
    };
  }
}
