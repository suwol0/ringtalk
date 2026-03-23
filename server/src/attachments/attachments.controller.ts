import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser, JwtPayload } from '../common/decorators/current-user.decorator';
import { AttachmentsService } from './attachments.service';
import { PresignAttachmentDto } from './dto/presign-attachment.dto';

/**
 * POST /api/v1/attachments/presign
 *
 * S3 Presigned PUT URL을 발급한다.
 * 클라이언트는 반환된 uploadUrl로 S3에 직접 파일을 PUT 업로드하고,
 * 완료 후 fileUrl을 메시지 전송 시 content로 사용한다.
 *
 * Request:  { fileName, contentType, fileSize }
 * Response: { uploadUrl, fileUrl, key, expiresIn }
 */
@Controller('attachments')
@UseGuards(JwtAuthGuard)
export class AttachmentsController {
  constructor(private readonly attachmentsService: AttachmentsService) {}

  @Post('presign')
  @Throttle({ short: { limit: 5, ttl: 1000 }, long: { limit: 30, ttl: 60000 } })
  async presign(
    @CurrentUser() user: JwtPayload,
    @Body() dto: PresignAttachmentDto,
  ) {
    return this.attachmentsService.presign(
      user.sub,
      dto.fileName,
      dto.contentType,
      dto.fileSize,
    );
  }
}
