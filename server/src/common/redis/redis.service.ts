import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client!: Redis;

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    this.client = new Redis({
      host: this.config.get('REDIS_HOST', 'localhost'),
      port: this.config.get<number>('REDIS_PORT', 6379),
      password: this.config.get('REDIS_PASSWORD') || undefined,
      db: this.config.get<number>('REDIS_DB', 0),
      retryStrategy: (times) => Math.min(times * 100, 3000),
    });

    this.client.on('connect', () => this.logger.log('Redis 연결 완료'));
    this.client.on('error', (err) => this.logger.error('Redis 오류', err));
  }

  async onModuleDestroy() {
    await this.client.quit();
  }

  // ─── 기본 키-값 ───────────────────────────────

  async set(key: string, value: string, ttlSeconds?: number): Promise<void> {
    if (ttlSeconds) {
      await this.client.setex(key, ttlSeconds, value);
    } else {
      await this.client.set(key, value);
    }
  }

  async get(key: string): Promise<string | null> {
    return this.client.get(key);
  }

  async del(key: string): Promise<void> {
    await this.client.del(key);
  }

  async exists(key: string): Promise<boolean> {
    return (await this.client.exists(key)) === 1;
  }

  async ttl(key: string): Promise<number> {
    return this.client.ttl(key);
  }

  // ─── 카운터 (Rate Limit) ──────────────────────

  async incr(key: string): Promise<number> {
    return this.client.incr(key);
  }

  async expire(key: string, seconds: number): Promise<void> {
    await this.client.expire(key, seconds);
  }

  // ─── JSON 헬퍼 ───────────────────────────────

  async setJson<T>(key: string, value: T, ttlSeconds?: number): Promise<void> {
    await this.set(key, JSON.stringify(value), ttlSeconds);
  }

  async getJson<T>(key: string): Promise<T | null> {
    const raw = await this.get(key);
    if (!raw) return null;
    return JSON.parse(raw) as T;
  }

  // ─── OTP 전용 키 생성 ────────────────────────

  static otpKey(phone: string): string {
    return `otp:${phone}`;
  }

  static otpRateLimitKey(phone: string): string {
    return `otp_rate:${phone}`;
  }

  static otpIpRateLimitKey(ip: string): string {
    return `otp_ip_rate:${ip}`;
  }

  static sessionKey(userId: string, deviceId: string): string {
    return `session:${userId}:${deviceId}`;
  }

  static presenceKey(userId: string): string {
    return `presence:${userId}`;
  }

  static typingKey(roomId: string): string {
    return `typing:${roomId}`;
  }

  static refreshTokenKey(userId: string, deviceId: string): string {
    return `rt:${userId}:${deviceId}`;
  }
}
