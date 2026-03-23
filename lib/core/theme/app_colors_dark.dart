import 'package:flutter/material.dart';
import 'app_colors.dart';

// ══════════════════════════════════════════════════════════════════
//  링톡 다크모드 컬러 시스템
//
//  라이트 모드의 라벤더 세계관을 유지하되,
//  배경을 "딥 퍼플 블랙" 계열로 반전시킨 다크 팔레트
//
//  Primary·Semantic 색상은 라이트와 동일 (AppColors 재사용)
//  Background·Surface·Text·Border만 다크 버전으로 재정의
//
//  ┌──────────────────────────────────────────────────────────────┐
//  │  다크 배경 스케일 (HSL 289° 기준, 명도만 반전)                │
//  │                                                              │
//  │  bgDefault  #140820  딥 퍼플 블랙 (기본 스캐폴드)            │
//  │  bgDeep     #0D0514  더 깊은 블랙 (섹션 구분)                │
//  │  bgTinted   #1C0A28  카드·모달 배경                          │
//  └──────────────────────────────────────────────────────────────┘
// ══════════════════════════════════════════════════════════════════
abstract class AppColorsDark {

  // ─── Primary — 라이트와 동일 (브랜드 불변) ──────────────────────────────────
  static const primary        = AppColors.primary;
  static const primaryHover   = AppColors.primaryHover;
  static const primaryDark    = AppColors.primaryDark;
  static const primaryDeep    = AppColors.primaryDeep;
  static const primarySurface = Color(0xFF2D1040); // 다크 위 뱃지 배경 (어두운 보라)

  // ─── Background (딥 퍼플 블랙 스케일) ───────────────────────────────────────
  static const bgDefault = Color(0xFF140820); // H:289 S:67% L:8%  — 기본 스캐폴드
  static const bgDeep    = Color(0xFF0D0514); // H:289 S:75% L:5%  — 섹션 구분·가장 깊은 배경
  static const bgTinted  = Color(0xFF1C0A28); // H:289 S:63% L:10% — 카드·모달 "어두운 화이트"

  // ─── Surface / Container ─────────────────────────────────────────────────────
  static const surfaceDefault = Color(0xFF1C0A28); // = bgTinted — 카드·리스트 아이템
  static const surfaceSubtle  = Color(0xFF251035); // H:289 S:55% L:14% — 입력 필드·태그
  static const surfaceOverlay = Color(0xFF321450); // H:289 S:59% L:20% — hover·오버레이

  // ─── Text (밝은 라벤더~흰색 스케일) ─────────────────────────────────────────
  static const textPrimary   = Color(0xFFF0E6F6); // H:289 S:60% L:93% — 헤더·중요 텍스트
  static const textSecondary = Color(0xFFB09ABE); // H:289 S:18% L:68% — 본문·라벨
  static const textDisabled  = Color(0xFF5A4466); // H:289 S:20% L:33% — 플레이스홀더·비활성
  static const textOnPrimary = Color(0xFFFFFFFF); // Primary 위 텍스트 (라이트와 동일)

  // ─── Border / Divider ────────────────────────────────────────────────────────
  static const borderDefault = Color(0xFF4A2E60); // H:289 S:35% L:28% — 입력 테두리
  static const borderSubtle  = Color(0xFF2E1848); // H:289 S:48% L:19% — 구분선·카드 테두리

  // ─── Chat Bubble ─────────────────────────────────────────────────────────────
  static const bubbleMine       = AppColors.primary;     // 내 말풍선 = Primary (불변)
  static const bubbleMineText   = Color(0xFFFFFFFF);
  static const bubbleOther      = Color(0xFF251035);     // = surfaceSubtle (어두운 카드)
  static const bubbleOtherText  = Color(0xFFF0E6F6);     // = textPrimary dark
  static const bubbleSystem     = Color(0xFF1E0D2C);     // 시스템 메시지 배경
  static const bubbleSystemText = Color(0xFFB09ABE);     // = textSecondary dark

  // ─── Semantic — 라이트와 동일 (의미색은 모드와 무관) ────────────────────────
  static const error        = AppColors.error;
  static const errorLight   = AppColors.errorLight;
  static const errorDark    = AppColors.errorDark;
  static const warning      = AppColors.warning;
  static const warningLight = AppColors.warningLight;
  static const warningDark  = AppColors.warningDark;
  static const success      = AppColors.success;
  static const info         = AppColors.info;

  // ─── Presence ────────────────────────────────────────────────────────────────
  static const online  = AppColors.online;
  static const offline = Color(0xFF6B5578); // 다크 위 퍼플-그레이 (밝게 조정)
  static const away    = AppColors.away;
}
