import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { WebSocketGatewayService } from './websocket.gateway';
import { MessagesModule } from '../messages/messages.module';
import { PrismaModule } from '../common/prisma/prisma.module';

@Module({
  imports: [
    PrismaModule,
    MessagesModule,
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get('JWT_SECRET', 'fallback-secret'),
        signOptions: { expiresIn: config.get('JWT_ACCESS_EXPIRES_IN', '15m') },
      }),
    }),
  ],
  providers: [WebSocketGatewayService],
})
export class WebSocketModule {}
