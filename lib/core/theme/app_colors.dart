import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════
//  링톡 컬러 시스템
//
//  배경/Primary : 보라·라벤더 유니버스 (#B350CC 기준축 HSL 289°)
//  Warning      : 개나리 옐로 계열  (#FFEF40 ~)  — 쨍한 신호 노랑
//  Error        : 포르쉐 레드 계열  (#F51E0F ~)  — 강렬한 액션 레드
//  Success      : 스틸 블루        (#2680A8)     — 차분한 완료감
//  Info         : 인디고 퍼플      (#7C4DBA)     — 브랜드 계열 안내
//
//  ┌──────────────────────────────────────────────────────────────┐
//  │  Semantic 색상 팔레트                                         │
//  │                                                              │
//  │  🟣 Primary   #B350CC  보라      — 브랜드, 활성              │
//  │  🟡 Warning   #FFEF40  개나리    — 주의, 자리비움             │
//  │  🔴 Error     #F51E0F  포르쉐레드 — 오류, 위험               │
//  │  🔵 Success   #2680A8  스틸블루  — 성공, 온라인              │
//  │  💜 Info      #7C4DBA  인디고    — 정보, 안내                │
//  └──────────────────────────────────────────────────────────────┘
// ══════════════════════════════════════════════════════════════════
abstract class AppColors {

  // ─── Primary (HSL 289° 보라) ────────────────────────────────────────────────
  static const primary        = Color(0xFFB350CC); // H:289 S:61% L:56% — 브랜드, CTA
  static const primaryHover   = Color(0xFFBD66D2); // H:289 S:51% L:61% — hover·ripple
  static const primaryDark    = Color(0xFF9A3DB0); // H:289 S:48% L:46% — pressed
  static const primaryDeep    = Color(0xFF7B2D9C); // H:289 S:55% L:39% — 강조 포인트
  static const primarySurface = Color(0xFFF3E0FA); // H:289 S:70% L:93% — 뱃지·선택 배경

  // ─── Background (라벤더 스케일 — 유지) ──────────────────────────────────────
  static const bgDefault = Color(0xFFF6E9F9); // H:289 S:60% L:95% — 기본 스캐폴드
  static const bgDeep    = Color(0xFFECD3F2); // H:289 S:50% L:89% — 섹션 구분·그라데이션 끝
  static const bgTinted  = Color(0xFFFEF8FF); // H:289 S:100% L:99.5% — 보라 틴트 화이트

  // ─── Surface / Container (보라 틴트 화이트 — 유지) ──────────────────────────
  static const surfaceDefault = Color(0xFFFEF8FF); // = bgTinted — 카드·리스트 아이템
  static const surfaceSubtle  = Color(0xFFF4EBF8); // H:289 S:45% L:95.5% — 입력 필드·태그
  static const surfaceOverlay = Color(0xFFE8D4F0); // H:289 S:40% L:89% — hover·오버레이

  // ─── Text (보라-차콜 스케일 — 유지) ─────────────────────────────────────────
  static const textPrimary   = Color(0xFF1C0A24); // H:289 S:60% L:9%  — 헤더·중요 텍스트
  static const textSecondary = Color(0xFF664D78); // H:289 S:23% L:39% — 본문·라벨
  static const textDisabled  = Color(0xFFB09ABE); // H:289 S:18% L:68% — 플레이스홀더·비활성
  static const textOnPrimary = Color(0xFFFFFFFF); // Primary 위 텍스트

  // ─── Border / Divider (보라 스케일 — 유지) ──────────────────────────────────
  static const borderDefault = Color(0xFFCAAAD8); // H:289 S:30% L:75% — 입력 테두리
  static const borderSubtle  = Color(0xFFE4D0EE); // H:289 S:35% L:88% — 구분선·카드 테두리

  // ─── Chat Bubble (유지) ──────────────────────────────────────────────────────
  static const bubbleMine       = Color(0xFFB350CC); // = primary
  static const bubbleMineText   = Color(0xFFFFFFFF);
  static const bubbleOther      = Color(0xFFFEF8FF); // 보라 틴트 화이트
  static const bubbleOtherText  = Color(0xFF1C0A24);
  static const bubbleSystem     = Color(0xFFEDE0F2); // 라벤더
  static const bubbleSystemText = Color(0xFF664D78);

  // ─── Error — 포르쉐 레드 계열 ────────────────────────────────────────────────
  //  쨍하고 강렬한 액션 레드. 오류·실패·위험 상황에서 즉각적인 인지 유도.
  //  #F51E0F (기준) → 밝은 톤 #F86257 ~ 어두운 톤 #DD1B0E
  static const error      = Color(0xFFF51E0F); // 포르쉐 레드 (기준)
  static const errorLight = Color(0xFFF86257); // 연한 레드 — 에러 배경·토스트 배경
  static const errorDark  = Color(0xFFDD1B0E); // 진한 레드 — pressed·강조

  // ─── Warning — 개나리 옐로 계열 ──────────────────────────────────────────────
  //  쨍한 개나리 노랑. 주의·경고 상황에서 시선을 잡아끄는 신호색.
  //  #FFEF40 (기준) → 밝은 톤 #FFF479 ~ 어두운 톤 #C8B800
  //  주의: 매우 밝아 라이트 배경 위 텍스트로 쓸 때는 warningDark 사용
  static const warning      = Color(0xFFFFEF40); // 개나리 옐로 (기준)
  static const warningLight = Color(0xFFFFF479); // 연한 노랑 — 경고 배경·뱃지
  static const warningDark  = Color(0xFFC8B800); // 진한 노랑 — 라이트 배경 위 텍스트·아이콘

  // ─── Success — 스틸 블루 ─────────────────────────────────────────────────────
  //  차분하고 안정적인 완료감. 보라의 쿨한 보색 형제.
  static const success = Color(0xFF2680A8); // 스틸 블루 — 성공, 전송 완료

  // ─── Info — 인디고 퍼플 ──────────────────────────────────────────────────────
  //  브랜드(Primary) 직접 파생. 정보성 안내에 사용.
  static const info = Color(0xFF7C4DBA); // 인디고 바이올렛 — 정보, 안내

  // ─── Presence / Online Status ────────────────────────────────────────────────
  static const online  = Color(0xFF2680A8); // = success (스틸 블루)
  static const offline = Color(0xFF9E8AAB); // 퍼플-그레이
  static const away    = Color(0xFFFFEF40); // = warning (개나리 옐로 — 자리 비움)
}
