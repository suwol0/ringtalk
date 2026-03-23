import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: RingTalkApp()));
}

class RingTalkApp extends ConsumerWidget {
  const RingTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: '링톡',

      // 라이트 테마
      theme: AppTheme.light,

      // 다크 테마 — 기기 설정에 따라 자동 전환
      // 토대만 설정, 실제 다크모드 완성은 추후 진행
      darkTheme: AppTheme.dark,

      // 기기 시스템 설정을 따름 (light/dark 자동)
      themeMode: ThemeMode.system,

      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
