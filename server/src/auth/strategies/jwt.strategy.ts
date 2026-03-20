import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../common/prisma/prisma.service';
import { JwtPayload } from '../../common/decorators/current-user.decorator';
import { ErrorCode } from '@ringtalk/shared-server';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    config: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get('JWT_SECRET', 'fallback-secret'),
    });
  }

  async validate(payload: JwtPayload): Promise<JwtPayload> {
    const session = await this.prisma.userSession.findUnique({
      where: {
        userId_deviceId: { userId: payload.sub, deviceId: payload.deviceId },
      },
    });

    if (!session) {
      throw new UnauthorizedException({
        code: ErrorCode.UNAUTHORIZED,
        message: '세션이 존재하지 않습니다. 다시 로그인해 주세요.',
      });
    }

    return { sub: payload.sub, deviceId: payload.deviceId };
  }
}
