<div align="center">
  <img src="./assets/logo.png" alt="링톡 로고" width="160" />
  <h1>🔔 링톡 (RingTalk)</h1>
  <p><strong>마음이 '링'하는 순간, 링톡</strong></p>
  <p>카카오톡을 겨냥한 메신저 앱 — <strong>모바일(iOS/Android) + PC(Windows/macOS)</strong> 지원</p>

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
| DB                     | PostgreSQL 16 + Prisma ORM  |                                       |
| 캐시/세션              | Redis 7 (ioredis)           | Rate Limit, 세션                      |
| 인증                   | 전화번호 OTP + JWT          | Access 15분 / Refresh 30일            |
| 파일 스토리지          | S3 호환 + Pre-signed URL    | 서버 직접 중계 없음                   |
| 모노레포               | pnpm workspaces + Turborepo |                                       |
| CI                     | GitHub Actions              | analyze + build                       |

---

## ⚠️ 명령어 실행 위치 (중요)

**`messenger`는 모노레포 루트입니다.** `android/` 폴더가 루트에 없습니다.

| 목적 | 올바른 경로 | 잘못된 예 |
|------|-------------|-----------|
| Android (gradlew) | `app/android/` | ~~`android/`~~ (없음) |
| Flutter 앱 | `app/` | ~~루트~~ |
| NestJS 서버 | `server/` | ~~루트~~ |

```bash
# ❌ 잘못됨 (루트에서)
cd android          # → cd: no such file or directory
./gradlew clean    # → zsh: no such file or directory

# ✅ 올바름
cd app/android
./gradlew clean

# 또는 루트에서 한 줄로
cd app/android && ./gradlew clean
```

루트 `package.json`에 편의 스크립트가 있습니다: `pnpm app:android:clean`, `pnpm app:android:build` 등.

---

## 디렉토리 구조

```
ringtalk/
├── .github/
│   ├── workflows/
│   │   └── ci.yml                 # GitHub Actions CI
│   └── pull_request_template.md   # PR 자동 템플릿
├── app/                    # Flutter — iOS / Android / Windows / macOS / Web
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/   (앱 상수, API 엔드포인트, WS 이벤트)
│   │   │   ├── models/      (Auth, User, Chat, Api Dart 모델)
│   │   │   ├── network/     (Dio HTTP, Socket.IO + onConnect 콜백 큐)
│   │   │   ├── router/      (go_router, _AuthNotifier + refreshListenable)
│   │   │   ├── storage/     (flutter_secure_storage)
│   │   │   ├── theme/       (AppColors, AppColorsDark, AppTheme)
│   │   │   └── utils/       (phone_utils, contact_hash_utils, date_utils, responsive)
│   │   ├── features/
│   │   │   ├── auth/        (screens/, widgets/)
│   │   │   ├── chat/        (data/, providers/, screens/, widgets/)
│   │   │   ├── contacts/    (연락처 동기화)
│   │   │   ├── friends/     (친구 목록)
│   │   │   └── settings/    (설정)
│   │   └── shared/widgets/  (MainShell 탭 네비게이션, DesktopChatLayout 2-패널)
│   └── pubspec.yaml
├── server/                 # NestJS API 서버
│   ├── src/
│   │   ├── auth/            (OTP, JWT, Passport 전략)
│   │   ├── users/           (프로필, 친구, 차단)
│   │   ├── contacts/       (연락처 동기화, syncContacts)
│   │   ├── chats/           (GET /chats, POST /chats/direct)
│   │   ├── rooms/           (RoomsService, CreateDirectRoomDto)
│   │   ├── websocket/       (Socket.IO Gateway, JWT 인증)
│   │   └── common/          (Prisma, Redis, Guards, Filters)
│   └── prisma/
│       └── schema.prisma    (9개 모델)
├── shared/                 # 서버 전용 TypeScript 공통 타입/상수/유틸
├── docker-compose.yml      # PostgreSQL 16 + Redis 7
├── turbo.json
└── pnpm-workspace.yaml
```

---

## 빠른 시작

### 사전 요구사항

| 도구           | 버전   | 용도               |
| -------------- | ------ | ------------------ |
| Node.js        | >= 20  | 서버 런타임        |
| pnpm           | >= 9   | 패키지 매니저      |
| Flutter SDK    | >= 3.0 | 앱 개발            |
| Docker         | 최신   | PostgreSQL + Redis |
| Android Studio | 최신   | Android 에뮬레이터 |
| Xcode (macOS)  | >= 15  | iOS / macOS 빌드   |

