import 'dart:math';
import 'package:flutter/material.dart';

/// 반응형 브레이크포인트 상수 및 유틸리티
class Responsive {
  Responsive._();

  static const double _mobileBreak = 600;
  static const double _desktopBreak = 1000;

  // ── 판별 ─────────────────────────────────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < _mobileBreak;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= _mobileBreak && w < _desktopBreak;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _desktopBreak;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _mobileBreak;

  // ── 값 선택 ───────────────────────────────────────────────────────────────
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }

  // ── 레이아웃 최대 너비 ────────────────────────────────────────────────────
  /// 폼/인증 화면용 최대 너비
  static const double authMaxWidth = 480;

  /// 콘텐츠 화면(친구, 설정 등)용 최대 너비
  static const double contentMaxWidth = 680;

  /// 채팅방 화면용 최대 너비
  static const double chatRoomMaxWidth = 860;

  /// 채팅 사이드 패널 너비 (데스크톱 2-패널)
  static const double chatSidePanelWidth = 360;
}

/// 브레이크포인트에 따라 다른 위젯을 렌더링하는 레이아웃 위젯
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1000) return desktop;
        if (constraints.maxWidth >= 600) return tablet ?? desktop;
        return mobile;
      },
    );
  }
}

/// 화면 중앙 정렬 + 최대 너비 제한 래퍼
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = Responsive.contentMaxWidth,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// 말풍선 최대 너비 계산 (데스크톱에서 캡 적용)
double bubbleMaxWidth(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  if (Responsive.isDesktop(context)) {
    return min(screenWidth * 0.55, 520);
  }
  return screenWidth * 0.75;
}
