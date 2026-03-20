import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { createHash } from 'crypto';
import { PrismaService } from '../common/prisma/prisma.service';
import { RedisService } from '../common/redis/redis.service';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import {
  OtpResponse,
  AuthTokens,
  ErrorCode,
  OTP_EXPIRES_IN,
  OTP_MAX_ATTEMPTS,
  OTP_RATE_LIMIT_WINDOW,
  OTP_RATE_LIMIT_MAX,
} from '@ringtalk/shared-server';

// 액세스 토큰 만료 시간 (초 단위 고정값)
const ACCESS_TOKEN_EXPIRES_IN_SECONDS = 15 * 60;

interface TokenPair {
  accessToken: string;
  refreshToken: string;
  refreshTokenHash: string;
  expiresAt: Date;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly redis: RedisService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  // ─── OTP 요청 ──────────────────────────────────────────────────────────────

  async requestOtp(dto: RequestOtpDto, ip: string): Promise<OtpResponse> {
    const { phoneNumber } = dto;

    await this.checkOtpRateLimit(phoneNumber, ip);

    const otp = this.generateOtp();
    const otpHash = await bcrypt.hash(otp, 10);

    await this.redis.setJson(
      RedisService.otpKey(phoneNumber),
      { hash: otpHash, attempts: 0 },
      OTP_EXPIRES_IN,
    );

    await this.incrementRateLimit(phoneNumber, ip);
    await this.sendOtp(phoneNumber, otp);

    return { success: true, expiresIn: OTP_EXPIRES_IN };
  }

  // ─── OTP 검증 + 로그인/회원가입 ────────────────────────────────────────────

  async verifyOtp(dto: VerifyOtpDto): Promise<AuthTokens & { isNewUser: boolean }> {
    const { phoneNumber, otp, deviceId, deviceName, platform, pushToken } = dto;

    const stored = await this.redis.getJson<{ hash: string; attempts: number }>(
      RedisService.otpKey(phoneNumber),
    );

    if (!stored) {
      throw new BadRequestException({
        code: ErrorCode.OTP_EXPIRED,
        message: 'OTP가 만료되었거나 존재하지 않습니다.',
      });
    }

    if (stored.attempts >= OTP_MAX_ATTEMPTS) {
      await this.redis.del(RedisService.otpKey(phoneNumber));
      throw new BadRequestException({
        code: ErrorCode.OTP_MAX_ATTEMPTS,
        message: '최대 시도 횟수를 초과했습니다. 새로운 OTP를 요청하세요.',
      });
    }

    const isValid = await bcrypt.compare(otp, stored.hash);

    if (!isValid) {
      await this.redis.setJson(
        RedisService.otpKey(phoneNumber),
        { ...stored, attempts: stored.attempts + 1 },
        await this.redis.ttl(RedisService.otpKey(phoneNumber)),
      );
      throw new BadRequestException({
        code: ErrorCode.OTP_INVALID,
        message: `잘못된 OTP입니다. 남은 시도: ${OTP_MAX_ATTEMPTS - stored.attempts - 1}회`,
      });
    }

    await this.redis.del(RedisService.otpKey(phoneNumber));

    const { user, isNewUser } = await this.findOrCreateUser(phoneNumber);
    const tokens = await this.createSession(user.id, { deviceId, deviceName, platform, pushToken });

    this.logger.log(`로그인 성공: userId=${user.id} device=${deviceName} (신규: ${isNewUser})`);

    return { ...tokens, isNewUser, userId: user.id } as typeof tokens & { isNewUser: boolean; userId: string };
  }

  // ─── 토큰 갱신 ─────────────────────────────────────────────────────────────