```bash
# pnpm 설치
npm install -g pnpm

# Flutter 설치 확인
flutter doctor
```

### 1. 의존성 설치

```bash
# 서버 + 공유 패키지
pnpm install

# Flutter 앱
cd app && flutter pub get
```

### 2. 인프라 실행 (DB + Redis)

```bash
docker-compose up -d

# 상태 확인
docker-compose ps
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
OTP_MOCK=true        # 개발 중 SMS 없이 콘솔에서 OTP 확인
```

**Flutter 앱**

```bash
# app/.env 파일 생성 (flutter_dotenv가 pubspec.yaml assets에서 읽음)
cat > app/.env << 'EOF'
API_URL=http://localhost:3000/api/v1
WS_URL=ws://localhost:3000
OTP_MOCK=true
EOF
```

> `app/.env`는 `.gitignore` 대상입니다. 실제 서버 주소로 변경해 사용하세요.

### 4. DB 마이그레이션 + 시드

```bash
cd server
pnpm db:generate   # Prisma 클라이언트 생성
pnpm db:migrate    # 마이그레이션 실행
pnpm db:seed       # 테스트 데이터 삽입
```

### 5. 개발 서버 실행

```bash
# NestJS 서버 (루트에서)
pnpm server

# Flutter 앱
cd app
flutter run                # 연결된 기기/시뮬레이터 자동 선택
flutter run -d chrome      # 웹 (Chrome)
flutter run -d ios         # iOS 시뮬레이터
flutter run -d android     # Android 에뮬레이터
flutter run -d macos       # macOS 네이티브
flutter run -d windows     # Windows 네이티브
```

---

## 설치된 Flutter 패키지

| 패키지                   | 용도                              |
| ------------------------ | --------------------------------- |
| `go_router`              | 라우팅 (ShellRoute 탭 네비게이션) |
| `flutter_riverpod`       | 상태 관리                         |
| `dio`                    | HTTP 클라이언트 + 자동 토큰 갱신  |
| `socket_io_client`       | Socket.IO 실시간 채팅             |
| `flutter_secure_storage` | 토큰·이용약관 동의 보안 저장      |
| `cached_network_image`   | 프로필·미디어 이미지 캐싱         |
| `shimmer`                | 스켈레톤 로딩 UI                  |
| `uuid`                   | 클라이언트 임시 메시지 ID         |
| `crypto`                 | 전화번호 SHA-256 해시             |
| `flutter_contacts`       | 기기 연락처 동기화                |
| `permission_handler`     | 권한 요청 (연락처/카메라/알림)    |
| `image_picker`           | 이미지 첨부 (4주차 예정)          |
| `file_picker`            | 파일 첨부 (4주차 예정)            |
| `flutter_dotenv`         | 환경변수 (.env)                   |

## 네이티브 설정 (필수)

> ⚠️ `permission_handler` 설치 후 **네이티브 설정 필수**:
>
> **Android** — `app/android/app/src/main/AndroidManifest.xml`:
>
> ```xml
> <uses-permission android:name="android.permission.READ_CONTACTS"/>
> <uses-permission android:name="android.permission.CAMERA"/>
> <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
> <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
> ```
>
> **iOS** — `app/ios/Runner/Info.plist`:
>
> ```xml
> <key>NSContactsUsageDescription</key>
> <string>친구를 찾기 위해 연락처 접근이 필요합니다.</string>
> <key>NSCameraUsageDescription</key>
> <string>프로필 사진 촬영을 위해 카메라 접근이 필요합니다.</string>
> <key>NSPhotoLibraryUsageDescription</key>
> <string>사진 전송을 위해 사진 라이브러리 접근이 필요합니다.</string>
> ```

### NestJS 서버

```bash
cd server

# 파일 업로드 (4주차)
pnpm add @aws-sdk/client-s3 @aws-sdk/s3-request-presigner
pnpm add multer @types/multer -D
```

---

## 디자인 토큰 (퍼플 테마)

