import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/models.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/auth_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/utils.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String deviceId;
  const OtpScreen({super.key, required this.phone, required this.deviceId});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _otpLength = AppConstants.otpLength;
  static const _expireSec = AppConstants.otpExpiresInSeconds;

  final _controllers = List.generate(_otpLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  bool _isLoading = false;
  String? _error;
  int _timeLeft = _expireSec;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer.cancel();
      }
    });
  }

  String _formatTime(int sec) => formatOtpTimer(sec);
  String _maskPhone(String phone) => maskPhoneNumber(phone);

  String get _currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      default:
        return 'web';
    }
  }

  void _onDigitChange(String value, int index) {
    final digit = value.replaceAll(RegExp(r'\D'), '');
    if (digit.isEmpty) return;

    _controllers[index].text = digit[digit.length - 1];
    if (index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
      final otp = _controllers.map((c) => c.text).join();
      if (otp.length == _otpLength) {
        _verify(otp);
      }
    }
  }

  // Flutter 3.18+ 새 키보드 API 사용
  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify(String otp) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await apiClient.post(
        ApiEndpoints.verifyOtp,
        data: VerifyOtpRequest(
          phoneNumber: widget.phone,
          otp: otp,
          deviceId: widget.deviceId,
          deviceName: 'Flutter Device',
          platform: _currentPlatform,
        ).toJson(),
      );

      final tokens = AuthTokens.fromJson(res.data['data'] as Map<String, dynamic>);
      await AuthStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      if (tokens.userId != null) {
        await AuthStorage.saveUserId(tokens.userId!);
      }

      if (mounted) {
        if (tokens.isNewUser) {
          context.go('/profile-setup');
        } else {
          context.go('/chats');
        }
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] as String? ?? 'OTP 인증에 실패했습니다.';
      setState(() => _error = msg);
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await apiClient.post(
        ApiEndpoints.requestOtp,
        data: RequestOtpRequest(
          phoneNumber: widget.phone,
          deviceId: widget.deviceId,
          platform: _currentPlatform,
        ).toJson(),
      );
      setState(() {
        _timeLeft = _expireSec;
        _error = null;
      });
      _timer.cancel();
      _startTimer();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['error']?['message'] as String? ?? '재발송 실패');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDefault,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton()),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Responsive.authMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('인증번호 입력', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: _maskPhone(widget.phone),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: '\n으로 발송된 6자리 인증번호를 입력하세요.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      _otpLength,
                      (i) => _OtpBox(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        onChanged: (v) => _onDigitChange(v, i),
                        onKeyEvent: (e) => _onKeyEvent(e, i),
                        enabled: !_isLoading,
                        autoFocus: i == 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _timeLeft > 0
                          ? RichText(
                              text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                                children: [
                                  const TextSpan(text: '남은 시간: '),
                                  TextSpan(
                                    text: _formatTime(_timeLeft),
                                    style: const TextStyle(
                                        color: AppColors.primary, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            )
                          : const Text('인증번호가 만료되었습니다.',
                              style: TextStyle(color: AppColors.error, fontSize: 13)),
                      TextButton(
                        onPressed: _timeLeft <= 150 ? _resend : null,
                        style: TextButton.styleFrom(
                          side: BorderSide(
                            color: _timeLeft <= 150 ? AppColors.primary : AppColors.borderDefault,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        ),
                        child: const Text('재발송'),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  ],
                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ],
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
    _timer.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;
  final bool enabled;
  final bool autoFocus;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
    required this.enabled,
    required this.autoFocus,
  });

  @override
  Widget build(BuildContext context) {
    // OTP 박스 너비: 화면 너비 기반 비율 계산 (최소 40, 최대 56)
    final screenW = MediaQuery.sizeOf(context).width;
    final availableW = (screenW.clamp(0, Responsive.authMaxWidth) - 48); // horizontal padding 24*2
    final boxW = (availableW / 6 - 4).clamp(40.0, 56.0); // 6칸, gap 4
    final boxH = boxW * 1.2;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: onKeyEvent,
      child: SizedBox(
        width: boxW,
        height: boxH,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autoFocus,
          enabled: enabled,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          onChanged: onChanged,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color:
                    controller.text.isNotEmpty ? AppColors.primary : AppColors.borderDefault,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surfaceDefault,
          ),
        ),
      ),
    );
  }
}
