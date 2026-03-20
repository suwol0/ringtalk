import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ErrorCode } from '@ringtalk/shared-server';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException({ code: ErrorCode.USER_NOT_FOUND, message: '유저를 찾을 수 없습니다.' });
    }
    const { phoneHash: _, ...safe } = user;
    return safe;
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: dto,
    });
    const { phoneHash: _, ...safe } = user;
    return safe;
  }

  async searchByPhoneHash(phoneHashes: string[]) {
    // phoneHash(SHA-256)를 함께 반환 — 클라이언트가 매칭 역방향 맵 구성에 사용
    return this.prisma.user.findMany({
      where: { phoneHash: { in: phoneHashes } },
      select: {
        id: true,
        displayName: true,
        profileImageUrl: true,
        statusMessage: true,
        phoneHash: true, // 클라이언트 매칭용
      },
    });
  }

  async blockUser(userId: string, targetId: string) {
    await this.prisma.friend.upsert({
      where: { userId_friendId: { userId, friendId: targetId } },
      create: { userId, friendId: targetId, status: 'blocked' },
      update: { status: 'blocked' },
    });
  }

  /**
   * 수락된 친구 목록 반환 (이름순, alias 우선 표시, phoneHash 포함)
   */
  async getFriends(userId: string) {
    const friends = await this.prisma.friend.findMany({
      where: { userId, status: 'accepted' },
      include: {
        friend: {
          select: {
            id: true,
            displayName: true,
            profileImageUrl: true,
            statusMessage: true,
            phoneHash: true,
          },
        },
      },
      orderBy: [{ friend: { displayName: 'asc' } }],
    });

    return friends.map((f: (typeof friends)[number]) => ({
      ...f.friend,
      displayName: f.alias ?? f.friend.displayName,
      alias: f.alias,
      friendedAt: f.createdAt,
    }));
  }
}
