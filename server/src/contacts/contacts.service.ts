import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../common/prisma/prisma.service';

@Injectable()
export class ContactsService {
  private readonly logger = new Logger(ContactsService.name);

  constructor(private readonly prisma: PrismaService) {}

  // ─── POST /contacts/sync ────────────────────────────────────────────────────
  // 클라이언트가 보낸 SHA-256 해시 목록과 DB의 phoneHash를 매칭
  // 매칭된 유저와 자동으로 친구 관계(accepted) 생성
  async syncContacts(userId: string, phoneHashes: string[]) {
    if (phoneHashes.length === 0) {
      return { matched: 0, friends: [] };
    }

    // 매칭된 유저 조회 (자기 자신 + 탈퇴 계정 제외)
    const matchedUsers = await this.prisma.user.findMany({
      where: {
        phoneHash: { in: phoneHashes },
        id: { not: userId },
        status: 'active',
      },
      select: {
        id: true,
        displayName: true,
        profileImageUrl: true,
        statusMessage: true,
        phoneHash: true, // 클라이언트 역방향 매핑용
      },
    });

    // 매칭된 유저마다 친구 관계 upsert (이미 친구면 유지, 없으면 생성)
    if (matchedUsers.length > 0) {
      await this.prisma.$transaction(
        matchedUsers.map((user: (typeof matchedUsers)[number]) =>
          this.prisma.friend.upsert({
            where: {
              userId_friendId: { userId, friendId: user.id },
            },
            create: { userId, friendId: user.id, status: 'accepted' },
            update: {}, // 기존 상태(차단 등) 유지
          }),
        ),
      );
    }

    this.logger.log(
      `연락처 동기화: userId=${userId} 전송=${phoneHashes.length} 매칭=${matchedUsers.length}`,
    );

    return {
      matched: matchedUsers.length,
      friends: matchedUsers,
    };
  }

}