```
[Primary]
  primary        #B350CC   보라 (브랜드, CTA)
  primaryHover   #BD66D2   hover / ripple
  primaryDark    #9A3DB0   pressed
  primaryDeep    #7B2D9C   강조 포인트
  primarySurface #F3E0FA   뱃지 배경

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

## Contacts API

| 메서드 | 엔드포인트                 | 인증 | 설명                                            |
| ------ | -------------------------- | ---- | ----------------------------------------------- |
| POST   | `/api/v1/contacts/sync`    | 🔒   | 연락처 해시 전송 → 친구 자동 등록               |
| GET    | `/api/v1/users/me/friends` | 🔒   | 수락된 친구 목록 (이름순, alias·phoneHash 포함) |

---

## Chats API

| 메서드 | 엔드포인트             | 인증 | 설명                                                          |
| ------ | ---------------------- | ---- | ------------------------------------------------------------- |
| GET    | `/api/v1/chats`        | 🔒   | 채팅 목록 (participants, lastMessage, unreadCount 포함)       |
| POST   | `/api/v1/chats/direct` | 🔒   | 1:1 채팅방 생성 또는 기존 방 반환 (body: `{ participantId }`) |

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

> `local.properties`는 `.gitignore` 대상이므로 CI에서 Flutter/Android SDK 경로를 동적으로 생성합니다.

---

## 주차별 개발 로드맵

### ✅ 1주차: 아키텍처/기반 공사 + 인증 골격

- [x] pnpm + Turborepo 모노레포
- [x] Flutter 앱 (iOS/Android/Windows/macOS/**Web** 단일 코드베이스)
- [x] NestJS 서버 골격
- [x] `shared` (TypeScript 공통 타입/상수/유틸)
- [x] 퍼플 디자인 토큰 (라이트/다크 모드, warning 개나리·error 포르쉐 레드)
- [x] **다크모드 토대** (`AppColorsDark` + `AppTheme.dark` + `ThemeMode.system`)
- [x] Auth API (OTP 요청/검증/갱신/로그아웃)
- [x] OTP Rate Limit (전화번호 + IP)
- [x] 디바이스별 세션 관리
- [x] Prisma 스키마 + Docker Compose
- [x] 로그인 화면 (Welcome → Phone → OTP → ProfileSetup)
- [x] **이용약관 + 개인정보처리방침 동의 모달** (최초 1회, 약관 전문 보기)
- [x] **GitHub Actions CI** (analyze + build + artifact)
- [x] **Flutter Web 플랫폼 추가** (PWA 메니페스트, 브랜딩 스플래시)

---

### 🚧 2주차: 연락처/친구 + 1:1 채팅방 생성

- [x] **연락처 권한 처리** (permission_handler, iOS/Android/Web 분기)
- [x] **전화번호 E.164 정규화** (010-, 02-, +82- 등 다양한 포맷)
- [x] **SHA-256 해시 변환** (서버로 원본 번호 전송 없이 프라이버시 보호)
- [x] **연락처 동기화 파이프라인** (100개 배치, 서버 IN 절 매칭)
- [x] **서버 phoneHash bcrypt → SHA-256** (결정론적 해시로 검색 가능)
- [x] **`POST /contacts/sync`** — 해시 전송 → 가입자 매칭 → 친구 자동 등록
- [x] **`GET /users/me/friends`** — 수락된 친구 목록 (이름순, 별명 우선)
- [x] **친구 목록 UI** — 동기화 상태 배너 + 친구 타일 + "채팅하기" 버튼
- [x] **`GET /users/me/friends`** — FriendsRepository, 화면 진입 시 서버에서 친구 목록 조회
- [x] **1:1 채팅방 생성** — `POST /chats/direct` (participants 유니크, 친구 관계 검증)
- [x] **채팅 목록** — `GET /chats` (최근 메시지, 안 읽음 뱃지, roomId 기반 화면)

### ✅ 3주차: 실시간 메시징 + ACK/읽음 + 반응형 레이아웃

- [x] **Socket.IO 게이트웨이 + JWT 인증** — handshake 시 `auth.accessToken` 검증, 세션 확인
- [x] **Flutter WS 인증** — SocketService, MainShell connect / dispose disconnect
- [x] **`message:send` / `message:new` / `message:status` 이벤트** — DB 저장, room 브로드캐스트, 낙관적 업데이트
- [x] **`clientMessageId` 낙관적 업데이트** — message:new에 clientMessageId 포함, 발신자 중복 방지
- [x] **읽음 처리 (`lastReadMessageId`)** — `chat.read` 이벤트, `MessageReadReceipt` DB 저장, `lastReadAt` 갱신, room 브로드캐스트, 채팅 목록 unreadCount 즉시 초기화
- [x] **전송 실패 재시도 UX** — 10초 타임아웃 → `failed` 상태, 말풍선 빨간 테두리 + 재전송 버튼
- [x] **반응형 레이아웃** — `Responsive` 유틸리티, mobile(`<600`) / tablet(`600~999`) / desktop(`≥1000`) 브레이크포인트
- [x] **데스크톱 2-패널 레이아웃** — `DesktopChatLayout` (채팅 목록 + 채팅방 동시 표시)
- [x] **NavigationRail (태블릿/PC)** — `MainShell`이 너비에 따라 BottomNavigationBar ↔ NavigationRail 자동 전환

#### 🔧 안정성 리팩토링 (3주차 후속)

- [x] **소켓 race condition 수정** — `SocketService`에 `onConnectCallbacks` 큐 추가, `ChatRoomNotifier` / `RoomsNotifier` 모두 소켓 미연결 시 onConnect 후 자동 재구독
- [x] **GoRouter 단일 인스턴스** — `_AuthNotifier + refreshListenable` 패턴, 인증 상태 변화 시 GoRouter 재생성 방지
- [x] **`RoomsNotifier` 실시간 구독** — `message:new` 소켓 이벤트 구독, 채팅 목록 `lastMessage` / `unreadCount` 실시간 반영
- [x] **메모리 누수 수정** — `then()` 콜백 내 `mounted` 체크, `dispose()` 시 소켓 리스너 `off()` + timer 취소
- [x] **자동 스크롤** — `ref.listen` 기반, 하단(80px 이내) 위치 시 새 메시지 도착에 자동 스크롤
- [x] **`_buildOptions()` 수정** — cascade(`..`) 오류 → 메서드 체이닝(`.`)으로 `Map<String, dynamic>` 올바르게 반환
- [x] **`.gitignore` 정리** — React Native / Expo / Tauri 관련 항목 제거 (Flutter 전용 프로젝트)

### 🚨 당장 해야 하는 것 (P0 — 보안/기능 크리티컬)

- [ ] **로그아웃 시 서버 API 호출** — `settings_screen.dart`가 `AuthStorage.clear()`만 하고 `POST /auth/logout`을 호출하지 않아 서버 세션이 잔존 (보안)
- [ ] **프로필 설정 API 연동** — `profile_setup_screen.dart`의 이름 입력이 `Future.delayed`만 하고 `PATCH /users/me` 미호출 → 신규 유저 이름이 저장되지 않음
- [ ] **설정 화면 메뉴 연동** — "프로필 편집", "로그인된 기기(`GET /auth/sessions`)", "알림", "개인정보 보호" 전부 빈 `onTap: () {}`
- [ ] **토큰 만료 감지** — `isAuthenticated()`가 토큰 존재 여부만 확인하고 만료 체크를 안 해 만료 토큰으로 WS 연결 시도 → 재연결 로직 없음
- [ ] **OTP 실제 SMS 발송** — `OTP_MOCK=true` 환경에서만 동작, Twilio 미연동 → 프로덕션 배포 불가

---

### 🟠 단기 (P1 — UX/안정성)

- [ ] **메시지 무한 스크롤** — `MessagesRepository`에 `cursor/limit` 파라미터 있고 서버도 구현됐지만, 스크롤 상단 도달 시 이전 메시지 로드 미구현
- [ ] **채팅방 AppBar 빈 버튼 처리** — 영상통화·음성통화 버튼 비활성화 또는 숨김, 더보기 버튼에 "알림 끄기 / 채팅방 나가기" 메뉴 추가
- [ ] **설정 화면 실제 프로필 표시** — 현재 이름·사진 전부 하드코딩, `GET /users/me`로 실제 유저 정보 표시
- [ ] **`unreadCount` 정확한 쿼리** — 현재 `lastMessage` 시간 비교로 0 또는 1만 반환, `MessageReadReceipt` 기반 정확한 카운트 필요
- [ ] **Presence(온라인 상태) 구현** — 서버가 모든 유저를 `'offline'`으로 하드코딩, `user:presence` WS 이벤트 실구현
- [ ] **토큰 갱신 후 WS 재연결** — Dio 인터셉터가 401 처리 시 `socketService.reconnect()` 미호출 → WS가 만료 토큰 상태 유지
- [ ] **채팅 목록 스켈레톤 UI** — `friends_screen`은 스켈레톤 있지만 `chat_list_screen`은 스피너만 사용
- [ ] **CI `--frozen-lockfile` 적용** — 현재 `--no-frozen-lockfile`로 의존성 버전 불일치 가능
- [ ] **CI 서버 단위 테스트 추가** — 현재 TypeScript 타입 체크만, NestJS `jest` 테스트 단계 없음

---

### 4주차: 첨부 파일 업로드 (Pre-signed)

- [ ] `POST /media/presign` → S3 Pre-signed URL 발급
- [ ] 클라이언트 직접 업로드 (서버 경유 없음)
- [ ] 이미지 썸네일 (클라 리사이징)
- [ ] 파일 검증 (확장자 / 사이즈 / MIME)
- [ ] `ChatInputBar`에 미디어 첨부 버튼 추가

### 5주차: 동영상 + 전송 품질

- [ ] 업로드 진행률 UI
- [ ] 동영상 썸네일 추출
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
- [ ] 프로필 사진 업로드

### 8주차: 운영 필수 + UI 마감

- [ ] 메시지 전송 Rate Limit
- [ ] Bubble, Timestamp, 읽음 뱃지 UI polish
- [ ] 에러 토스트 / 리트라이 UX
- [ ] `OtpRecord` DB 테이블 활용 또는 정리 (현재 Redis만 사용)
- [ ] OTP Twilio 실 SMS 발송 연동

### 9주차: 안정화 + 릴리즈 패키징

- [ ] 메시지 리스트 가상화 (`flutter_list_view`)
- [ ] Sentry 연동 (Flutter + NestJS)
- [ ] Android / iOS 스토어 빌드 서명
- [ ] iOS 빌드 CI 잡 추가
- [ ] 서버 Docker 이미지 빌드 + CD 파이프라인

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
  └── 채팅방 (메시지 리스트 / 입력 / 첨부)
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
│          │   [입력창] [파일 드래그&드롭]   │
└──────────┴───────────────────────────────┘
```

