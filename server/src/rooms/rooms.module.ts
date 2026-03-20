import { Module } from '@nestjs/common';
import { ChatsController } from '../chats/chats.controller';
import { RoomsService } from './rooms.service';
import { MessagesModule } from '../messages/messages.module';
import { PrismaModule } from '../common/prisma/prisma.module';

@Module({
  imports: [PrismaModule, MessagesModule],
  controllers: [ChatsController],
  providers: [RoomsService],
  exports: [RoomsService],
})
export class RoomsModule {}
