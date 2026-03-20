// 인증 관련 Dart 모델

class RequestOtpRequest {
  final String phoneNumber;
  final String deviceId;
  final String platform;

  const RequestOtpRequest({
    required this.phoneNumber,
    required this.deviceId,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'deviceId': deviceId,
        'platform': platform,
      };
}

class VerifyOtpRequest {
  final String phoneNumber;
  final String otp;
  final String deviceId;
  final String deviceName;
  final String platform;
  final String? pushToken;

  const VerifyOtpRequest({
    required this.phoneNumber,
    required this.otp,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    this.pushToken,
  });

  Map<String, dynamic> toJson() => {
        'phoneNumber': phoneNumber,
        'otp': otp,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'platform': platform,
        if (pushToken != null) 'pushToken': pushToken,
      };
}

class RefreshTokenRequest {
  final String refreshToken;
  final String deviceId;

  const RefreshTokenRequest({required this.refreshToken, required this.deviceId});

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
        'deviceId': deviceId,
      };
}

class OtpResponse {
  final bool success;
  final int expiresIn;
  final int? retryAfter;

  const OtpResponse({
    required this.success,
    required this.expiresIn,
    this.retryAfter,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) => OtpResponse(
        success: json['success'] as bool,
        expiresIn: json['expiresIn'] as int,
        retryAfter: json['retryAfter'] as int?,
      );
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final bool isNewUser;
  final String? userId;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.isNewUser = false,
    this.userId,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        expiresIn: json['expiresIn'] as int,
        isNewUser: json['isNewUser'] as bool? ?? false,
        userId: json['userId'] as String?,
      );
}

class UserSession {
  final String id;
  final String deviceId;
  final String deviceName;
  final String platform;
  final DateTime lastSeenAt;
  final DateTime createdAt;

  const UserSession({
    required this.id,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.lastSeenAt,
    required this.createdAt,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        id: json['id'] as String,
        deviceId: json['deviceId'] as String,
        deviceName: json['deviceName'] as String,
        platform: json['platform'] as String,
        lastSeenAt: DateTime.parse(json['lastSeenAt'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
