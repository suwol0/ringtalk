// API 공통 응답/에러 Dart 모델

class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;
  final PaginationMeta? meta;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) =>
      ApiResponse(
        success: json['success'] as bool,
        data: json['data'] != null && fromJsonT != null
            ? fromJsonT(json['data'])
            : json['data'] as T?,
        error: json['error'] != null
            ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
            : null,
        meta: json['meta'] != null
            ? PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>)
            : null,
      );
}

class ApiError {
  final String code;
  final String message;
  final dynamic details;

  const ApiError({required this.code, required this.message, this.details});

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
        code: json['code'] as String,
        message: json['message'] as String,
        details: json['details'],
      );

  @override
  String toString() => '[$code] $message';
}

class PaginationMeta {
  final int total;
  final int page;
  final int limit;
  final bool hasNext;
  final bool hasPrev;
  final String? nextCursor;

  const PaginationMeta({
    required this.total,
    required this.page,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
    this.nextCursor,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) => PaginationMeta(
        total: json['total'] as int,
        page: json['page'] as int,
        limit: json['limit'] as int,
        hasNext: json['hasNext'] as bool,
        hasPrev: json['hasPrev'] as bool,
        nextCursor: json['nextCursor'] as String?,
      );
}

/// 공통 에러 코드
abstract class ErrorCode {
  // 인증
  static const otpExpired = 'OTP_EXPIRED';
  static const otpInvalid = 'OTP_INVALID';
  static const otpMaxAttempts = 'OTP_MAX_ATTEMPTS';
  static const rateLimit = 'RATE_LIMIT';
  static const tokenExpired = 'TOKEN_EXPIRED';
  static const tokenInvalid = 'TOKEN_INVALID';
  static const unauthorized = 'UNAUTHORIZED';

  // 유저
  static const userNotFound = 'USER_NOT_FOUND';
  static const userBlocked = 'USER_BLOCKED';

  // 채팅
  static const roomNotFound = 'ROOM_NOT_FOUND';
  static const notRoomMember = 'NOT_ROOM_MEMBER';
  static const messageNotFound = 'MESSAGE_NOT_FOUND';

  // 서버
  static const internalError = 'INTERNAL_ERROR';
  static const validationError = 'VALIDATION_ERROR';
}

/// API 예외
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromError(ApiError error, {int? statusCode}) =>
      ApiException(code: error.code, message: error.message, statusCode: statusCode);

  @override
  String toString() => 'ApiException($code): $message';
}
