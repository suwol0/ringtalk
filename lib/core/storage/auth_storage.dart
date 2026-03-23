import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

abstract class AuthStorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userId = 'user_id';
  static const deviceId = 'device_id';
}

class AuthStorage {
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: AuthStorageKeys.accessToken, value: accessToken),
      _storage.write(key: AuthStorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  static Future<String?> getAccessToken() =>
      _storage.read(key: AuthStorageKeys.accessToken);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: AuthStorageKeys.refreshToken);

  static Future<String?> getUserId() =>
      _storage.read(key: AuthStorageKeys.userId);

  static Future<String?> getDeviceId() =>
      _storage.read(key: AuthStorageKeys.deviceId);

  static Future<void> saveUserId(String userId) =>
      _storage.write(key: AuthStorageKeys.userId, value: userId);

  static Future<void> saveDeviceId(String deviceId) =>
      _storage.write(key: AuthStorageKeys.deviceId, value: deviceId);

  static Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: AuthStorageKeys.accessToken),
      _storage.delete(key: AuthStorageKeys.refreshToken),
      _storage.delete(key: AuthStorageKeys.userId),
    ]);
  }

  static Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // 이용약관 동의 여부 (최초 1회)
  static Future<bool> hasAgreedToTerms() async {
    final value = await _storage.read(key: 'terms_agreed');
    return value == 'true';
  }

  static Future<void> setTermsAgreed() async {
    await _storage.write(key: 'terms_agreed', value: 'true');
  }
}

// Plain Riverpod provider (no codegen)
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  return AuthStorage.isAuthenticated();
});
