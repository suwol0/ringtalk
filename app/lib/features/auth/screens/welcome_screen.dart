import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../widgets/terms_modal.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _onStart(BuildContext context) async {
    // 이미 약관에 동의했으면 바로 이동
    final alreadyAgreed = await AuthStorage.hasAgreedToTerms();
    if (alreadyAgreed) {
      if (context.mounted) context.push('/phone');
      return;
    }

    // 첫 실행: 약관 모달 표시
    if (!context.mounted) return;
    final agreed = await showTermsModal(context);
    if (!agreed) return;

    await AuthStorage.setTermsAgreed();
    if (context.mounted) context.push('/phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.bgDefault, AppColors.bgDeep],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Responsive.authMaxWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // ─── 로고 ─────────────────────────────────────────
                    Image.asset(
                      'assets/images/app_logo.png',
                      height: 88,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── 앱 이름 ──────────────────────────────────────
                    Text(
                      '링톡',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 44,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "마음이 '링'하는 순간, 링톡",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),

                    const Spacer(flex: 4),

                    // ─── 시작 버튼 ────────────────────────────────────
                    _StartButton(onPressed: () => _onStart(context)),

                    const SizedBox(height: 16),

                    // ─── 약관 안내 텍스트 ──────────────────────────────
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textDisabled,
                              height: 1.5,
                            ),
                        children: const [
                          TextSpan(text: '시작하면 '),
                          TextSpan(
                            text: '서비스 이용약관',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                          TextSpan(text: ' 및 '),
                          TextSpan(
                            text: '개인정보 처리방침',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.textSecondary,
                            ),
                          ),
                          TextSpan(text: '\n에 동의하는 것으로 간주됩니다.'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 시작 버튼 (로딩 상태 포함) ───────────────────────────────────────────────
class _StartButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  const _StartButton({required this.onPressed});

  @override
  State<_StartButton> createState() => _StartButtonState();
}

class _StartButtonState extends State<_StartButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await widget.onPressed();
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      child: _loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Text('전화번호로 시작하기'),
    );
  }
}
