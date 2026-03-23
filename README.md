<div align="center">
  <img src="./assets/logo.png" alt="링톡 로고" width="160" />
  <h1>🔔 링톡 (RingTalk)</h1>
  <p><strong>마음이 '링'하는 순간, 링톡</strong></p>
  <p>카카오톡을 겨냥한 메신저 앱 — <strong>모바일(iOS/Android) + PC(Windows/macOS) + Web</strong> 지원</p>

![CI](https://github.com/suwol0/ringtalk/actions/workflows/ci.yml/badge.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![NestJS](https://img.shields.io/badge/NestJS-10-E0234E?logo=nestjs)
![License](https://img.shields.io/badge/license-MIT-purple)

</div>

---

## 기술 스택

| 영역                   | 기술                        | 비고                                  |
| ---------------------- | --------------------------- | ------------------------------------- |
| 앱 (모바일 + PC + Web) | Flutter (Dart)              | iOS / Android / Windows / macOS / Web |
| 백엔드                 | NestJS (TypeScript)         | REST API                              |
| 실시간                 | Socket.IO                   | WebSocket                             |
| DB                     | PostgreSQL 15 + Prisma ORM  |                                       |
| 캐시/세션              | Redis 8 (ioredis)           | Rate Limit, OTP 저장                  |
| 인증                   | 전화번호 OTP + JWT          | Access 15분 / Refresh 30일            |
| 파일 스토리지          | AWS S3 + Presigned URL      | 서버 직접 중계 없음                   |
| 모노레포               | pnpm workspaces             |                                       |
| CI                     | GitHub Actions              | analyze + build + artifact            |

---

## 디렉토리 구조

```
ringtalk/
├── .github/
│   ├── workflows/
│   │   └── ci.yml                      # GitHub Actions CI (analyze · build · artifact)
│   └── pull_request_template.md        # PR 자동 템플릿
│
├── android/                            # Android 네이티브 (Flutter)
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/
│   │       └── main/
│   │           ├── AndroidManifest.xml
│   │           └── kotlin/com/ringtalk/ringtalk/
│   │               └── MainActivity.kt
│   ├── build.gradle.kts
│   └── settings.gradle.kts
│
├── ios/                                # iOS 네이티브 (Flutter)
│   └── Runner/
│       └── Info.plist                  # 권한 설정 (카메라, 사진, 마이크, 연락처)
│
├── lib/                                # Flutter Dart 소스
│   ├── main.dart                       # 앱 진입점 (ProviderScope, ThemeMode.system)
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart      # 앱 상수, API 엔드포인트, WS 이벤트명
│   │   │
│   │   ├── data/
│   │   │   └── upload_repository.dart  # S3 presign 요청 + 직접 PUT 업로드
│   │   │
│   │   ├── models/
│   │   │   ├── api_model.dart          # ApiResponse, ApiError 공통 모델
│   │   │   ├── auth_model.dart         # AuthTokens, RequestOtpRequest, VerifyOtpRequest
│   │   │   ├── chat_model.dart         # ChatRoom, Message, MessageType, MessageStatus
│   │   │   ├── contact_model.dart      # LocalContact, ProcessedContact, RingTalkContact
│   │   │   ├── user_model.dart         # UserProfile, UserStatus
│   │   │   └── models.dart             # 모델 barrel export
│   │   │
│   │   ├── network/
│   │   │   ├── api_client.dart         # Dio HTTP + 401 자동 토큰 갱신 인터셉터
│   │   │   ├── socket_service.dart     # Socket.IO 연결·인증·onConnectCallbacks 큐
│   │   │   └── socket_provider.dart    # Riverpod Provider (앱 수명 단일 인스턴스)
│   │   │
│   │   ├── router/
│   │   │   └── app_router.dart         # go_router + _AuthNotifier + refreshListenable
│   │   │
│   │   ├── storage/
│   │   │   └── auth_storage.dart       # flutter_secure_storage (토큰·userId·deviceId)
│   │   │
│   │   ├── theme/
│   │   │   ├── app_colors.dart         # 라이트 퍼플 컬러 팔레트
│   │   │   ├── app_colors_dark.dart    # 다크 딥퍼플 컬러 팔레트
│   │   │   └── app_theme.dart          # ThemeData light/dark
│   │   │
│   │   └── utils/
│   │       ├── phone_utils.dart        # 전화번호 E.164 정규화
│   │       ├── contact_hash_utils.dart # SHA-256 해시 변환
│   │       ├── date_utils.dart         # 날짜 포맷 (오늘/어제/날짜 구분)
│   │       ├── responsive.dart         # Responsive 유틸 (mobile/tablet/desktop 브레이크포인트)
│   │       └── utils.dart              # OTP 타이머, 전화번호 마스킹 등 공통 유틸
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   ├── welcome_screen.dart          # 시작 화면 (로고 + 시작하기)
│   │   │   │   ├── phone_screen.dart            # 전화번호 입력
│   │   │   │   ├── otp_screen.dart              # OTP 6자리 입력 (ConsumerStatefulWidget)
│   │   │   │   └── profile_setup_screen.dart    # 최초 프로필(이름) 설정
│   │   │   └── widgets/
│   │   │       └── terms_modal.dart             # 이용약관·개인정보 동의 모달
│   │   │
│   │   ├── chat/
│   │   │   ├── data/
│   │   │   │   ├── messages_repository.dart     # GET /chats/:id/messages (cursor 페이지네이션)
│   │   │   │   └── rooms_repository.dart        # GET /chats, POST /chats/direct
│   │   │   ├── providers/
│   │   │   │   ├── chat_room_provider.dart      # ChatRoomNotifier (메시지 목록, WS 구독, 재시도)
│   │   │   │   └── rooms_provider.dart          # RoomsNotifier (채팅 목록, message:new 실시간)
│   │   │   ├── screens/
│   │   │   │   ├── chat_list_screen.dart        # 채팅 목록 (unread 뱃지, 최근 메시지)
│   │   │   │   └── chat_room_screen.dart        # 채팅방 (메시지 리스트, 자동 스크롤, 업로드)
│   │   │   └── widgets/
│   │   │       ├── chat_input_bar.dart          # 입력창 + 📎 첨부 버튼 (이미지/파일)
│   │   │       ├── chat_room_tile.dart          # 채팅 목록 타일
│   │   │       ├── date_divider.dart            # 날짜 구분선
│   │   │       ├── empty_chats_view.dart        # 채팅 없음 빈 화면
│   │   │       └── message_bubble.dart          # 말풍선 (mine/other, 재시도 버튼, 읽음 상태)
│   │   │
│   │   ├── contacts/
│   │   │   ├── data/
│   │   │   │   └── contacts_repository.dart    # 연락처 권한 요청 + POST /contacts/sync
│   │   │   └── providers/
│   │   │       └── contacts_provider.dart      # 연락처 동기화 상태 Provider
│   │   │
│   │   ├── friends/
│   │   │   ├── data/
│   │   │   │   └── friends_repository.dart     # GET /users/me/friends
│   │   │   ├── providers/
│   │   │   │   └── friends_provider.dart       # FriendsNotifier (목록 조회·동기화)
│   │   │   ├── screens/
│   │   │   │   ├── friends_screen.dart         # 친구 목록 화면 (새로고침·동기화 AppBar)
│   │   │   │   └── friend_profile_screen.dart  # 친구 프로필 (채팅하기·차단)
│   │   │   └── widgets/
│   │   │       ├── empty_friends_view.dart     # 연락처 동기화 안내 빈 화면
│   │   │       ├── friend_tile.dart            # 친구 타일 (아바타·이름·채팅 버튼)
│   │   │       ├── friends_error_view.dart     # 에러 뷰 (재시도 버튼)
│   │   │       ├── friends_list_content.dart   # 친구 목록 리스트 + 당겨서 새로고침
│   │   │       ├── friends_loading_skeleton.dart # 스켈레톤 로딩 UI
│   │   │       └── sync_status_banner.dart     # 동기화 진행·완료·에러 배너
│   │   │
│   │   └── settings/
│   │       └── screens/
│   │           └── settings_screen.dart        # 설정 (프로필 카드·메뉴·로그아웃)
│   │
│   └── shared/
│       └── widgets/
│           ├── main_shell.dart                 # 탭 네비게이션 셸 (BottomBar ↔ NavigationRail)
│           └── desktop_chat_layout.dart        # 데스크톱 2-패널 레이아웃
│
├── web/                                # Web 플랫폼 설정 (Flutter)
├── macos/                              # macOS 네이티브 (Flutter)
├── windows/                            # Windows 네이티브 (Flutter)
├── assets/
│   └── images/                         # Flutter 앱 이미지 에셋
│
├── pubspec.yaml                        # Flutter 의존성 및 에셋 선언
│
├── server/                             # NestJS REST API 서버
│   ├── src/
│   │   ├── main.ts                     # 서버 진입점 (CORS, Prefix, Pipe, Filter, Interceptor)
│   │   ├── app.module.ts               # 루트 모듈
│   │   │
│   │   ├── auth/                       # 인증
│   │   │   ├── auth.controller.ts      # OTP 요청/검증, 토큰 갱신, 세션 관리
│   │   │   ├── auth.service.ts         # OTP 생성·검증, JWT 발급, 세션 저장
│   │   │   ├── auth.module.ts
│   │   │   ├── strategies/
│   │   │   │   └── jwt.strategy.ts     # Passport JWT 전략 + 세션 DB 검증
│   │   │   └── dto/
│   │   │       ├── request-otp.dto.ts
│   │   │       ├── verify-otp.dto.ts
│   │   │       └── refresh-token.dto.ts
│   │   │
│   │   ├── users/                      # 유저
│   │   │   ├── users.controller.ts     # GET/PATCH /users/me, 친구목록, 검색, 차단
│   │   │   ├── users.service.ts
│   │   │   ├── users.module.ts
│   │   │   └── dto/
│   │   │       ├── update-profile.dto.ts
│   │   │       └── search-by-phone.dto.ts
│   │   │
│   │   ├── contacts/                   # 연락처 동기화
│   │   │   ├── contacts.controller.ts  # POST /contacts/sync
│   │   │   ├── contacts.service.ts     # SHA-256 해시 IN 절 매칭, 친구 자동 등록
│   │   │   ├── contacts.module.ts
│   │   │   └── dto/
│   │   │       └── sync-contacts.dto.ts
│   │   │
│   │   ├── chats/                      # 채팅 HTTP API
│   │   │   └── chats.controller.ts     # GET /chats, POST /chats/direct, GET /chats/:id/messages
│   │   │
│   │   ├── rooms/                      # 채팅방 비즈니스 로직
│   │   │   ├── rooms.service.ts        # 채팅방 생성·조회, 참여자 관리
│   │   │   ├── rooms.module.ts
│   │   │   └── dto/
│   │   │       └── create-direct-room.dto.ts
│   │   │
│   │   ├── messages/                   # 메시지 비즈니스 로직
│   │   │   ├── messages.service.ts     # 메시지 저장, 읽음 처리($transaction), 포맷
│   │   │   └── messages.module.ts
│   │   │
│   │   ├── upload/                     # 파일 업로드 (S3 Presigned URL)
│   │   │   ├── upload.controller.ts    # POST /upload/presign
│   │   │   ├── upload.service.ts       # S3Client, getSignedUrl (5분 유효)
│   │   │   ├── upload.module.ts
│   │   │   └── dto/
│   │   │       └── get-upload-url.dto.ts # MIME 검증, 100MB 제한
│   │   │
│   │   ├── websocket/                  # Socket.IO 게이트웨이
│   │   │   ├── websocket.gateway.ts    # room:join/leave, message:send, chat.read, message:delivered
│   │   │   └── websocket.module.ts
│   │   │
│   │   └── common/                     # 공통 인프라
│   │       ├── decorators/
│   │       │   └── current-user.decorator.ts  # @CurrentUser() → JwtPayload
│   │       ├── filters/
│   │       │   └── http-exception.filter.ts   # 에러 응답 통일 (code·message·details)
│   │       ├── guards/
│   │       │   └── jwt-auth.guard.ts           # JWT Bearer 토큰 검증
│   │       ├── interceptors/
│   │       │   └── transform.interceptor.ts    # 응답 { success, data } 래핑
│   │       ├── prisma/
│   │       │   ├── prisma.service.ts           # PrismaClient + onModuleInit 연결
│   │       │   └── prisma.module.ts            # Global 모듈
│   │       └── redis/
│   │           ├── redis.service.ts            # get/set/del/setJson/getJson/incr
│   │           └── redis.module.ts             # Global 모듈
│   │
│   └── prisma/
│       ├── schema.prisma               # 8개 모델 (users·sessions·friends·rooms·messages 등)
│       └── seed.ts                     # 개발용 테스트 데이터
│
├── shared/                             # 서버 전용 TypeScript 공통 타입·상수·유틸
│   └── src/
│       ├── index.ts                    # barrel export
│       ├── constants/
│       │   └── index.ts                # ErrorCode, WsEvent 상수
│       ├── types/
│       │   ├── api.ts                  # ApiResponse, ApiError, PaginationMeta, ErrorCode
│       │   ├── auth.ts                 # OTP·JWT 관련 타입
│       │   ├── chat.ts                 # ChatRoom, Message, MessageType 공통 타입
│       │   └── user.ts                 # UserPublicProfile, UserStatus
│       └── utils/
│           ├── phone.ts                # E.164 정규화
│           └── date.ts                 # 날짜 포맷 유틸
│
├── docs/
│   └── chat.md                         # WebSocket 이벤트 명세
│
├── .github/
├── docker-compose.yml                  # PostgreSQL 15 + Redis 8
├── pnpm-workspace.yaml
└── turbo.json
```

---

## 빠른 시작

### 사전 요구사항

| 도구           | 버전   | 용도               |
| -------------- | ------ | ------------------ |
| Node.js        | >= 20  | 서버 런타임        |
| pnpm           | >= 9   | 패키지 매니저      |
| Flutter SDK    | >= 3.0 | 앱 개발            |
| Docker **또는** Homebrew | 최신 | PostgreSQL + Redis |
| Android Studio | 최신   | Android 에뮬레이터 |
| Xcode (macOS)  | >= 15  | iOS / macOS 빌드   |

### 1. 의존성 설치

```bash
# 서버 + 공유 패키지 (루트에서)
pnpm install

# Flutter 앱 (루트에서)
flutter pub get
```

### 2. 인프라 실행 (DB + Redis)

**Docker 사용 시**
```bash
docker-compose up -d
```

**Homebrew 사용 시 (macOS, Docker 없이)**
```bash
brew install postgresql@15 redis
brew services start postgresql@15
brew services start redis

# DB·유저 생성
createuser -s ringtalk
createdb -O ringtalk ringtalk_db
psql -U ringtalk -d ringtalk_db -c "ALTER USER ringtalk WITH PASSWORD 'password';"
```

### 3. 환경변수 설정

**서버**

```bash
cp server/.env.example server/.env
```

`server/.env`에서 반드시 수정할 항목:

```env
JWT_SECRET=<랜덤 32자 이상 문자열>
JWT_REFRESH_SECRET=<다른 랜덤 32자 이상 문자열>
DATABASE_URL="postgresql://ringtalk:password@localhost:5432/ringtalk_db"
OTP_MOCK=true         # 개발 중 SMS 없이 콘솔에서 OTP 확인
OTP_MOCK_CODE=123456  # 개발 시 고정 OTP 코드 (OTP_MOCK=true 일 때만 적용)

# 파일 업로드 (S3 Presigned URL)
AWS_REGION=ap-northeast-2
AWS_ACCESS_KEY_ID=<AWS 액세스 키>
AWS_SECRET_ACCESS_KEY=<AWS 시크릿 키>
S3_BUCKET_NAME=<버킷 이름>
```

**Flutter 앱**

```bash
# app/.env 파일 생성
cat > app/.env << 'EOF'
API_URL=http://localhost:3000/api/v1
WS_URL=ws://localhost:3000
OTP_MOCK=true
EOF
```

> `app/.env`는 `.gitignore` 대상입니다. 실제 서버 주소로 변경해 사용하세요.

### 4. DB 스키마 적용

```bash
cd server

# 신규 환경 (마이그레이션 이력 없는 경우)
pnpm prisma db push

# 기존 마이그레이션 환경
pnpm db:migrate    # prisma migrate dev
pnpm db:generate   # Prisma 클라이언트 재생성
```

### 5. 개발 서버 실행

```bash
# NestJS 서버 (server/ 디렉토리에서)
cd server && pnpm dev          # nest start --watch

# Flutter 앱 (루트에서)
flutter run                    # 연결된 기기/시뮬레이터 자동 선택
flutter run -d chrome --web-port 8080  # 웹 (Chrome)
flutter run -d ios             # iOS 시뮬레이터
flutter run -d android         # Android 에뮬레이터
flutter run -d macos           # macOS 네이티브
flutter run -d windows         # Windows 네이티브
```

---

## 설치된 Flutter 패키지

| 패키지                   | 용도                                        |
| ------------------------ | ------------------------------------------- |
| `go_router`              | 라우팅 (ShellRoute 탭 네비게이션)           |
| `flutter_riverpod`       | 상태 관리                                   |
| `dio`                    | HTTP 클라이언트 + 401 자동 토큰 갱신        |
| `socket_io_client`       | Socket.IO 실시간 채팅                       |
| `flutter_secure_storage` | 토큰·userId·deviceId 보안 저장              |
| `cached_network_image`   | 프로필·미디어 이미지 캐싱                   |
| `shimmer`                | 스켈레톤 로딩 UI                            |
| `uuid`                   | 클라이언트 임시 메시지 ID (낙관적 업데이트) |
| `crypto`                 | 전화번호 SHA-256 해시                       |
| `flutter_contacts`       | 기기 연락처 읽기                            |
| `permission_handler`     | 권한 요청 (연락처·카메라·알림)              |
| `image_picker`           | 이미지·동영상 첨부 (갤러리/카메라)          |
| `file_picker`            | PDF 등 파일 첨부 (web withData 지원)        |
| `flutter_dotenv`         | 환경변수 (.env)                             |

## 네이티브 설정 (필수)

> ⚠️ `permission_handler` + `image_picker` 설치 후 **네이티브 설정 필수**:
>
> **Android** — `android/app/src/main/AndroidManifest.xml`:
>
> ```xml
> <uses-permission android:name="android.permission.READ_CONTACTS"/>
> <uses-permission android:name="android.permission.CAMERA"/>
> <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
> ```
>
> **iOS** — `ios/Runner/Info.plist`:
>
> ```xml
> <key>NSContactsUsageDescription</key>
> <string>친구를 찾기 위해 연락처 접근이 필요합니다.</string>
> <key>NSCameraUsageDescription</key>
> <string>프로필 사진·파일 첨부를 위해 카메라 접근이 필요합니다.</string>
> <key>NSPhotoLibraryUsageDescription</key>
> <string>사진 전송을 위해 사진 라이브러리 접근이 필요합니다.</string>
> ```

---

## 디자인 토큰 (퍼플 테마)

```
[Primary]
  primary        #B350CC   보라 (브랜드, CTA)
  primaryHover   #BD66D2   hover / ripple
  primaryDark    #9A3DB0   pressed
  primaryDeep    #7B2D9C   강조 포인트
  primarySurface #F3E0FA   뱃지·선택 배경

[라이트 모드 배경]
  bgDefault  #F6E9F9   기본 스캐폴드
  bgDeep     #ECD3F2   섹션 구분·그라데이션
  bgTinted   #FEF8FF   보라 틴트 화이트 (카드)

[다크 모드 배경]
  bgDefault  #140820   딥 퍼플 블랙
  bgDeep     #0D0514   더 깊은 블랙
  bgTinted   #1C0A28   다크 카드

[Semantic]
  error      #F51E0F + Light #F86257 + Dark #DD1B0E  포르쉐 레드
  warning    #FFEF40 + Light #FFF479 + Dark #C8B800  개나리 옐로
  success    #2680A8   스틸 블루
  info       #7C4DBA   인디고 퍼플
```

> 다크모드: `ThemeMode.system` — 기기 설정 자동 추적

---

## Auth API

| 메서드 | 엔드포인트                  | 인증 | 설명                    |
| ------ | --------------------------- | ---- | ----------------------- |
| POST   | `/api/v1/auth/request-otp`  | —    | OTP 발송                |
| POST   | `/api/v1/auth/verify-otp`   | —    | OTP 검증 + 토큰 발급    |
| POST   | `/api/v1/auth/refresh`      | —    | 액세스 토큰 갱신        |
| POST   | `/api/v1/auth/logout`       | 🔒   | 현재 기기 로그아웃      |
| GET    | `/api/v1/auth/sessions`     | 🔒   | 로그인 기기 목록        |
| DELETE | `/api/v1/auth/sessions/:id` | 🔒   | 특정 기기 강제 로그아웃 |

## Users API

| 메서드 | 엔드포인트               | 인증 | 설명                            |
| ------ | ------------------------ | ---- | ------------------------------- |
| GET    | `/api/v1/users/me`       | 🔒   | 내 프로필 조회                  |
| PATCH  | `/api/v1/users/me`       | 🔒   | 프로필 수정 (displayName·상태)  |
| GET    | `/api/v1/users/me/friends` | 🔒 | 친구 목록 (이름순, alias 우선)  |
| POST   | `/api/v1/users/search`   | 🔒   | 전화번호 해시로 유저 검색       |
| POST   | `/api/v1/users/:id/block`| 🔒   | 유저 차단                       |

## Contacts API

| 메서드 | 엔드포인트              | 인증 | 설명                                |
| ------ | ----------------------- | ---- | ----------------------------------- |
| POST   | `/api/v1/contacts/sync` | 🔒   | 연락처 해시 전송 → 친구 자동 등록  |

## Chats API

| 메서드 | 엔드포인트                       | 인증 | 설명                                                      |
| ------ | -------------------------------- | ---- | --------------------------------------------------------- |
| GET    | `/api/v1/chats`                  | 🔒   | 채팅 목록 (participants, lastMessage, unreadCount 포함)   |
| POST   | `/api/v1/chats/direct`           | 🔒   | 1:1 채팅방 생성 또는 기존 방 반환 (`{ participantId }`)  |
| GET    | `/api/v1/chats/:id/messages`     | 🔒   | 메시지 목록 (cursor·limit 페이지네이션)                   |

## Upload API

| 메서드 | 엔드포인트              | 인증 | 설명                                              |
| ------ | ----------------------- | ---- | ------------------------------------------------- |
| POST   | `/api/v1/upload/presign`| 🔒   | S3 Presigned PUT URL 발급 (5분 유효, 100MB 제한)  |

**요청 예시**
```json
{
  "fileName": "photo.jpg",
  "contentType": "image/jpeg",
  "fileSize": 1048576
}
```

**응답 예시**
```json
{
  "uploadUrl": "https://bucket.s3.ap-northeast-2.amazonaws.com/uploads/...",
  "fileUrl": "https://bucket.s3.ap-northeast-2.amazonaws.com/uploads/userId/timestamp-uuid.jpg",
  "key": "uploads/userId/timestamp-uuid.jpg",
  "expiresIn": 300
}
```

**허용 MIME 타입:** `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `video/mp4`, `video/quicktime`, `application/pdf`

**S3 Key 구조:** `uploads/{userId}/{timestamp}-{uuid}.{ext}`

> ⚠️ **S3 CORS 설정 필수** — 클라이언트가 직접 PUT 요청하므로 S3 버킷에 CORS 규칙(`PUT`, `Content-Type`, `Content-Length`)을 허용해야 합니다.

---

## CI (GitHub Actions)

```
PR / push → main, dev
    │
    ├── 🖥 server-check
    │     pnpm install → prisma generate → tsc shared → tsc server
    │
    ├── 🐦 flutter-check
    │     touch .env → flutter pub get → flutter analyze → flutter test
    │
    └── 🏗 flutter-build  (main push 시)
          touch .env → local.properties 생성 → flutter pub get
          → Android APK debug 빌드 → artifact 7일 보관
```

---

## 주차별 개발 로드맵

### ✅ 1주차: 아키텍처/기반 공사 + 인증 골격

- [x] pnpm 모노레포 구성 (`app/` · `server/` · `shared/`)
- [x] Flutter 앱 (iOS/Android/Windows/macOS/**Web** 단일 코드베이스)
- [x] NestJS 서버 골격 (전역 Prefix, ValidationPipe, ExceptionFilter, TransformInterceptor)
- [x] `shared` — TypeScript 공통 타입·상수·유틸 (ErrorCode, ApiResponse)
- [x] 퍼플 디자인 토큰 (라이트/다크 모드, warning 개나리·error 포르쉐 레드)
- [x] **다크모드** (`AppColorsDark` + `AppTheme.dark` + `ThemeMode.system`)
- [x] Auth API (OTP 요청/검증/갱신/로그아웃·세션 관리)
- [x] OTP Rate Limit (전화번호 + IP 이중 제한)
- [x] 디바이스별 세션 관리 (`user_sessions`)
- [x] Prisma 스키마 8개 모델 + Docker Compose
- [x] 로그인 화면 흐름 (Welcome → Phone → OTP → ProfileSetup)
- [x] **이용약관 + 개인정보처리방침 동의 모달** (최초 1회)
- [x] **GitHub Actions CI** (analyze + build + artifact)

---

### ✅ 2주차: 연락처/친구 + 1:1 채팅방 생성

- [x] **연락처 권한 처리** (permission_handler, iOS/Android/Web 분기)
- [x] **전화번호 E.164 정규화** (010-, 02-, +82- 등 다양한 포맷 지원)
- [x] **SHA-256 해시 변환** (서버로 원본 번호 전송 없이 프라이버시 보호)
- [x] **연락처 동기화 파이프라인** (100개 배치, 서버 IN 절 매칭)
- [x] **`POST /contacts/sync`** — 해시 전송 → 가입자 매칭 → 친구 자동 등록
- [x] **`GET /users/me/friends`** — 수락된 친구 목록 (이름순, 별명 우선)
- [x] **친구 목록 UI** — 동기화 상태 배너 + 친구 타일 + "채팅하기" 버튼 + 스켈레톤
- [x] **1:1 채팅방 생성** — `POST /chats/direct` (participants 유니크, 친구 관계 검증)
- [x] **채팅 목록** — `GET /chats` (최근 메시지, 안 읽음 뱃지)

### ✅ 3주차: 실시간 메시징 + ACK/읽음 + 반응형 레이아웃

- [x] **Socket.IO 게이트웨이 + JWT 인증** — handshake 시 `auth.accessToken` 검증
- [x] **`message:send` / `message:new` / `message:status` 이벤트** — DB 저장, 낙관적 업데이트
- [x] **`clientMessageId` 낙관적 업데이트** — 발신자 중복 방지
- [x] **읽음 처리 (`lastReadMessageId`)** — `chat.read` 이벤트, `MessageReadReceipt` DB 저장
- [x] **전송 실패 재시도 UX** — 10초 타임아웃 → `failed` 상태 + 재전송 버튼
- [x] **반응형 레이아웃** — mobile(`<600`) / tablet(`600~999`) / desktop(`≥1000`) 브레이크포인트
- [x] **데스크톱 2-패널 레이아웃** — `DesktopChatLayout`
- [x] **NavigationRail (태블릿/PC)** — `MainShell` 너비에 따라 자동 전환

#### 🔧 안정성 리팩토링 (3주차 후속)

- [x] **소켓 race condition 수정** — `onConnectCallbacks` 큐, 미연결 시 자동 재구독
- [x] **GoRouter 단일 인스턴스** — `_AuthNotifier + refreshListenable`, 재생성 방지
- [x] **`RoomsNotifier` 실시간 구독** — `message:new` 소켓 이벤트로 채팅 목록 실시간 반영
- [x] **메모리 누수 수정** — `then()` 콜백 `mounted` 체크, `dispose()` 소켓 `off()` + timer 취소
- [x] **자동 스크롤** — `ref.listen` 기반, 하단(80px) 위치 시 새 메시지 자동 스크롤
- [x] **OTP mock 코드 고정** — `OTP_MOCK_CODE` 환경변수 반영 (`123456` 고정 코드)
- [x] **인증 루프 버그 수정** — `ref.invalidate(isAuthenticatedProvider)` 로그인 직후 호출
- [x] **UI 가독성 개선** — 친구/설정 화면 텍스트 색상 명시 (`textPrimary` · `primaryDeep`)

---

### ✅ 4주차: 파일 업로드 (S3 Presigned URL)

- [x] **`POST /upload/presign`** — S3 Presigned PUT URL 발급 (5분 유효, 100MB 제한)
- [x] **MIME 타입 검증** — 허용 7종 (jpeg·png·gif·webp·mp4·mov·pdf)
- [x] **`UploadRepository` (Flutter)** — presign 요청 → S3 직접 PUT 업로드 (web·mobile 공통)
- [x] **`ChatInputBar` 📎 첨부 버튼** — 바텀시트 (이미지/동영상·파일 선택)
- [x] **업로드 프로그레스** — 업로드 중 LinearProgressIndicator + 입력 비활성화
- [x] **메시지 type 확장** — `sendMessage(type: 'image' | 'file')` 소켓 emit
- [ ] **이미지 버블 렌더링** — `MessageBubble`에 `cached_network_image` 이미지 표시
- [ ] **S3 CORS 설정** — 버킷 CORS 규칙 (PUT·Content-Type·Content-Length 허용)

### 5주차: 동영상 + 전송 품질

- [ ] 업로드 진행률(%) UI (`Dio onSendProgress`)
- [ ] 동영상 썸네일 추출 + 재생 플레이어
- [ ] 이미지 전송 전 클라 리사이징 (imageQuality 조정)
- [ ] 오프라인 메시지 큐 (네트워크 복구 후 자동 전송)
- [ ] WS 재연결 후 `room:join` 자동 재emit

### 6주차: 푸시 알림 + 멀티 디바이스 동기화

- [ ] FCM (Android) / APNs (iOS) 연동
- [ ] 포그라운드/백그라운드 알림 분기
- [ ] 커서 기반 메시지 동기화 API
- [ ] 멀티 디바이스 읽음 동기화

### 7주차: 기능 확장

- [ ] 그룹 채팅 생성 (`RoomType.group` 스키마 존재)
- [ ] 메시지 삭제 (`isDeleted`, `deletedFor` 스키마 존재, API/UI 없음)
- [ ] 친구 요청/수락 플로우 (`FriendStatus.pending` 스키마 존재, 현재 즉시 accepted)
- [ ] 차단 기능 UI (`POST /users/:id/block` API 존재, Flutter 미연동)
- [ ] 친구 별명(alias) 변경 (`Friend.alias` 스키마 존재)
- [ ] 프로필 사진 업로드 (S3 업로드 구조 활용)

### 8주차: 운영 필수 + UI 마감

- [ ] 메시지 무한 스크롤 (cursor 기반, 스크롤 상단 도달 시 이전 메시지 로드)
- [ ] 메시지 전송 Rate Limit
- [ ] Bubble·Timestamp·읽음 뱃지 UI polish
- [ ] 에러 토스트 / 리트라이 UX
- [ ] OTP Twilio 실 SMS 발송 연동

### 9주차: 안정화 + 릴리즈 패키징

- [ ] 메시지 리스트 가상화 (`flutter_list_view`)
- [ ] Sentry 연동 (Flutter + NestJS)
- [ ] Android / iOS 스토어 빌드 서명
- [ ] iOS 빌드 CI 잡 추가
- [ ] 서버 Docker 이미지 빌드 + CD 파이프라인

---

### 🚨 당장 해야 하는 것 (P0 — 보안/기능 크리티컬)

- [ ] **로그아웃 시 서버 API 호출** — `settings_screen.dart`가 `AuthStorage.clear()`만 하고 `POST /auth/logout`을 호출하지 않아 서버 세션이 잔존 (보안)
- [ ] **프로필 설정 API 연동** — `profile_setup_screen.dart`의 이름 입력이 `Future.delayed`만 하고 `PATCH /users/me` 미호출 → 신규 유저 이름이 저장되지 않음
- [ ] **설정 화면 메뉴 연동** — "프로필 편집", "로그인된 기기", "알림", "개인정보 보호" 전부 빈 `onTap: () {}`
- [ ] **토큰 만료 감지** — `isAuthenticated()`가 토큰 존재 여부만 확인, 만료 체크 없음
- [ ] **OTP 실제 SMS 발송** — `OTP_MOCK=true` 환경에서만 동작, Twilio 미연동

### 🟠 단기 (P1 — UX/안정성)

- [ ] **채팅 목록 스켈레톤 UI** — `friends_screen`은 스켈레톤 있지만 `chat_list_screen`은 스피너만 사용
- [ ] **설정 화면 실제 프로필 표시** — 현재 이름·사진 하드코딩, `GET /users/me` 연동 필요
- [ ] **`unreadCount` 정확한 쿼리** — `MessageReadReceipt` 기반 정확한 카운트 필요
- [ ] **Presence(온라인 상태) 구현** — 서버가 모든 유저를 `'offline'`으로 하드코딩
- [ ] **토큰 갱신 후 WS 재연결** — Dio 401 처리 시 `socketService.reconnect()` 미호출
- [ ] **CI `--frozen-lockfile` 적용** — 현재 `--no-frozen-lockfile`로 의존성 버전 불일치 가능
- [ ] **CI 서버 단위 테스트 추가** — 현재 TypeScript 타입 체크만, NestJS `jest` 테스트 없음

---

## IA (화면/메뉴 구조)

**Auth Flow**

```
Welcome → 전화번호 입력 → OTP 인증 → 프로필 설정 → 메인
```

**메인 탭 (모바일)**

```
채팅
  ├── 채팅 목록
  └── 채팅방 (메시지 리스트 / 입력 / 📎 첨부)
친구
  ├── 친구 목록
  └── 친구 프로필 (채팅하기 / 차단)
설정
  ├── 계정 (번호 / 기기 목록)
  ├── 알림 on/off
  └── 차단 목록
```

**PC 레이아웃**

```
┌──────────┬───────────────────────────────┐
│ 사이드바  │           채팅방               │
│ (채팅목록)│   메시지 리스트                │
│          │   ───────────────────────────  │
│          │   [입력창] [📎 파일 첨부]       │
└──────────┴───────────────────────────────┘
```

---

## DB 스키마 (PostgreSQL)

Prisma 스키마 파일: `server/prisma/schema.prisma`

| 테이블                  | 설명                                       |
| ----------------------- | ------------------------------------------ |
| `users`                 | 유저 (전화번호 E.164 + SHA-256 해시 저장)  |
| `user_sessions`         | 디바이스별 로그인 세션 (refreshToken 저장) |
| `otp_records`           | OTP 발급 이력 (현재 Redis 메인 사용)       |
| `friends`               | 친구 관계 (pending/accepted/blocked)       |
| `chat_rooms`            | 채팅방 (direct/group)                      |
| `room_participants`     | 참여자 (마지막 읽음, 뮤트)                 |
| `messages`              | 메시지 (clientMessageId, 소프트 삭제)      |
| `message_read_receipts` | 읽음 영수증                                |

---

## WebSocket (Socket.IO)

**연결 URL:** `http://localhost:3000` (API 서버와 동일 포트, path: `/socket.io`)

**인증:** 연결 시 `auth` 객체에 `accessToken` 전달

```javascript
import { io } from 'socket.io-client';
const socket = io('http://localhost:3000', {
  auth: { accessToken: '<JWT>' },
});
socket.on('authenticated', (data) => console.log('인증 완료:', data.userId));
```

**Flutter 클라이언트**
- `SocketService` — access token으로 연결, `NetworkUrls.socketBase` 사용
- `MainShell.initState()`에서 `connect()`, `dispose()`에서 `disconnect()` (메모리 누수 방지)
- `onConnectCallbacks` 큐 — 소켓 미연결 시 구독 대기, 연결 완료 후 자동 실행 (race condition 대응)

---

## WebSocket 이벤트

### 클라 → 서버

| 이벤트              | 페이로드                                          | 설명                |
| ------------------- | ------------------------------------------------- | ------------------- |
| (연결 시)           | `auth: { accessToken }`                           | WS 인증 (handshake) |
| `room:join`         | `{ roomId }`                                      | 채팅방 입장         |
| `room:leave`        | `{ roomId }`                                      | 채팅방 퇴장         |
| `message:send`      | `{ roomId, clientMessageId, content, type? }`     | 메시지 전송         |
| `message:delivered` | `{ messageId, roomId }`                           | 수신 확인           |
| `chat.read`         | `{ roomId, lastReadMessageId? }`                  | 읽음 처리           |

### 서버 → 클라

| 이벤트           | 페이로드                                                                              | 설명                           |
| ---------------- | ------------------------------------------------------------------------------------- | ------------------------------ |
| `authenticated`  | `{ userId }`                                                                          | 인증 완료                      |
| `message:new`    | `{ message, clientMessageId? }`                                                       | 새 메시지 (room 전체 브로드)   |
| `message:status` | `{ clientMessageId, status, messageId }` / `{ status:'read', readBy, lastReadMessageId }` | ACK / 읽음 알림            |
| `chat.read`      | `{ roomId, userId, readAt, lastReadMessageId? }`                                      | 읽음 동기화 (room 전체 브로드) |
| `error`          | `{ code, message }`                                                                   | 오류                           |

**메시지 상태 흐름**

```
sending → (socket emit) → sent → delivered → read
    └─ 10초 타임아웃 → failed → (재시도 버튼) → sending
```

> `clientMessageId(uuid)` — 낙관적 업데이트용. `message:new`에 포함되어 발신자 중복 방지.
> `lastReadMessageId` — 해당 메시지까지 읽음 처리. 없으면 방 전체 읽음.

---

## 파일 업로드 흐름 (S3 Presigned URL)

```
사용자 파일 선택 (image_picker / file_picker)
    │
    ▼  UploadRepository.uploadBytes()
    │
    ├── POST /api/v1/upload/presign
    │     { fileName, contentType, fileSize }
    │     ↓
    │     { uploadUrl, fileUrl, key, expiresIn }
    │
    └── PUT {uploadUrl}  ← S3 직접 업로드 (서버 거치지 않음)
          Headers: Content-Type, Content-Length
          Body: 파일 바이트
    │
    ▼  socket.emit('message:send')
          { roomId, clientMessageId, content: fileUrl, type: 'image' | 'file' }
```

---

## 연락처 동기화 파이프라인

```
기기 연락처 (LocalContact)
    │
    ▼  phone_utils.normalizeContactNumbers()
    │
    │  010-1234-5678    →  +821012345678  ✅
    │  010 1234 5678    →  +821012345678  ✅
    │  02-123-4567      →  +82212345678   ✅
    │  +82-10-1234-5678 →  +821012345678  ✅
    │  잘못된 번호        →  (제외)         ❌
    │
    ▼  contact_hash_utils.hashPhoneE164()  [SHA-256]
    │
ProcessedContact { e164Number, phoneHash(SHA-256) }
    │
    ▼  100개 배치 → POST /contacts/sync { phoneHashes: [...] }
    │
    ▼  서버: WHERE phoneHash IN (클라이언트 해시 목록)
    │
RingTalkContact { local, profile? }
    ├── isOnRingTalk == true  → 링톡 친구 목록
    └── isOnRingTalk == false → 초대 가능 목록
```

**프라이버시 설계**: 서버는 원본 전화번호를 수신하지 않습니다.
클라이언트가 SHA-256 해시만 전송하고 서버도 동일 방식으로 저장하여 IN 절 매칭.
