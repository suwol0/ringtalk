import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Socket.IO WebSocket 어댑터
  app.useWebSocketAdapter(new IoAdapter(app));

  // 전역 접두사
  app.setGlobalPrefix('api/v1');

  // CORS 설정
  const corsOrigins = process.env.CORS_ORIGINS?.split(',') ?? ['http://localhost:3001'];
  app.enableCors({
    origin: corsOrigins,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Device-Id'],
  });

  // 전역 파이프 - 요청 유효성 검사
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // DTO에 없는 필드 제거
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );

  // 전역 필터 - 에러 응답 통일
  app.useGlobalFilters(new HttpExceptionFilter());

  // 전역 인터셉터 - 응답 포맷 통일
  app.useGlobalInterceptors(new TransformInterceptor());

  const port = process.env.PORT ?? 3000;
  await app.listen(port);

  console.log(`🔔 링톡 서버 실행 중: http://localhost:${port}/api/v1`);
}

bootstrap();
