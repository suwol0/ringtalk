# 채팅 기능 문서

## 개요

링톡의 실시간 채팅은 **Socket.IO** 기반으로 동작합니다.
REST API로 메시지 히스토리를 조회하고, WebSocket으로 실시간 송수신을 처리합니다.

---

## 아키텍처

```
┌─────────────────┐     message:send      ┌─────────────────┐
│  Flutter Client │ ────────────────────► │  NestJS Server  │
│                 │                       │  WebSocket GW   │
│  ChatRoomProvider│ ◄──────────────────── │  MessagesService │
└─────────────────┘   message:new (room)  └────────┬────────┘
        │                        message:status     │
        │                                          │
        │                                          ▼
        │                                 ┌─────────────────┐
        │                                 │   PostgreSQL    │
        └────────────────────────────────│   (messages)    │
              GET /chats/:id/messages     └─────────────────┘
```

---

## WebSocket 이벤트 흐름

### 메시지 전송

1. **클라이언트** `message:send` emit
   - `{ roomId, clientMessageId, content, type: 'text' }`

2. **서버**
   - `room:join`으로 입장한 참여자만 전송 가능
   - DB에 메시지 저장
   - `message:new`를 **room 전체**에 브로드캐스트 (`clientMessageId` 포함)
   - 발신자에게 `message:status` 전송 (`messageId` 포함)

3. **클라이언트**
   - 낙관적 업데이트: 즉시 UI에 `clientMessageId`로 메시지 표시
   - `message:status` 수신 시 → 해당 메시지의 `id`를 서버 ID로 교체
   - `message:new` 수신 시:
     - 발신자가 나 + `clientMessageId` 있음 → 낙관적 메시지 교체 (중복 방지)
     - 그 외 → 새 메시지 추가

---

## Flutter 구조

### 디렉터리

```
lib/features/chat/
├── data/
│   ├── messages_repository.dart   # GET /chats/:id/messages
│   └── rooms_repository.dart      # GET /chats, POST /chats/direct
├── providers/
│   ├── chat_room_provider.dart    # ChatRoomNotifier (메시지 상태, WS 구독)
│   └── rooms_provider.dart        # 채팅 목록
├── screens/
│   ├── chat_list_screen.dart
│   └── chat_room_screen.dart
└── widgets/
    ├── chat_input_bar.dart    # 입력창
    ├── chat_room_tile.dart    # 목록 타일
    ├── date_divider.dart      # 날짜 구분선
    └── message_bubble.dart    # 메시지 말풍선
```

### ChatRoomProvider

- `room:join` / `room:leave` — 채팅방 입·퇴장 시 구독
- `message:new` — 실시간 메시지 수신 (브로드캐스트)
- `message:status` — 전송 완료 시 낙관적 메시지 ID 교체
- `loadMessages()` — REST로 히스토리 로드

### UI 컴포넌트

| 위젯 | 역할 |
|------|------|
| `MessageBubble` | 텍스트/미디어/시스템 메시지, 시간·상태 표시 |
| `DateDivider` | "2024년 3월 5일 화요일" 형식 구분선 |
| `ChatInputBar` | 입력 필드 + 전송 버튼, 최대 길이 검증 |

---

## 서버 (NestJS)

### MessagesService

- `sendMessage(userId, payload)` — 참여자 검증, DB 저장, 메시지 반환
- `getMessages(roomId, userId, cursor?, limit)` — cursor 기반 페이지네이션

### WebSocket Gateway

- `room:join` — 참여자 확인 후 `socket.join('room:' + roomId)`
- `room:leave` — `socket.leave()`
- `message:send` — MessagesService 호출 후 `message:new` 브로드캐스트 + `message:status` 발신

---

## 상수 (WsEvents)

`app/lib/core/constants/app_constants.dart`:

```dart
abstract class WsEvents {
  static const roomJoin = 'room:join';
  static const roomLeave = 'room:leave';
  static const messageSend = 'message:send';
  static const messageNew = 'message:new';
  static const messageStatus = 'message:status';
}
```
