import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { UploadService } from './upload.service';
import { GetUploadUrlDto } from './dto/get-upload-url.dto';

@Controller('upload')
@UseGuards(JwtAuthGuard)
export class UploadController {
  constructor(private readonly uploadService: UploadService) {}

  /**
   * POST /api/v1/upload/presign
   *
   * Presigned PUT URL을 발급한다.
   * 클라이언트는 반환된 uploadUrl로 S3에 직접 파일을 PUT 업로드하고,
   * 완료 후 fileUrl을 메시지 전송 시 사용한다.
   *
   * 요청: { fileName, contentType, fileSize }
   * 응답: { uploadUrl, fileUrl, key, expiresIn }
   */
  @Post('presign')
  @Throttle({ short: { limit: 5, ttl: 1000 }, long: { limit: 30, ttl: 60000 } })
  async getPresignedUrl(
    @CurrentUser() user: JwtPayload,
    @Body() dto: GetUploadUrlDto,
  ) {
    return this.uploadService.getPresignedUrl(
      user.sub,
      dto.fileName,
      dto.contentType,
      dto.fileSize,
    );
  }
}
