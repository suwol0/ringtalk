# 링톡 Flutter 앱

링톡 메신저의 클라이언트 앱입니다. Flutter로 iOS, Android, Web, Windows, macOS를 지원합니다.

## 기술 스택

- **Flutter** 3.x
- **상태 관리** — Riverpod
- **라우팅** — go_router
- **HTTP** — Dio (api_client)
- **실시간** — socket_io_client
- **저장소** — flutter_secure_storage (토큰)

## 디렉터리 구조

```
lib/
├── core/                 # 공통
│   ├── constants/        # API 엔드포인트, WsEvents
│   ├── models/           # Auth, User, Chat, Message
│   ├── network/          # api_client, socket_service
│   ├── router/           # go_router
│   ├── storage/          # auth_storage
│   ├── theme/            # AppColors, AppTheme
│   └── utils/            # date_utils, phone_utils
├── features/
│   ├── auth/             # 로그인 (OTP, 프로필 설정)
│   │   ├── screens/
│   │   └── widgets/
│   ├── chat/             # 채팅 목록, 채팅방
│   │   ├── data/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── contacts/         # 연락처 동기화
│   ├── friends/          # 친구 목록
│   └── settings/         # 설정, 로그아웃
└── shared/                # MainShell (탭 네비게이션)
```

## 채팅 기능

- **채팅 목록** — `GET /chats`, 최근 메시지, 안 읽음 뱃지
- **채팅방** — `room:join` 후 `message:send` / `message:new` / `message:status` 실시간 처리
- **낙관적 업데이트** — 전송 즉시 UI 반영, `message:status`로 서버 ID 교체

자세한 내용은 [docs/chat.md](../../docs/chat.md)를 참고하세요.

## 실행

```bash
# 루트에서
pnpm app

# 또는
cd app && flutter run
```

### 플랫폼별

```bash
flutter run -d chrome      # Web
flutter run -d ios         # iOS 시뮬레이터
flutter run -d android     # Android 에뮬레이터
flutter run -d macos       # macOS
flutter run -d windows     # Windows
```

## 환경 변수

`--dart-define` 또는 `.env` (flutter_dotenv):

- `API_URL` — API 서버 URL (기본: `http://localhost:3000/api/v1`)
- Socket.IO는 API URL의 origin 사용
