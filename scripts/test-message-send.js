#!/usr/bin/env node
/**
 * message.send 이벤트 테스트
 *
 * 사전 요구: 서버 실행 중 (pnpm server), DB 시드 완료 (pnpm db:seed)
 *
 * 사용법:
 *   1. user1로 OTP 로그인 → accessToken 획득
 *   2. node scripts/test-message-send.js <accessToken>
 *
 * 또는 curl로 토큰 획득:
 *   curl -X POST http://localhost:3000/api/v1/auth/verify-otp \
 *     -H "Content-Type: application/json" \
 *     -d '{"phoneNumber":"+821011111111","otp":"123456","deviceId":"test-device","deviceName":"Test","platform":"web"}'
 */

const { io } = require('socket.io-client');

const token = process.argv[2];
if (!token) {
  console.error('Usage: node scripts/test-message-send.js <accessToken>');
  process.exit(1);
}

const socket = io('http://localhost:3000', {
  auth: { accessToken: token },
});

socket.on('connect', () => console.log('✓ 연결됨'));
socket.on('authenticated', (d) => console.log('✓ 인증됨:', d));
socket.on('connect_error', (e) => console.error('✗ 연결 실패:', e.message));
socket.on('message:new', (d) => console.log('← message:new:', JSON.stringify(d, null, 2)));
socket.on('message:status', (d) => console.log('← message:status:', d));
socket.on('error', (d) => console.error('← error:', d));

socket.on('connect', () => {
  socket.emit('room:join', { roomId: 'seed-room-1' });
  setTimeout(() => {
    console.log('→ message:send');
    socket.emit('message:send', {
      roomId: 'seed-room-1',
      clientMessageId: 'test-' + Date.now(),
      content: '테스트 메시지 ' + new Date().toISOString(),
      type: 'text',
    });
  }, 500);
});

setTimeout(() => {
  console.log('테스트 완료. 3초 후 종료.');
  socket.disconnect();
  process.exit(0);
}, 5000);
