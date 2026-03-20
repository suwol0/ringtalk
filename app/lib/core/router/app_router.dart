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

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(isAuthenticatedProvider);

  // AsyncValue<bool> → bool (로딩 중엔 false로 처리)
  final isAuthenticated = authAsync.valueOrNull ?? false;

  return GoRouter(
    initialLocation: isAuthenticated ? '/chats' : '/welcome',
    redirect: (context, state) {
      final loggedIn = isAuthenticated;
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
              // 데스크톱에서는 2-패널 레이아웃, 모바일/태블릿은 목록만 표시
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
});
