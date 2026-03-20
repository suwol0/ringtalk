import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayInit,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../common/prisma/prisma.service';
import { MessagesService } from '../messages/messages.service';
import { JwtPayload } from '../common/decorators/current-user.decorator';
import { WsEvents } from '@ringtalk/shared-server';

export interface AuthenticatedSocket extends Socket {
  data: Socket['data'] & { user?: JwtPayload };
}

const ROOM_PREFIX = 'room:';

@WebSocketGateway({
  cors: { origin: '*' },
  path: '/socket.io',
})
export class WebSocketGatewayService
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(WebSocketGatewayService.name);

  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
    private readonly messages: MessagesService,
  ) {}

  afterInit(server: Server) {
    server.use(async (socket: Socket, next) => {
      const token =
        socket.handshake.auth?.accessToken ?? socket.handshake.auth?.token;

      if (!token) {
        this.logger.warn(`WS 연결 거부: 토큰 없음 (socket ${socket.id})`);
        return next(new Error('UNAUTHORIZED'));
      }

      try {
        const payload = this.jwt.verify<JwtPayload>(token, {
          secret: this.config.get('JWT_SECRET', 'fallback-secret'),
        });

        const session = await this.prisma.userSession.findUnique({
          where: {
            userId_deviceId: { userId: payload.sub, deviceId: payload.deviceId },
          },
        });

        if (!session) {
          this.logger.warn(`WS 연결 거부: 세션 없음 (userId=${payload.sub})`);
          return next(new Error('UNAUTHORIZED'));
        }

        (socket as AuthenticatedSocket).data.user = {
          sub: payload.sub,
          deviceId: payload.deviceId,
        };
        next();
      } catch {
        this.logger.warn(`WS 연결 거부: 토큰 검증 실패 (socket ${socket.id})`);
        return next(new Error('UNAUTHORIZED'));
      }
    });

    this.logger.log('WebSocket Gateway 초기화 완료');
  }

  handleConnection(client: AuthenticatedSocket) {
    const user = client.data.user;
    if (user) {
      client.join(`user:${user.sub}`);
      this.logger.log(`WS 연결: userId=${user.sub} socket=${client.id}`);
      client.emit(WsEvents.AUTHENTICATED, { userId: user.sub });
    }
  }

  handleDisconnect(client: AuthenticatedSocket) {
    const user = client.data.user;
    if (user) {
      this.logger.log(`WS 연결 해제: userId=${user.sub} socket=${client.id}`);
    }
  }

  @SubscribeMessage(WsEvents.ROOM_JOIN)
  async handleRoomJoin(
    @MessageBody() data: { roomId: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    const user = client.data.user;
    if (!user) return;

    const { roomId } = data;
    if (!roomId) return;

    const participation = await this.prisma.roomParticipant.findFirst({
      where: { roomId, userId: user.sub, leftAt: null },
    });
    if (!participation) return;

    client.join(ROOM_PREFIX + roomId);
    this.logger.debug(`room:join userId=${user.sub} roomId=${roomId}`);
  }

  @SubscribeMessage(WsEvents.ROOM_LEAVE)
  handleRoomLeave(
    @MessageBody() data: { roomId: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    const { roomId } = data;
    if (roomId) client.leave(ROOM_PREFIX + roomId);
  }

  @SubscribeMessage(WsEvents.MESSAGE_SEND)
  async handleMessageSend(
    @MessageBody()
    data: {
      roomId?: string;
      chatId?: string;
      clientMessageId: string;
      content?: string;
      text?: string;
      type?: string;
      mediaUrl?: string;
      replyToId?: string;
    },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    const user = client.data.user;
    if (!user) {
      client.emit('error', { code: 'UNAUTHORIZED', message: '인증이 필요합니다.' });
      return;
    }

    const roomId = data.roomId ?? data.chatId;
    const content = data.content ?? data.text ?? '';

    if (!roomId || !data.clientMessageId) {
      client.emit('error', {
        code: 'VALIDATION_ERROR',
        message: 'roomId, clientMessageId는 필수입니다.',
      });
      return;
    }

    try {
      const result = await this.messages.sendMessage(user.sub, {
        roomId,
        clientMessageId: data.clientMessageId,
        type: (data.type as any) ?? 'text',
        content,
        mediaUrl: data.mediaUrl,
        replyToId: data.replyToId,
      });

      const roomKey = ROOM_PREFIX + roomId;
      this.server.to(roomKey).emit(WsEvents.MESSAGE_NEW, {
        message: result.message,
        clientMessageId: data.clientMessageId,
      });

      client.emit(WsEvents.MESSAGE_STATUS, {
        clientMessageId: data.clientMessageId,
        status: 'sent',
        messageId: result.message.id,
      });
    } catch (err: any) {
      this.logger.warn(`message:send 실패: ${err?.message}`);
      client.emit('error', {
        code: err?.response?.code ?? 'INTERNAL_ERROR',
        message: err?.response?.message ?? '메시지 전송에 실패했습니다.',
      });
    }
  }

  @SubscribeMessage(WsEvents.CHAT_READ)
  async handleChatRead(
    @MessageBody() data: { roomId: string; lastReadMessageId?: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    const user = client.data.user;
    if (!user) return;

    const { roomId, lastReadMessageId } = data;
    if (!roomId) return;

    try {
      const { readAt, senderIds, lastReadMessageId: resolvedId } =
        await this.messages.markRead(roomId, user.sub, lastReadMessageId);

      // 방 전체에 읽음 브로드캐스트 (누가, 어느 메시지까지 읽었는지)
      this.server.to(ROOM_PREFIX + roomId).emit(WsEvents.CHAT_READ, {
        roomId,
        userId: user.sub,
        readAt: readAt.toISOString(),
        lastReadMessageId: resolvedId,
      });

      // 발신자들 개인 소켓에도 전달 (다른 기기 탭 등 대비)
      for (const senderId of senderIds) {
        if (senderId !== user.sub) {
          this.server.to(`user:${senderId}`).emit(WsEvents.MESSAGE_STATUS, {
            roomId,
            readBy: user.sub,
            status: 'read',
            readAt: readAt.toISOString(),
            lastReadMessageId: resolvedId,
          });
        }
      }

      this.logger.debug(
        `chat.read userId=${user.sub} roomId=${roomId} lastId=${resolvedId ?? 'all'} msgs=${senderIds.length}`,
      );
    } catch (err: any) {
      this.logger.warn(`chat.read 실패: ${err?.message}`);
    }
  }

  @SubscribeMessage(WsEvents.MESSAGE_DELIVERED)
  async handleMessageDelivered(
    @MessageBody() data: { messageId: string; roomId: string },
    @ConnectedSocket() client: AuthenticatedSocket,
  ) {
    const user = client.data.user;
    if (!user) return;

    const { messageId, roomId } = data;
    if (!messageId || !roomId) return;

    const participation = await this.prisma.roomParticipant.findFirst({
      where: { roomId, userId: user.sub, leftAt: null },
    });
    if (!participation) return;

    const message = await this.prisma.message.findFirst({
      where: { id: messageId, roomId },
    });
    if (!message || message.senderId === user.sub) return;

    this.server.to(`user:${message.senderId}`).emit(WsEvents.MESSAGE_STATUS, {
      messageId,
      status: 'delivered',
      deliveredTo: user.sub,
    });
  }
}
