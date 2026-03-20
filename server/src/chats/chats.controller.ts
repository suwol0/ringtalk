import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { RoomsService } from '../rooms/rooms.service';
import { MessagesService } from '../messages/messages.service';
import { CreateDirectRoomDto } from '../rooms/dto/create-direct-room.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';

@Controller('chats')
@UseGuards(JwtAuthGuard)
export class ChatsController {
  constructor(
    private readonly rooms: RoomsService,
    private readonly messages: MessagesService,
  ) {}

  @Get()
  getChats(@CurrentUser() user: JwtPayload) {
    return this.rooms.getRooms(user.sub);
  }

  @Post('direct')
  createDirectChat(@CurrentUser() user: JwtPayload, @Body() dto: CreateDirectRoomDto) {
    return this.rooms.createDirectRoom(user.sub, dto);
  }

  @Get(':id/messages')
  getMessages(
    @CurrentUser() user: JwtPayload,
    @Param('id') roomId: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    // parseInt('abc') → NaN 방어: 숫자가 아니면 기본값 50 사용
    const parsed = limit ? parseInt(limit, 10) : 50;
    const limitNum = Number.isFinite(parsed) && parsed > 0 ? parsed : 50;
    return this.messages.getMessages(roomId, user.sub, cursor, limitNum);
  }
}
