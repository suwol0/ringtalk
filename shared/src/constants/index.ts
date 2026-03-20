// 앱 전역 상수

export const APP_NAME = '링톡';
export const APP_VERSION = '0.1.0';

// 인증
export const OTP_LENGTH = 6;
export const OTP_EXPIRES_IN = 180; // 3분 (초)
export const OTP_MAX_ATTEMPTS = 5;
export const OTP_RATE_LIMIT_WINDOW = 600; // 10분 (초)
export const OTP_RATE_LIMIT_MAX = 3; // 10분 내 최대 3번 요청

export const ACCESS_TOKEN_EXPIRES_IN = '15m';
export const REFRESH_TOKEN_EXPIRES_IN = '30d';

// 페이지네이션
export const DEFAULT_PAGE_SIZE = 30;
export const MAX_PAGE_SIZE = 100;
export const MESSAGE_PAGE_SIZE = 50;

// 메시지
export const MAX_MESSAGE_LENGTH = 5000;
export const MAX_FILE_SIZE_MB = 100;

// ══════════════════════════════════════════════════════════════
//  링톡 컬러 시스템 — 완전 라벤더·보라 유니버스
//  기준축: HSL 289° (Primary #B350CC)
//  원칙  : 파일 안 모든 색상이 보라(289°) 계열 DNA 보유
//          순수 흰색·무채색·원색 완전 배제
// ══════════════════════════════════════════════════════════════
export const Colors = {
  // ─── Primary (HSL 289°) ──────────────────────────────────────
  primary:        '#b350cc', // H:289 S:61% L:56% — 브랜드, CTA
  primaryHover:   '#bd66d2', // H:289 S:51% L:61% — hover·ripple
  primaryDark:    '#9a3db0', // H:289 S:48% L:46% — pressed
  primaryDeep:    '#7b2d9c', // H:289 S:55% L:39% — 강조 포인트
  primarySurface: '#f3e0fa', // H:289 S:70% L:93% — 뱃지·선택 배경

  // ─── Background (라벤더 스케일) ───────────────────────────────
  bgDefault: '#f6e9f9', // H:289 S:60% L:95% — 기본 스캐폴드
  bgDeep:    '#ecd3f2', // H:289 S:50% L:89% — 섹션 구분·그라데이션 끝
  bgTinted:  '#fef8ff', // H:289 S:100% L:99.5% — 보라 틴트 "화이트" (순수 흰색 대체)

  // ─── Surface (보라 틴트 화이트) ──────────────────────────────
  surfaceDefault: '#fef8ff', // = bgTinted — 카드·리스트
  surfaceSubtle:  '#f4ebf8', // H:289 S:45% L:95.5% — 입력 필드·태그
  surfaceOverlay: '#e8d4f0', // H:289 S:40% L:89% — hover·오버레이

  // ─── Text (보라-차콜 스케일) ─────────────────────────────────
  textPrimary:   '#1c0a24', // H:289 S:60% L:9%  — 헤더·중요 텍스트
  textSecondary: '#664d78', // H:289 S:23% L:39% — 본문·라벨
  textDisabled:  '#b09abe', // H:289 S:18% L:68% — 플레이스홀더·비활성
  textOnPrimary: '#ffffff',

  // ─── Border (보라 스케일) ─────────────────────────────────────
  borderDefault: '#caaad8', // H:289 S:30% L:75%
  borderSubtle:  '#e4d0ee', // H:289 S:35% L:88%

  // ─── Chat Bubble ──────────────────────────────────────────────
  bubbleMine:       '#b350cc', // = primary
  bubbleMineText:   '#ffffff',
  bubbleOther:      '#fef8ff', // = bgTinted (보라 틴트 화이트)
  bubbleOtherText:  '#1c0a24',
  bubbleSystem:     '#ede0f2',
  bubbleSystemText: '#664d78',

  // ─── Error — 포르쉐 레드 계열 ──────────────────────────────────
  error:      '#f51e0f', // 포르쉐 레드 (기준)
  errorLight: '#f86257', // 연한 레드 — 에러 배경·토스트
  errorDark:  '#dd1b0e', // 진한 레드 — pressed·강조

  // ─── Warning — 개나리 옐로 계열 ─────────────────────────────────
  //  라이트 배경 위 텍스트는 warningDark 사용 (대비 확보)
  warning:      '#ffef40', // 개나리 옐로 (기준)
  warningLight: '#fff479', // 연한 노랑 — 경고 배경·뱃지
  warningDark:  '#c8b800', // 진한 노랑 — 텍스트·아이콘

  // ─── Success / Info ──────────────────────────────────────────────
  success: '#2680a8', // 스틸 블루 — 성공, 완료
  info:    '#7c4dba', // 인디고 바이올렛 — 정보, 안내

  // ─── Presence ─────────────────────────────────────────────────────
  online:  '#2680a8', // = success
  offline: '#9e8aab', // 퍼플-그레이
  away:    '#ffef40', // = warning (개나리 옐로)
} as const;

// API 엔드포인트
export const ApiEndpoints = {
  auth: {
    requestOtp: '/auth/request-otp',
    verifyOtp: '/auth/verify-otp',
    refresh: '/auth/refresh',
    logout: '/auth/logout',
    sessions: '/auth/sessions',
  },
  users: {
    me: '/users/me',
    profile: (id: string) => `/users/${id}`,
    friends: '/users/me/friends',
    addFriend: '/users/me/friends',
    blockUser: (id: string) => `/users/${id}/block`,
    searchByPhone: '/users/search',
  },
  contacts: {
    sync: '/contacts/sync',
  },
  rooms: {
    list: '/rooms',
    create: '/rooms',
    detail: (id: string) => `/rooms/${id}`,
    messages: (id: string) => `/rooms/${id}/messages`,
    sendMessage: (id: string) => `/rooms/${id}/messages`,
    readMessage: (id: string) => `/rooms/${id}/read`,
  },
  chats: {
    list: '/chats',
    createDirect: '/chats/direct',
  },
  media: {
    upload: '/media/upload',
    presigned: '/media/presigned-url',
  },
} as const;

// WebSocket 이벤트
export const WsEvents = {
  // 연결
  CONNECT: 'connect',
  DISCONNECT: 'disconnect',
  AUTHENTICATE: 'authenticate',
  AUTHENTICATED: 'authenticated',

  // 메시지
  MESSAGE_SEND: 'message:send',
  MESSAGE_NEW: 'message:new',
  MESSAGE_STATUS: 'message:status',
  MESSAGE_DELIVERED: 'message:delivered',
  MESSAGE_DELETE: 'message:delete',
  MESSAGE_DELETED: 'message:deleted',

  // 읽음 처리
  CHAT_READ: 'chat.read',

  // 방
  ROOM_JOIN: 'room:join',
  ROOM_LEAVE: 'room:leave',
  ROOM_UPDATED: 'room:updated',

  // 유저 상태
  USER_TYPING_START: 'user:typing:start',
  USER_TYPING_STOP: 'user:typing:stop',
  USER_TYPING: 'user:typing',
  USER_PRESENCE: 'user:presence',
  USER_READ: 'user:read',
} as const;
