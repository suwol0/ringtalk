import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _complete() async {
    if (_nameCtrl.text.trim().isEmpty || _isLoading) return;
    setState(() => _isLoading = true);
    // TODO: 프로필 업데이트 API 연동
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go('/chats');
  }

  @override
  Widget build(BuildContext context) {
    final hasName = _nameCtrl.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Responsive.authMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // 아바타
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceSubtle,
                      border: Border.all(color: AppColors.borderSubtle, width: 2),
                    ),
                    child: const Icon(Icons.person_rounded, size: 48, color: AppColors.textDisabled),
                  ),
                  const SizedBox(height: 20),
                  Text('링톡에 오신 것을 환영해요!', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    '친구들에게 보여질 이름을 설정해 주세요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 40),
                  // 이름 입력
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    maxLength: 20,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: '이름 입력 (최대 20자)'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: hasName && !_isLoading ? _complete : null,
                    child: _isLoading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('완료'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
}
