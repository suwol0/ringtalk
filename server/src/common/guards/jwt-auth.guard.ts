import { Injectable, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { ErrorCode } from '@ringtalk/shared-server';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  handleRequest<TUser>(err: Error | null, user: TUser | false): TUser {
    if (err || !user) {
      throw new UnauthorizedException({
        code: ErrorCode.UNAUTHORIZED,
        message: '로그인이 필요합니다.',
      });
    }
    return user;
  }

  canActivate(context: ExecutionContext) {
    return super.canActivate(context);
  }
}
