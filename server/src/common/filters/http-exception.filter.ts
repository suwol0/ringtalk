import { ExceptionFilter, Catch, ArgumentsHost, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Request, Response } from 'express';
import { ApiResponse, ErrorCode, ErrorCodeType } from '@ringtalk/shared-server';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let code: ErrorCodeType = ErrorCode.INTERNAL_ERROR;
    let message = '서버 내부 오류가 발생했습니다.';
    let details: unknown = undefined;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();

      if (typeof exceptionResponse === 'object' && exceptionResponse !== null) {
        const resp = exceptionResponse as Record<string, unknown>;
        code = (resp['code'] as ErrorCodeType) ?? this.statusToCode(status);
        message = (resp['message'] as string) ?? exception.message;
        details = resp['details'];
      } else {
        message = exceptionResponse as string;
        code = this.statusToCode(status);
      }
    } else if (exception instanceof Error) {
      this.logger.error(`처리되지 않은 오류: ${exception.message}`, exception.stack);
    }

    const body: ApiResponse = {
      success: false,
      error: { code, message, details },
    };

    this.logger.warn(`[${request.method}] ${request.url} → ${status} ${code}`);
    response.status(status).json(body);
  }

  private statusToCode(status: number): ErrorCodeType {
    switch (status) {
      case 400: return ErrorCode.VALIDATION_ERROR;
      case 401: return ErrorCode.UNAUTHORIZED;
      case 429: return ErrorCode.RATE_LIMIT;
      default:  return ErrorCode.INTERNAL_ERROR;
    }
  }
}
