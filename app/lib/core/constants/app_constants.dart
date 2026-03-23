// 링톡 앱 전역 상수

abstract class AppConstants {
  static const appName = '링톡';
  static const appVersion = '0.1.0';

  // OTP
  static const otpLength = 6;
  static const otpExpiresInSeconds = 180; // 3분
  static const otpMaxAttempts = 5;
  static const otpRateLimitWindowSeconds = 600; // 10분
  static const otpRateLimitMax = 3;

  // 토큰
  static const accessTokenExpiresIn = '15m';
  static const refreshTokenExpiresIn = '30d';

  // 페이지네이션
  static const defaultPageSize = 30;
  static const maxPageSize = 100;
  static const messagePageSize = 50;

  // 메시지
  static const maxMessageLength = 5000;
  static const maxFileSizeMb = 100;
}

/// API 엔드포인트
abstract class ApiEndpoints {
  // 인증
  static const requestOtp = '/auth/request-otp';
  static const verifyOtp = '/auth/verify-otp';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const sessions = '/auth/sessions';

  // 유저
  static const me = '/users/me';
  static String userProfile(String id) => '/users/$id';
  static const friends = '/users/me/friends';
  static const addFriend = '/users/me/friends';
  static String blockUser(String id) => '/users/$id/block';
  static const searchByPhone = '/users/search';

  // 연락처 동기화 (친구 목록은 GET /users/me/friends 사용)
  static const contactsSync = '/contacts/sync';

  // 채팅 (목록, 1:1 생성, 메시지)
  static const chats = '/chats';
  static const chatsDirect = '/chats/direct';
  static String chatMessages(String id) => '/chats/$id/messages';

  // 미디어 업로드
  static const uploadPresign = '/upload/presign';
}

/// 네트워크 기본 URL (API_URL에서 origin 추출)
abstract class NetworkUrls {
  static const _apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// Socket.IO 서버 URL (API와 동일 호스트)
  static String get socketBase =>
      Uri.parse(_apiUrl).replace(path: '').toString();
}

/// WebSocket 이벤트 이름
abstract class WsEvents {
  // 연결
  static const connect = 'connect';
  static const disconnect = 'disconnect';
  static const authenticate = 'authenticate';
  static const authenticated = 'authenticated';

  // 메시지
  static const messageSend = 'message:send';
  static const messageNew = 'message:new';
  static const messageStatus = 'message:status';
  static const messageDelivered = 'message:delivered';
  static const messageDelete = 'message:delete';
  static const messageDeleted = 'message:deleted';
  static const chatRead = 'chat.read';

  // 방
  static const roomJoin = 'room:join';
  static const roomLeave = 'room:leave';
  static const roomUpdated = 'room:updated';

  // 유저 상태
  static const userTypingStart = 'user:typing:start';
  static const userTypingStop = 'user:typing:stop';
  static const userTyping = 'user:typing';
  static const userPresence = 'user:presence';
  static const userRead = 'user:read';
}
