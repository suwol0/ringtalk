import { createParamDecorator, ExecutionContext } from '@nestjs/common';

// JwtPayload의 단일 출처 - jwt.strategy.ts가 이 타입을 import
export interface JwtPayload {
  sub: string; // userId
  deviceId: string;
  iat?: number;
  exp?: number;
}

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): JwtPayload => {
    const request = ctx.switchToHttp().getRequest();
    return request.user as JwtPayload;
  },
);
