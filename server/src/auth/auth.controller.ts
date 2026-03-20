import { Controller, Post, Body, Get, Delete, Param, Req, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  /**
   * POST /auth/request-otp
   * 전화번호로 OTP 발송 요청
   * Rate Limit: 10분에 3회 (서비스 레이어에서 추가 검증)
   */
  @Post('request-otp')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { ttl: 60000, limit: 5 } }) // 1분에 5회 기본 제한
  requestOtp(@Body() dto: RequestOtpDto, @Req() req: Request) {
    const ip = req.ip ?? req.socket.remoteAddress ?? 'unknown';
    return this.auth.requestOtp(dto, ip);
  }

  /**
   * POST /auth/verify-otp
   * OTP 검증 → 토큰 발급 (로그인/회원가입 통합)
   */
  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.auth.verifyOtp(dto);
  }

  /**
   * POST /auth/refresh
   * 액세스 토큰 갱신
   */
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshTokenDto) {
    return this.auth.refresh(dto);
  }

  /**
   * POST /auth/logout
   * 현재 디바이스 로그아웃
   */
  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  async logout(@CurrentUser() user: JwtPayload) {
    await this.auth.logout(user.sub, user.deviceId);
  }

  /**
   * GET /auth/sessions
   * 내 세션 목록 조회 (로그인 디바이스 목록)
   */
  @Get('sessions')
  @UseGuards(JwtAuthGuard)
  getSessions(@CurrentUser() user: JwtPayload) {
    return this.auth.getSessions(user.sub);
  }

  /**
   * DELETE /auth/sessions/:sessionId
   * 특정 세션 강제 종료
   */
  @Delete('sessions/:sessionId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(JwtAuthGuard)
  async revokeSession(@CurrentUser() user: JwtPayload, @Param('sessionId') sessionId: string) {
    await this.auth.revokeSession(user.sub, sessionId);
  }
}
