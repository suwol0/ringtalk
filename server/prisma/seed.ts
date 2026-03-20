import { PrismaClient } from '@prisma/client';
import { createHash } from 'crypto';

const prisma = new PrismaClient();

function sha256Phone(phoneE164: string): string {
  return createHash('sha256').update(phoneE164).digest('hex');
}

async function main() {
  console.log('🌱 DB 시드 시작...');

  // 개발용 테스트 유저 (auth.service와 동일한 SHA-256 방식)
  const phoneHash1 = sha256Phone('+821011111111');
  const phoneHash2 = sha256Phone('+821022222222');

  const user1 = await prisma.user.upsert({
    where: { phoneE164: '+821011111111' },
    update: {},
    create: {
      phoneE164: '+821011111111',
      phoneHash: phoneHash1,
      displayName: '테스트 유저 1',
      statusMessage: '링톡 개발 중 🔔',
    },
  });

  const user2 = await prisma.user.upsert({
    where: { phoneE164: '+821022222222' },
    update: {},
    create: {
      phoneE164: '+821022222222',
      phoneHash: phoneHash2,
      displayName: '테스트 유저 2',
      statusMessage: '안녕하세요!',
    },
  });

  // 친구 관계
  await prisma.friend.upsert({
    where: { userId_friendId: { userId: user1.id, friendId: user2.id } },
    update: {},
    create: { userId: user1.id, friendId: user2.id, status: 'accepted' },
  });

  await prisma.friend.upsert({
    where: { userId_friendId: { userId: user2.id, friendId: user1.id } },
    update: {},
    create: { userId: user2.id, friendId: user1.id, status: 'accepted' },
  });

  // 1:1 채팅방
  const room = await prisma.chatRoom.upsert({
    where: { id: 'seed-room-1' },
    update: {},
    create: {
      id: 'seed-room-1',
      type: 'direct',
      createdById: user1.id,
      participants: {
        create: [
          { userId: user1.id, role: 'owner' },
          { userId: user2.id, role: 'member' },
        ],
      },
    },
  });

  // 시드 메시지
  await prisma.message.createMany({
    data: [
      { roomId: room.id, senderId: user1.id, type: 'text', content: '안녕하세요! 링톡 테스트 중이에요 🔔' },
      { roomId: room.id, senderId: user2.id, type: 'text', content: '반가워요! 잘 작동하네요 ✨' },
    ],
    skipDuplicates: true,
  });

  console.log('✅ 시드 완료!');
  console.log(`   유저1: ${user1.displayName} (${user1.phoneE164})`);
  console.log(`   유저2: ${user2.displayName} (${user2.phoneE164})`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
