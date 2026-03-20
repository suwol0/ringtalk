import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ContactsModule } from './contacts/contacts.module';
import { RoomsModule } from './rooms/rooms.module';
import { WebSocketModule } from './websocket/websocket.module';
import { MessagesModule } from './messages/messages.module';
import { PrismaModule } from './common/prisma/prisma.module';
import { RedisModule } from './common/redis/redis.module';

@Module({
  imports: [
    // 환경변수
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),

    // 전역 Rate Limit (세부 제한은 각 컨트롤러에서 추가)
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: () => ({
        throttlers: [
          {
            name: 'short',
            ttl: 1000, // 1초
            limit: 10,
          },
          {
            name: 'long',
            ttl: 60000, // 1분
            limit: 100,
          },
        ],
      }),
    }),

    PrismaModule,
    RedisModule,
    AuthModule,
    UsersModule,
    ContactsModule,
    RoomsModule,
    MessagesModule,
    WebSocketModule,
  ],
})
export class AppModule {}
