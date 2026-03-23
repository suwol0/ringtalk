// Socket.IO 서비스 Provider
//
// MainShell 진입 시 connect(), 로그아웃 시 disconnect() 호출

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'socket_service.dart';

final socketServiceProvider = Provider<SocketService>((_) => SocketService());