  async refresh(dto: RefreshTokenDto): Promise<AuthTokens> {
    const { refreshToken, deviceId } = dto;

    let payload: { sub: string; deviceId: string };
    try {
      payload = this.jwt.verify(refreshToken, {
        secret: this.config.get('JWT_REFRESH_SECRET'),
      }) as typeof payload;
    } catch {
      throw new UnauthorizedException({
        code: ErrorCode.TOKEN_EXPIRED,
        message: '리프레시 토큰이 만료되었거나 유효하지 않습니다.',
      });
    }

    if (payload.deviceId !== deviceId) {
      throw new UnauthorizedException({
        code: ErrorCode.TOKEN_INVALID,
        message: '토큰과 디바이스가 일치하지 않습니다.',
      });
    }

    const session = await this.prisma.userSession.findUnique({
      where: { userId_deviceId: { userId: payload.sub, deviceId } },
    });

    if (!session || session.expiresAt < new Date()) {
      throw new UnauthorizedException({
        code: ErrorCode.TOKEN_EXPIRED,
        message: '세션이 만료되었습니다. 다시 로그인해 주세요.',
      });
    }

    const isValid = await bcrypt.compare(refreshToken, session.refreshToken);
    if (!isValid) {
      throw new UnauthorizedException({
        code: ErrorCode.TOKEN_INVALID,
        message: '유효하지 않은 리프레시 토큰입니다.',
      });
    }

    return this.rotateTokens(payload.sub, deviceId);
  }

  // ─── 로그아웃 ──────────────────────────────────────────────────────────────

  async logout(userId: string, deviceId: string): Promise<void> {
    await Promise.all([
      this.prisma.userSession.deleteMany({ where: { userId, deviceId } }),
      this.redis.del(RedisService.sessionKey(userId, deviceId)),
    ]);
    this.logger.log(`로그아웃: userId=${userId} deviceId=${deviceId}`);
  }

  // ─── 세션 목록 ─────────────────────────────────────────────────────────────

  async getSessions(userId: string) {
    return this.prisma.userSession.findMany({
      where: { userId },
      select: {
        id: true,
        deviceId: true,
        deviceName: true,
        platform: true,
        lastSeenAt: true,
        createdAt: true,
      },
      orderBy: { lastSeenAt: 'desc' },
    });
  }

  // ─── 특정 세션 강제 종료 ───────────────────────────────────────────────────

  async revokeSession(userId: string, sessionId: string): Promise<void> {
    const session = await this.prisma.userSession.findFirst({
      where: { id: sessionId, userId },
    });
    if (session) {
      await Promise.all([
        this.prisma.userSession.delete({ where: { id: sessionId } }),
        this.redis.del(RedisService.sessionKey(userId, session.deviceId)),
      ]);
    }
  }

  // ─── 내부 헬퍼 ─────────────────────────────────────────────────────────────

  private generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  private async sendOtp(phone: string, otp: string): Promise<void> {
    if (this.config.get('OTP_MOCK') === 'true') {
      this.logger.log(`[개발] OTP for ${phone}: ${otp}`);
      return;
    }
    // TODO: Twilio 연동
    // const client = twilio(this.config.get('TWILIO_ACCOUNT_SID'), this.config.get('TWILIO_AUTH_TOKEN'));
    // await client.messages.create({ body: `[링톡] 인증번호: ${otp}`, from: this.config.get('TWILIO_PHONE_NUMBER'), to: phone });
  }

