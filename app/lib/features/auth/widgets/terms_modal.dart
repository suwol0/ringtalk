import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 서비스 이용약관 + 개인정보처리방침 동의 모달
/// 처음 1회만 표시, 동의 완료 시 [true] 반환
Future<bool> showTermsModal(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => const _TermsSheet(),
  );
  return result ?? false;
}

class _TermsSheet extends StatefulWidget {
  const _TermsSheet();

  @override
  State<_TermsSheet> createState() => _TermsSheetState();
}

class _TermsSheetState extends State<_TermsSheet> {
  bool _agreeService = false;
  bool _agreePrivacy = false;

  bool get _allAgreed => _agreeService && _agreePrivacy;

  void _toggleAll(bool value) {
    setState(() {
      _agreeService = value;
      _agreePrivacy = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.bgTinted,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── 핸들 바 ────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ─── 제목 + 기능 소개 ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '링톡 서비스 시작 전\n약관 동의가 필요해요',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '필수 항목에 동의하셔야 서비스를 이용하실 수 있습니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 20),

                // ─── 서비스 기능 소개 카드 ─────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Column(
                    children: [
                      _FeatureItem(
                        icon: Icons.lock_rounded,
                        title: '엔드투엔드 암호화',
                        desc: '모든 메시지는 발신자와 수신자만 읽을 수 있습니다.',
                      ),
                      SizedBox(height: 12),
                      _FeatureItem(
                        icon: Icons.bolt_rounded,
                        title: '실시간 메시지',
                        desc: 'Socket.IO 기반으로 지연 없이 즉시 전달됩니다.',
                      ),
                      SizedBox(height: 12),
                      _FeatureItem(
                        icon: Icons.devices_rounded,
                        title: '모바일 · PC 동기화',
                        desc: 'iOS, Android, Windows, macOS, 웹에서 동시 사용 가능합니다.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),

          // ─── 전체 동의 ───────────────────────────────────────────
          _AgreeTile(
            label: '전체 동의',
            sublabel: '서비스 이용약관, 개인정보 처리방침 (필수)',
            checked: _allAgreed,
            bold: true,
            onTap: () => _toggleAll(!_allAgreed),
          ),
          const Divider(height: 1, indent: 24, endIndent: 24),

          // ─── 개별 항목 ───────────────────────────────────────────
          _AgreeTile(
            label: '[필수] 서비스 이용약관',
            checked: _agreeService,
            onTap: () => setState(() => _agreeService = !_agreeService),
            onViewTap: () => _showDetail(context, _serviceTermsContent, '서비스 이용약관'),
          ),
          _AgreeTile(
            label: '[필수] 개인정보 처리방침',
            checked: _agreePrivacy,
            onTap: () => setState(() => _agreePrivacy = !_agreePrivacy),
            onViewTap: () => _showDetail(context, _privacyContent, '개인정보 처리방침'),
          ),

          const SizedBox(height: 20),

          // ─── 동의 버튼 ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              onPressed: _allAgreed
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: AppColors.borderDefault,
                disabledForegroundColor: AppColors.textDisabled,
              ),
              child: const Text('동의하고 시작하기'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, String content, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgTinted,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(24),
                child: Text(
                  content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.7,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 체크 타일 컴포넌트 ──────────────────────────────────────────────────────
class _AgreeTile extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool checked;
  final bool bold;
  final VoidCallback onTap;
  final VoidCallback? onViewTap;

  const _AgreeTile({
    required this.label,
    required this.checked,
    required this.onTap,
    this.sublabel,
    this.bold = false,
    this.onViewTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            // 체크박스
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: checked ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: checked ? AppColors.primary : AppColors.borderDefault,
                  width: 2,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            // 라벨
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sublabel!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            // 전문 보기
            if (onViewTap != null)
              GestureDetector(
                onTap: onViewTap,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '보기',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 기능 소개 아이템 ─────────────────────────────────────────────────────────
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureItem({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 약관 내용 ───────────────────────────────────────────────────────────────
const _serviceTermsContent = '''
제1조 (목적)
이 약관은 링톡(이하 "서비스")이 제공하는 메신저 서비스의 이용 조건 및 절차, 이용자와 링톡 간의 권리·의무 및 책임사항에 관한 기본적인 사항을 규정함을 목적으로 합니다.

제2조 (서비스의 제공)
① 링톡은 전화번호 인증을 통해 회원가입 및 로그인을 제공합니다.
② 서비스는 모바일(iOS, Android) 및 데스크톱(Windows, macOS), 웹을 통해 이용하실 수 있습니다.
③ 서비스는 메시지 송수신, 파일 전송, 친구 추가 등의 기능을 제공합니다.

제3조 (이용자의 의무)
① 이용자는 타인의 정보를 도용하거나 허위 정보를 등록해서는 안 됩니다.
② 이용자는 서비스를 불법적인 목적으로 사용하거나 타인에게 피해를 줄 수 있는 행위를 해서는 안 됩니다.
③ 스팸, 음란물, 혐오 발언 등의 내용을 전송하는 행위는 금지됩니다.

제4조 (서비스 이용 제한)
링톡은 이용자가 본 약관을 위반하거나 서비스 운영을 방해하는 경우 서비스 이용을 제한할 수 있습니다.

제5조 (면책 사항)
링톡은 천재지변, 시스템 장애 등 불가항력적인 사유로 인한 서비스 장애에 대해 책임을 지지 않습니다.

제6조 (약관의 변경)
링톡은 관련 법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있으며, 변경 시 앱 내 공지를 통해 안내합니다.
''';

const _privacyContent = '''
링톡 개인정보 처리방침

1. 수집하는 개인정보 항목
- 필수: 전화번호, 기기 식별자(Device ID), 플랫폼 정보(iOS/Android/PC)
- 선택: 프로필 사진, 상태 메시지

2. 개인정보 수집 및 이용 목적
- 본인 확인 및 로그인(OTP 인증)
- 친구 찾기(전화번호 해시 기반 매칭)
- 메시지 서비스 제공
- 서비스 개선 및 오류 분석
- 푸시 알림 발송

3. 개인정보 보유 및 이용 기간
- 회원 탈퇴 시 즉시 삭제 (단, 법령에 의해 보존이 필요한 경우 해당 기간 보관)
- 전화번호는 SHA-256 해시값으로 변환하여 저장 (원문 복원 불가)

4. 개인정보의 제3자 제공
링톡은 이용자의 개인정보를 원칙적으로 제3자에게 제공하지 않습니다.
단, 이용자의 동의가 있거나 법령에 의한 경우 예외로 합니다.

5. 개인정보 처리 위탁
링톡은 서비스 향상을 위해 일부 업무를 외부에 위탁할 수 있으며,
위탁 시 관련 법령에 따라 안전하게 관리합니다.

6. 이용자의 권리
이용자는 언제든지 자신의 개인정보를 조회·수정·삭제하거나
처리 정지를 요청할 수 있습니다.

7. 개인정보 보호책임자
개인정보 관련 문의: contact@ringtalk.app
''';
