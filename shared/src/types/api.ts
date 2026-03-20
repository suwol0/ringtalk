// API 공통 응답 타입

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: ApiError;
  meta?: PaginationMeta;
}

export interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  hasNext: boolean;
  hasPrev: boolean;
}

export interface PaginationQuery {
  page?: number;
  limit?: number;
  cursor?: string;
}

// 공통 에러 코드
export const ErrorCode = {
  // 인증
  OTP_EXPIRED: 'OTP_EXPIRED',
  OTP_INVALID: 'OTP_INVALID',
  OTP_MAX_ATTEMPTS: 'OTP_MAX_ATTEMPTS',
  RATE_LIMIT: 'RATE_LIMIT',
  TOKEN_EXPIRED: 'TOKEN_EXPIRED',
  TOKEN_INVALID: 'TOKEN_INVALID',
  UNAUTHORIZED: 'UNAUTHORIZED',

  // 유저
  USER_NOT_FOUND: 'USER_NOT_FOUND',
  USER_BLOCKED: 'USER_BLOCKED',
  FORBIDDEN: 'FORBIDDEN',

  // 채팅
  ROOM_NOT_FOUND: 'ROOM_NOT_FOUND',
  NOT_ROOM_MEMBER: 'NOT_ROOM_MEMBER',
  MESSAGE_NOT_FOUND: 'MESSAGE_NOT_FOUND',

  // 서버
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  VALIDATION_ERROR: 'VALIDATION_ERROR',
} as const;

export type ErrorCodeType = (typeof ErrorCode)[keyof typeof ErrorCode];
