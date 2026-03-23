import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/phone_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_room_screen.dart';
import '../../features/friends/screens/friend_profile_screen.dart';
import '../../features/friends/screens/friends_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../models/contact_model.dart';
import '../storage/auth_storage.dart';
import '../utils/responsive.dart';
import '../../shared/widgets/desktop_chat_layout.dart';
import '../../shared/widgets/main_shell.dart';

// ─── 인증 상태 변화를 GoRouter에 알리는 ChangeNotifier ───────────────────────
class _AuthNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _isAuthenticated = false;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  _AuthNotifier(this._ref) {
    _init();
    _ref.listen<AsyncValue<bool>>(isAuthenticatedProvider, (_, next) {
      _isLoading = next.isLoading;
      _isAuthenticated = next.valueOrNull ?? false;
      notifyListeners();
    });
  }

  Future<void> _init() async {
    _isAuthenticated = await AuthStorage.isAuthenticated();
    _isLoading = false;
    notifyListeners();
  }
}

// ─── GoRouter — 앱 수명 동안 단 한 번만 생성 ────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  final router = GoRouter(
    initialLocation: '/welcome',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // 인증 확인 중에는 리다이렉트 보류
      if (authNotifier.isLoading) return null;

      final loggedIn = authNotifier.isAuthenticated;
      final onAuthRoute = state.matchedLocation.startsWith('/welcome') ||
          state.matchedLocation.startsWith('/phone') ||
          state.matchedLocation.startsWith('/otp') ||
          state.matchedLocation.startsWith('/profile-setup');

      if (!loggedIn && !onAuthRoute) return '/welcome';
      if (loggedIn && onAuthRoute) return '/chats';
      return null;
    },
    routes: [
      // ─── 인증 ───────────────────────────────
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/phone', builder: (_, __) => const PhoneScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, String>;
          return OtpScreen(phone: extra['phone']!, deviceId: extra['deviceId']!);
        },
      ),
      GoRoute(path: '/profile-setup', builder: (_, __) => const ProfileSetupScreen()),

      // ─── 메인 (탭 셸) ───────────────────────
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/chats',
            builder: (context, __) {
              if (Responsive.isDesktop(context)) {
                return const DesktopChatLayout();
              }
              return const ChatListScreen();
            },
          ),
          GoRoute(
            path: '/chats/:roomId',
            builder: (_, state) {
              final roomId = state.pathParameters['roomId']!;
              final extra = state.extra as Map<String, String>?;
              return ChatRoomScreen(
                roomId: roomId,
                displayName: extra?['displayName'],
              );
            },
          ),
          GoRoute(path: '/friends', builder: (_, __) => const FriendsScreen()),
          GoRoute(
            path: '/friends/profile',
            builder: (_, state) {
              final contact = state.extra as RingTalkContact;
              return FriendProfileScreen(contact: contact);
            },
          ),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    authNotifier.dispose();
    router.dispose();
  });

  return router;
});
