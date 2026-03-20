// Socket.IO 클라이언트 — access token 인증
//
// 연결 시 auth: { accessToken } 전달
// 서버에서 JWT 검증 + 세션 확인 후 연결 허용
// 인증 성공 시 'authenticated' 이벤트 수신

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/app_constants.dart';
import '../storage/auth_storage.dart';

/// Socket.IO 연결 관리 — access token 기반 인증
class SocketService {
  io.Socket? _socket;
  bool _isConnecting = false;

  /// 소켓 연결 직후 호출할 콜백 목록 (room:join 등 재등록에 사용)
  final List<VoidCallback> _onConnectCallbacks = [];

  io.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;

  void addOnConnectCallback(VoidCallback cb) => _onConnectCallbacks.add(cb);
  void removeOnConnectCallback(VoidCallback cb) => _onConnectCallbacks.remove(cb);

  /// access token으로 Socket.IO 연결
  Future<void> connect() async {
    if (_socket?.connected == true || _isConnecting) return;

    final token = await AuthStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint('[SocketService] 토큰 없음 — 연결 스킵');
      return;
    }

    _isConnecting = true;
    try {
      _socket = io.io(NetworkUrls.socketBase, _buildOptions(token));
      _setupListeners();
    } finally {
      _isConnecting = false;
    }
  }

  /// cascade(`..`)가 아닌 메서드 체이닝(`.`)으로 Map<String, dynamic> 반환
  Map<String, dynamic> _buildOptions(String token) => io.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .enableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(5)
      .setReconnectionDelay(1000)
      .setAuth({'accessToken': token})
      .build();

  void _setupListeners() {
    _socket!
      ..onConnect((_) {
        debugPrint('[SocketService] 연결됨');
        // 대기 중인 콜백 일괄 실행 (room:join 등 재구독)
        final callbacks = List<VoidCallback>.from(_onConnectCallbacks);
        for (final cb in callbacks) {
          cb();
        }
      })
      ..on(WsEvents.authenticated, (data) => debugPrint('[SocketService] 인증 완료: $data'))
      ..onConnectError((err) => debugPrint('[SocketService] 연결 실패: $err'))
      ..onDisconnect((reason) => debugPrint('[SocketService] 연결 해제: $reason'));
  }

  /// 연결 해제
  void disconnect() {
    _onConnectCallbacks.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  /// 토큰 갱신 후 재연결
  Future<void> reconnect() async {
    disconnect();
    await connect();
  }
}
