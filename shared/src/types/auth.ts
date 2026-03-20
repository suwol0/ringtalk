// 인증 관련 타입 정의

export interface RequestOtpDto {
  phoneNumber: string; // E.164 형식: +821012345678
  deviceId: string;
  platform: 'ios' | 'android' | 'windows' | 'macos' | 'web';
}

export interface VerifyOtpDto {
  phoneNumber: string;
  otp: string;
  deviceId: string;
  deviceName: string;
  platform: 'ios' | 'android' | 'windows' | 'macos' | 'web';
  pushToken?: string;
}

export interface RefreshTokenDto {
  refreshToken: string;
  deviceId: string;
}

export interface LogoutDto {
  deviceId: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number; // seconds
}

export interface OtpResponse {
  success: boolean;
  expiresIn: number; // seconds (180)
  retryAfter?: number; // rate limit 시 재시도 대기 시간(초)
}

export interface UserSession {
  userId: string;
  deviceId: string;
  deviceName: string;
  platform: string;
  lastSeenAt: string; // ISO 8601
  createdAt: string;
}
