import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { randomUUID } from 'crypto';
import { AllowedContentType } from './dto/presign-attachment.dto';

const PRESIGN_EXPIRES_IN_SECONDS = 5 * 60; // 5분

const MIME_TO_EXT: Record<AllowedContentType, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/gif': '.gif',
  'image/webp': '.webp',
  'video/mp4': '.mp4',
  'video/quicktime': '.mov',
  'application/pdf': '.pdf',
};

export interface PresignedUrlResult {
  uploadUrl: string;
  fileUrl: string;
  key: string;
  expiresIn: number;
}

@Injectable()
export class AttachmentsService {
  private readonly logger = new Logger(AttachmentsService.name);
  private readonly s3: S3Client;
  private readonly bucket: string;
  private readonly region: string;

  constructor(private readonly config: ConfigService) {
    this.region = this.config.get<string>('AWS_REGION', 'ap-northeast-2');
    this.bucket = this.config.get<string>('S3_BUCKET_NAME', '');

    this.s3 = new S3Client({
      region: this.region,
      credentials: {
        accessKeyId: this.config.get<string>('AWS_ACCESS_KEY_ID', ''),
        secretAccessKey: this.config.get<string>('AWS_SECRET_ACCESS_KEY', ''),
      },
    });
  }

  /**
   * S3 Presigned PUT URL 발급
   *
   * 클라이언트가 직접 S3에 PUT 업로드할 수 있도록 서명된 URL을 생성한다.
   * 서버는 파일을 중계하지 않으므로 대용량 파일도 서버 부하 없이 처리 가능.
   *
   * S3 Key 구조: attachments/{userId}/{timestamp}-{uuid}.{ext}
   */
  async presign(
    userId: string,
    fileName: string,
    contentType: AllowedContentType,
    fileSize: number,
  ): Promise<PresignedUrlResult> {
    const ext = this.resolveExt(fileName, contentType);
    const key = `attachments/${userId}/${Date.now()}-${randomUUID()}${ext}`;

    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: key,
      ContentType: contentType,
      ContentLength: fileSize,
    });

    const uploadUrl = await getSignedUrl(this.s3, command, {
      expiresIn: PRESIGN_EXPIRES_IN_SECONDS,
    });

    const fileUrl = `https://${this.bucket}.s3.${this.region}.amazonaws.com/${key}`;

    this.logger.log(
      `Presigned URL 발급: userId=${userId}, key=${key}, size=${fileSize}`,
    );

    return {
      uploadUrl,
      fileUrl,
      key,
      expiresIn: PRESIGN_EXPIRES_IN_SECONDS,
    };
  }

  /** 파일명 확장자 우선, 없으면 MIME 타입으로 폴백 */
  private resolveExt(fileName: string, contentType: AllowedContentType): string {
    const dotIdx = fileName.lastIndexOf('.');
    if (dotIdx !== -1 && dotIdx < fileName.length - 1) {
      return fileName.slice(dotIdx).toLowerCase();
    }
    return MIME_TO_EXT[contentType] ?? '';
  }
}