---

## DB 스키마 (PostgreSQL)

Prisma 스키마 파일: `server/prisma/schema.prisma`

| 테이블                  | 설명                                 |
| ----------------------- | ------------------------------------ |
| `users`                 | 유저 (전화번호 해시 저장)            |
| `user_sessions`         | 디바이스별 로그인 세션               |
| `otp_records`           | OTP 발급 이력                        |
| `friends`               | 친구 관계 (pending/accepted/blocked) |
| `chat_rooms`            | 채팅방 (direct/group)                |
| `room_participants`     | 참여자 (마지막 읽음, 뮤트)           |
| `messages`              | 메시지 (자기참조 답장, 소프트 삭제)  |
| `message_read_receipts` | 읽음 영수증                          |

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

- handshake 시 JWT 검증 + 세션 확인
- 인증 성공 시 `authenticated` 이벤트 emit
- 인증 실패 시 연결 거부

**Flutter 클라이언트**
- `SocketService` — access token으로 연결, `NetworkUrls.socketBase` 사용
- `MainShell.initState()`에서 `connect()`, `dispose()`에서 `disconnect()` (메모리 누수 방지)
- `onConnectCallbacks` 큐 — 소켓 미연결 시 구독 대기, 연결 완료 후 자동 실행 (race condition 대응)
- `socket_provider.dart` — Riverpod Provider (앱 수명 동안 단일 인스턴스)

