import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../storage/auth_storage.dart';

const _baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);

final apiClient = _buildDio();

Dio _buildDio() {
  final dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // 요청 인터셉터: 액세스 토큰 자동 첨부
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await AuthStorage.getAccessToken();
      final deviceId = await AuthStorage.getDeviceId();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      if (deviceId != null) options.headers['X-Device-Id'] = deviceId;
      handler.next(options);
    },
    onError: (error, handler) async {
      // 401 → 리프레시 토큰으로 자동 갱신
      if (error.response?.statusCode == 401) {
        final refreshToken = await AuthStorage.getRefreshToken();
        final deviceId = await AuthStorage.getDeviceId();
        if (refreshToken == null || deviceId == null) {
          await AuthStorage.clear();
          return handler.next(error);
        }
        try {
          final res = await Dio().post(
            '$_baseUrl${ApiEndpoints.refresh}',
            data: {'refreshToken': refreshToken, 'deviceId': deviceId},
          );
          final data = res.data['data'];
          await AuthStorage.saveTokens(
            accessToken: data['accessToken'],
            refreshToken: data['refreshToken'],
          );
          // 원래 요청 재시도
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer ${data['accessToken']}';
          final retryRes = await dio.fetch(opts);
          return handler.resolve(retryRes);
        } catch (_) {
          await AuthStorage.clear();
          return handler.next(error);
        }
      }
      handler.next(error);
    },
  ));

  return dio;
}
