import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/socket_provider.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(socketServiceProvider).disconnect();
      await AuthStorage.clear();
      // mounted 체크 후 context 사용 (async gap 안전)
      if (context.mounted) context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSubtle,
      appBar: AppBar(title: const Text('설정')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.contentMaxWidth),
          child: ListView(
        children: [
          // 프로필 카드
          Container(
            color: AppColors.bgTinted,
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Text('나', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('내 프로필', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      SizedBox(height: 2),
                      Text('상태 메시지를 설정해 보세요', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _Section(title: '계정', items: [
            _MenuItem(icon: Icons.person_rounded, title: '프로필 편집', subtitle: '이름, 사진, 상태 메시지'),
            _MenuItem(icon: Icons.notifications_rounded, title: '알림 설정', subtitle: '소리, 배너, 진동'),
          ]),
          const SizedBox(height: 12),
          const _Section(title: '보안', items: [
            _MenuItem(icon: Icons.lock_rounded, title: '개인정보 보호', subtitle: '마지막 접속 공개 범위'),
            _MenuItem(icon: Icons.devices_rounded, title: '로그인된 기기', subtitle: '연결된 디바이스 관리'),
          ]),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Text('링톡 v0.1.0', style: TextStyle(fontSize: 12, color: AppColors.textDisabled)),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _logout(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(double.infinity, 48),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.6),
          ),
        ),
        Container(
          color: AppColors.bgTinted,
          child: Column(
            children: items.expand((item) => [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: AppColors.surfaceSubtle, borderRadius: BorderRadius.circular(8)),
                  child: Icon(item.icon, color: AppColors.primary, size: 20),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
                subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                onTap: () {},
              ),
              const Divider(indent: 68, height: 0),
            ]).toList()..removeLast(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title, subtitle;
  const _MenuItem({required this.icon, required this.title, required this.subtitle});
}