---

## WebSocket 이벤트

### 클라 → 서버

| 이벤트             | 페이로드                                                    | 설명                |
| ------------------ | ----------------------------------------------------------- | ------------------- |
| (연결 시)          | `auth: { accessToken }`                                     | WS 인증 (handshake) |
| `room:join`        | `{ roomId }`                                                | 채팅방 입장         |
| `room:leave`       | `{ roomId }`                                                | 채팅방 퇴장         |
| `message:send`     | `{ roomId, clientMessageId, content, type? }`               | 메시지 전송         |
| `message:delivered`| `{ messageId, roomId }`                                     | 수신 확인           |
| `chat.read`        | `{ roomId, lastReadMessageId? }`                            | 읽음 처리           |

### 서버 → 클라

| 이벤트           | 페이로드                                                              | 설명                         |
| ---------------- | --------------------------------------------------------------------- | ---------------------------- |
| `authenticated`  | `{ userId }`                                                          | 인증 완료                    |
| `message:new`    | `{ message, clientMessageId? }`                                       | 새 메시지 (room 전체 브로드) |
| `message:status` | `{ clientMessageId, status, messageId }` / `{ status:'read', readBy, lastReadMessageId }` | ACK / 읽음 알림 |
| `chat.read`      | `{ roomId, userId, readAt, lastReadMessageId? }`                      | 읽음 동기화 (room 전체 브로드) |
| `error`          | `{ code, message }`                                                   | 오류                         |

**메시지 상태 흐름**

```
sending → (socket emit) → sent → delivered → read
    └─ 10초 타임아웃 → failed → (재시도 버튼) → sending
```

> `clientMessageId(uuid)` — 낙관적 업데이트용. `message:new`에 포함되어 발신자 중복 방지.
> `lastReadMessageId` — 해당 메시지까지 읽음 처리. 없으면 방 전체 읽음.

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