  private async checkOtpRateLimit(phone: string, ip: string): Promise<void> {
    const phoneKey = RedisService.otpRateLimitKey(phone);
    const ipKey = RedisService.otpIpRateLimitKey(ip);

    const [phoneCount, ipCount] = await Promise.all([
      this.redis.get(phoneKey).then((v) => parseInt(v ?? '0')),
      this.redis.get(ipKey).then((v) => parseInt(v ?? '0')),
    ]);

    if (phoneCount >= OTP_RATE_LIMIT_MAX || ipCount >= OTP_RATE_LIMIT_MAX * 2) {
      const retryAfter = await this.redis.ttl(phoneKey);
      throw new HttpException(
        {
          code: ErrorCode.RATE_LIMIT,
          message: '너무 많은 OTP 요청입니다. 잠시 후 다시 시도하세요.',
          details: { retryAfter },
        },
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private async incrementRateLimit(phone: string, ip: string): Promise<void> {
    const phoneKey = RedisService.otpRateLimitKey(phone);
    const ipKey = RedisService.otpIpRateLimitKey(ip);

    const [phoneCount] = await Promise.all([
      this.redis.incr(phoneKey),
      this.redis.incr(ipKey),
    ]);

    // 첫 번째 증가 시 TTL 설정
    if (phoneCount === 1) {
      await Promise.all([
        this.redis.expire(phoneKey, OTP_RATE_LIMIT_WINDOW),
        this.redis.expire(ipKey, OTP_RATE_LIMIT_WINDOW),
      ]);
    }
  }

  private async findOrCreateUser(phoneE164: string) {
    const existing = await this.prisma.user.findUnique({ where: { phoneE164 } });
    if (existing) return { user: existing, isNewUser: false };

    // phoneHash: SHA-256(E.164) — 클라이언트와 동일한 방식으로 저장
    // 이렇게 해야 연락처 동기화 API에서 클라이언트가 보낸 해시와 IN 절 매칭 가능
    // bcrypt는 salt가 달라 매번 다른 값 → 검색 불가
    const phoneHash = createHash('sha256').update(phoneE164).digest('hex');

    const user = await this.prisma.user.create({
      data: {
        phoneE164,
        phoneHash,
        displayName: '링톡 사용자',
      },
    });

    return { user, isNewUser: true };
  }

  // 공통 토큰 페어 생성 - createSession / rotateTokens 양쪽에서 사용
  private async generateTokenPair(userId: string, deviceId: string): Promise<TokenPair> {
    const jwtPayload = { sub: userId, deviceId };

    const accessToken = this.jwt.sign(jwtPayload, {
      secret: this.config.get('JWT_SECRET'),
      expiresIn: this.config.get('JWT_ACCESS_EXPIRES_IN', '15m'),
    });

    const refreshToken = this.jwt.sign(jwtPayload, {
      secret: this.config.get('JWT_REFRESH_SECRET'),
      expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '30d'),
    });

    const refreshTokenHash = await bcrypt.hash(refreshToken, 10);
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 30);

    return { accessToken, refreshToken, refreshTokenHash, expiresAt };
  }

  private async createSession(
    userId: string,
    opts: { deviceId: string; deviceName: string; platform: string; pushToken?: string },
  ): Promise<AuthTokens> {
    const { deviceId, deviceName, platform, pushToken } = opts;
    const { accessToken, refreshToken, refreshTokenHash, expiresAt } =
      await this.generateTokenPair(userId, deviceId);

    await this.prisma.userSession.upsert({
      where: { userId_deviceId: { userId, deviceId } },
      create: {
        userId,
        deviceId,
        deviceName,
        platform: platform as any,
        pushToken,
        refreshToken: refreshTokenHash,
        expiresAt,
      },
      update: {
        deviceName,
        pushToken,
        refreshToken: refreshTokenHash,
        expiresAt,
        lastSeenAt: new Date(),
      },
    });

    return { accessToken, refreshToken, expiresIn: ACCESS_TOKEN_EXPIRES_IN_SECONDS };
  }

  private async rotateTokens(userId: string, deviceId: string): Promise<AuthTokens> {
    const { accessToken, refreshToken, refreshTokenHash, expiresAt } =
      await this.generateTokenPair(userId, deviceId);

    await Promise.all([
      this.prisma.userSession.update({
        where: { userId_deviceId: { userId, deviceId } },
        data: { refreshToken: refreshTokenHash, expiresAt, lastSeenAt: new Date() },
      }),
      // Redis에도 갱신 시각 반영
      this.redis.set(
        RedisService.refreshTokenKey(userId, deviceId),
        new Date().toISOString(),
        60 * 60 * 24 * 30, // 30일
      ),
    ]);

    return { accessToken, refreshToken, expiresIn: ACCESS_TOKEN_EXPIRES_IN_SECONDS };
  }
}
